require ecs
require ecs.common
require ecs.safe
require app
require strings
require game.es.awards_common
require game.events_game
require game.utils.team
require common_shooter.events_common_shooter
require enlisted.game.es.offender_cache_common
require enlisted.events_enlisted
require EnlistedDm
require math.base


struct AwardedSoldier
  guid : string = ""
  player : EntityId = INVALID_ENTITY_ID
  amount : float = 1.0
  isValid : bool = false

struct VehicleOffender
  eid : EntityId
  guid : string
  player : EntityId
  squad : EntityId
  isCrew : bool
  time : float

def is_valid_award(player : EntityId; guid : string)
  return !!player && !empty(guid)

def is_valid_soldier(player : EntityId; guid : string)
  return is_valid_award(player, guid)

def get_squad_size(squad : EntityId)
  return get_int(squad, "squad__numMembers") ?? 0

def get_crew_for_assist(offender_eid : EntityId)
  var res : array<AwardedSoldier>
  query(offender_eid) <| $ [es] (squad_member__squad : EntityId; human_anim__vehicleSelected : EntityId)
    assume offenderSquad = squad_member__squad
    let squadSize = get_squad_size(offenderSquad)
    if squadSize < 1
      return

    let offenderAddAmount = (squadSize == 1) ? 1.0 : 0.0 // for vehicle squad with single soldier
    let crewAmount = (squadSize > 1) ? (1.0 / float(squadSize - 1)) : 0.0

    query(human_anim__vehicleSelected) <| $ [es] (ownedBySquad : EntityId; vehicle_seats__seatEids : EidList)
      assume vehicleSquad = ownedBySquad
      if vehicleSquad != offenderSquad || offenderSquad == INVALID_ENTITY_ID
        return
      for seatEid in vehicle_seats__seatEids
        let soldierEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
        let amount = (offender_eid == soldierEid) ? offenderAddAmount : crewAmount
        if amount <= 0.
          continue
        query(soldierEid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__squad : EntityId;
                                                             squad_member__playerEid : EntityId;
                                                             guid : string = "")
          if squad_member__squad == vehicleSquad && is_valid_award(squad_member__playerEid, guid)
            res |> emplace([[AwardedSoldier guid=guid, player=squad_member__playerEid, amount=amount]])
  return <- res

def add_assists_for_markers(var award_list : Array; victim_pos : float3; offender_player : EntityId; offender_team : int)
  var assistants : table<uint; tuple<player : EntityId; guid : string; time : float>>
  query() <| $ [es] (transform : float3x4;
                     userPointType : string;
                     userPointOwner : EntityId;
                     user_point_assist__distance : float = 20.;
                     marker_enemy__ownerSoldierEid : EntityId;
                     timer__start : float)
    if userPointOwner == offender_player || userPointType != "enemy"
      return
    let soldierEid = marker_enemy__ownerSoldierEid
    let soldier = get_offender_from_cache(soldierEid)
    let soldierPlayerTeam = get_int(soldier.player, "team") ?? TEAM_UNASSIGNED
    if !is_valid_cache_soldier(soldier) || !is_teams_friendly(offender_team, soldierPlayerTeam)
      return
    let markPos = transform[3]
    let markerCreatedAt = timer__start
    let otherMarkerBySamePlayerTime = assistants?[uint(userPointOwner)]?.time ?? 0.
    if length_sq(victim_pos - markPos) < square(user_point_assist__distance) && markerCreatedAt > otherMarkerBySamePlayerTime
      assistants[uint(userPointOwner)] = [[auto soldier.player, soldier.guid, markerCreatedAt]]
  for assist in values(assistants)
    award_list |> push_soldier_stat(assist.player, assist.guid, "assists")

def get_engineer_for_offender(victim : EntityId; offender : EntityId) : AwardedSoldier
  var res : AwardedSoldier
  query(victim) <| $ [es] (last_offenders__engineerAssists : Object)
    let obj = last_offenders__engineerAssists["{offender}"] ?as Object
    res.guid = obj?.guid ?? ""
    res.player = obj?.playerEid ?? INVALID_ENTITY_ID
    res.isValid = is_valid_award(res.player, res.guid)
  return res

def get_crew_award_amount(squad_size : int)
  return (squad_size > 1 ? (1.0 / float(squad_size - 1))
        : squad_size == 1 ? 1.0
        : 0.0)

def add_vehicle_kill_assist(var award_list : Array; vehicle_eid : EntityId; killer_player_eid : EntityId)
  query(vehicle_eid) <| $ [es] (vehicle_kill_assist__stat : string = "";
                                vehicle_kill_assist__crewStat : string = "";
                                vehicle_kill_assist__engineerStat : string = "";
                                vehicleOffenders : Object;
                                vehicle_kill_assist__time : float = 20.)
    let assistTimeThreshold = get_sync_time() - vehicle_kill_assist__time
    for offender in vehicleOffenders
      let assist = offender.value as Object
      let assistEid = EntityId(uint(offender.key))
      let assistTime = assist?.time ?? 0.
      let assistPlayer = assist?.player ?? INVALID_ENTITY_ID
      let assistGuid = assist?.guid ?? ""
      let isCrew = assist?.isCrew ?? false
      let assistSquad = assist?.squad ?? INVALID_ENTITY_ID
      let squadSize = get_squad_size(assistSquad)

      if assistTime >= assistTimeThreshold && assistPlayer != killer_player_eid && is_valid_award(assistPlayer, assistGuid)
        let amount = isCrew ? get_crew_award_amount(squadSize) : 1.
        if amount > 0.
          let stat = isCrew ? vehicle_kill_assist__crewStat : vehicle_kill_assist__stat
          if !empty(stat)
            award_list |> push_soldier_stat(assistPlayer, assistGuid, stat, amount)

        if !isCrew && squadSize == 1 && !empty(vehicle_kill_assist__crewStat) // solo vehicle crew award
          award_list |> push_soldier_stat(assistPlayer, assistGuid, vehicle_kill_assist__crewStat)

        if !isCrew
          let engineerAssist = get_engineer_for_offender(vehicle_eid, assistEid)
          if engineerAssist.isValid && !empty(vehicle_kill_assist__engineerStat)
            award_list |> push_soldier_stat(engineerAssist.player, engineerAssist.guid, vehicle_kill_assist__engineerStat)

def zone_radius(tm : float3x4; sphere_zone__radius : float const?; capzone__approximateRadius : float const?)
  return sphere_zone__radius ?? capzone__approximateRadius ?? sqrt(length_sq(tm[0]) + length_sq(tm[2])) * 0.5

def add_zone_attack_defense_awards(var award_list : Array; victim_pos : float3; offender : CachedSoldier; offender_team : int)
  var isNearFriendlyZone = false
  var isNearEnemyZone = false
  find_query() <| $ [es] (transform : float3x4;
                          capzone__owningTeam : int;
                          capzone__defenseRadiusAdd : float = 0.0;
                          capzone__attackRadiusAdd : float = 0.0;
                          capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                          capzoneTwoChains : Tag const?;
                          active : bool = true;
                          sphere_zone__radius : float const?;
                          capzone__approximateRadius : float const?;
                          battle_contract__acceptedBy : EidList const?)
    assume onlyTeamCanCapture = capzone__onlyTeamCanCapture

    if battle_contract__acceptedBy != null
      if *battle_contract__acceptedBy |> find_index(offender.player) < 0
        return false

    let isUncapturedOneTeamZone = onlyTeamCanCapture != TEAM_UNASSIGNED && capzone__owningTeam != onlyTeamCanCapture
    let isCapturedFriendlyZone = is_teams_friendly(capzone__owningTeam, offender_team)
    let isCapturedEnemyZone = capzone__owningTeam != TEAM_UNASSIGNED && !isCapturedFriendlyZone
    let isCapzoneTwoChains = capzoneTwoChains != null
    let isAttackZone = isCapzoneTwoChains || isCapturedEnemyZone || (isUncapturedOneTeamZone && onlyTeamCanCapture == offender_team)
    let isDefenseZone = isCapturedFriendlyZone || (isUncapturedOneTeamZone && onlyTeamCanCapture != offender_team)
    if active && (isDefenseZone || isAttackZone)
      let zonePos = transform[3]
      let defenseRadius = isDefenseZone ? capzone__defenseRadiusAdd : capzone__attackRadiusAdd
      let zoneIncreasedRadius = zone_radius(transform, sphere_zone__radius, capzone__approximateRadius) + defenseRadius
      if length_sq(victim_pos - zonePos) < square(zoneIncreasedRadius)
        isNearFriendlyZone = isDefenseZone
        isNearEnemyZone = isAttackZone
        return true
    return false
  if isNearFriendlyZone
    award_list |> push_soldier_stat(offender.player, offender.guid, "defenseKills")
  if isNearEnemyZone
    award_list |> push_soldier_stat(offender.player, offender.guid, "attackKills")

def add_weapon_kill_awards(var award_list : Array; victim_pos : float3; damage_type : int; gun_props_id : int; offender_eid : EntityId; offender : CachedSoldier)
  if damage_type == int(DamageType DM_MELEE) || damage_type == int(DamageType DM_BACKSTAB)
    award_list |> push_soldier_stat(offender.player, offender.guid, "meleeKills")
  if get_gun_stat_type_by_props_id(gun_props_id) == "grenade"
    award_list |> push_soldier_stat(offender.player, offender.guid, "explosiveKills")
  if damage_type == int(DamageType DM_PROJECTILE)
    query(offender_eid) <| $ [es] (awards__longRangeDist : float; transform : float3x4)
      let killerPos = transform[3]
      if length_sq(killerPos - victim_pos) > square(awards__longRangeDist)
        award_list |> push_soldier_stat(offender.player, offender.guid, "longRangeKills")

def add_vehicle_kill_awards(var award_list : Array;
                            offender : CachedSoldier;
                            vehicle_eid : EntityId;
                            crew_for_assist : array<AwardedSoldier>;
                            engineer_for_assist : AwardedSoldier)
  query(vehicle_eid) <| $ [es] (vehicle_kill__award : string = "";
                                vehicle_kill__stat : string = "";
                                vehicle_kill__crewStat : string = "";
                                vehicle_kill__engineerStat : string = "")
    if !empty(vehicle_kill__award)
      add_award(offender.player, vehicle_kill__award)
    if !empty(vehicle_kill__stat)
      award_list |> push_soldier_stat(offender.player, offender.guid, vehicle_kill__stat)
    if !empty(vehicle_kill__crewStat)
      for crew in crew_for_assist
        award_list |> push_soldier_stat(crew.player, crew.guid, vehicle_kill__crewStat, crew.amount)
    if !empty(vehicle_kill__engineerStat) && engineer_for_assist.isValid
      award_list |> push_soldier_stat(engineer_for_assist.player, engineer_for_assist.guid, vehicle_kill__engineerStat)

[es(tag=server)]
def enlisted_kill_award_es(evt : EventEntityDied;
                           eid aka victim_eid : EntityId;
                           team aka victim_team : int = TEAM_UNASSIGNED;
                           guid aka victim_guid : string = "";
                           squad_member__playerEid : EntityId = INVALID_ENTITY_ID;
                           statsCountAsKill : Tag const?;
                           vehicle : Tag const?;
                           transform aka victim_transform : float3x4)
  assume killerEid = evt.offender
  assume gunPropsId = evt.gunPropsId
  assume damageType = evt.damageType

  assume victimPlayerEid = squad_member__playerEid
  let victimPos = victim_transform[3]
  let isVictimVehicle = vehicle != null
  let isStatsCountAsKill = statsCountAsKill != null

  let offender = get_offender_from_cache(killerEid)
  let offenderPlayerTeam = get_int(offender.player, "team") ?? TEAM_UNASSIGNED

  if victim_eid == killerEid || !is_valid_cache_soldier(offender) || victim_team == TEAM_UNASSIGNED || is_teams_friendly(offenderPlayerTeam, victim_team)
    return

  using() <| $(var awardList : Array)
    let isVictimValidSoldier = is_valid_soldier(victimPlayerEid, victim_guid)
    let isCountedAsKill = isVictimValidSoldier || isStatsCountAsKill
    if isCountedAsKill
      awardList |> push_soldier_stat(offender.player, offender.guid, "kills")
      awardList |> add_weapon_kill_awards(victimPos, damageType, gunPropsId, killerEid, offender)
      sendEvent(offender.player, [[OnScoringKillBySquadMember victim=victim_eid, offender=killerEid]])
    if isVictimValidSoldier
      awardList |> push_soldier_stat(victimPlayerEid, victim_guid, "killed")

    let crewForAssist <- get_crew_for_assist(killerEid)
    let engineerForAssist = get_engineer_for_offender(victim_eid, killerEid)

    if isVictimVehicle
      awardList |> add_vehicle_kill_assist(victim_eid, offender.player)
      awardList |> add_assists_for_markers(victimPos, offender.player, offenderPlayerTeam)
      awardList |> add_vehicle_kill_awards(offender, victim_eid, crewForAssist, engineerForAssist)
    else
      awardList |> add_assists_for_kill(victim_eid, killerEid)
      if engineerForAssist.isValid
        awardList |> push_soldier_stat(engineerForAssist.player, engineerForAssist.guid, "builtGunKills")

      if !empty(crewForAssist)
        for crew in crewForAssist
          awardList |> push_soldier_stat(crew.player, crew.guid, "crewKillAssists", crew.amount)

      add_zone_attack_defense_awards(awardList, victimPos, offender, offenderPlayerTeam)

    if length(awardList) > 0
      broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
        set(init, "list", awardList)

// Only one assist per kill, so we only should keep two offenders at max (killer and assistant)
// We cannot tell if offender is a killer because hitRes can show that the victim was downed but victim also may die instantly.
def insert_offender(victim_eid : EntityId;
                    offender : EntityId;
                    offender_guid : string;
                    offender_player : EntityId)
  query(victim_eid) <| $ [es] (offenders_for_assist__time : float = 15.;
                               var offenders_for_assist__last : Object&;
                               var offenders_for_assist__prev : Object&)
    let lastOffender = offenders_for_assist__last.soldier ?? INVALID_ENTITY_ID
    if !!lastOffender && lastOffender != offender
      offenders_for_assist__prev := offenders_for_assist__last
    offenders_for_assist__last |> set("soldier", offender)
    offenders_for_assist__last |> set("guid", offender_guid)
    offenders_for_assist__last |> set("player", offender_player)
    offenders_for_assist__last |> set("expireAtTime", get_sync_time() + offenders_for_assist__time)

def is_valid_assistant(obj : Object; offender_eid : EntityId; time : float)
  return (obj.soldier ?? INVALID_ENTITY_ID) != offender_eid && time < (obj.expireAtTime ?? 0.)

def add_assists_for_kill(var award_list : Array; victim_eid : EntityId; offender_eid : EntityId)
  query(victim_eid) <| $ [es] (offenders_for_assist__last : Object;
                               offenders_for_assist__prev : Object)
    let curTime = get_sync_time()
    var assistantEid = INVALID_ENTITY_ID
    var assistantPlayer = INVALID_ENTITY_ID
    var assistantGuid = ""
    if is_valid_assistant(offenders_for_assist__last, offender_eid, curTime)
      assistantEid = offenders_for_assist__last.soldier ?? INVALID_ENTITY_ID
      assistantPlayer = offenders_for_assist__last.player ?? INVALID_ENTITY_ID
      assistantGuid = offenders_for_assist__last.guid ?? ""
    elif is_valid_assistant(offenders_for_assist__prev, offender_eid, curTime)
      assistantEid = offenders_for_assist__prev.soldier ?? INVALID_ENTITY_ID
      assistantPlayer = offenders_for_assist__prev.player ?? INVALID_ENTITY_ID
      assistantGuid = offenders_for_assist__prev.guid ?? ""
    else
      return

    award_list |> push_soldier_stat(assistantPlayer, assistantGuid, "assists")

    let engineerAssist = get_engineer_for_offender(victim_eid, assistantEid)
    if engineerAssist.isValid
      award_list |> push_soldier_stat(engineerAssist.player, engineerAssist.guid, "builtGunKillAssists")


[es(tag=server)]
def enlisted_last_offender_tracker_es(evt : EventOnEntityHit) // broadcast
  assume victimEid = evt.victim
  assume offenderEid = evt.offender
  if (victimEid == offenderEid)
    return
  let offender = get_offender_from_cache(offenderEid)
  let victim = get_offender_from_cache(victimEid)
  let victimPlayerTeam = get_int(victim.player, "team") ?? TEAM_UNASSIGNED
  let offenderPlayerTeam = get_int(offender.player, "team") ?? TEAM_UNASSIGNED
  if is_valid_cache_soldier(offender) && !is_teams_friendly(offenderPlayerTeam, victimPlayerTeam)
    insert_offender(victimEid, offenderEid, offender.guid, offender.player)

[es(tag=server, on_appear)]
def marker_soldier_owner_es(evt : Event;
                            userPointOwner : EntityId;
                            var marker_enemy__ownerSoldierEid : EntityId&)
  marker_enemy__ownerSoldierEid = get_Eid(userPointOwner, "possessed") ?? INVALID_ENTITY_ID

[es(tag=server)]
def count_squad_member_kills(evt : OnScoringKillBySquadMember;
                             eid aka player_eid : EntityId;
                             var scoring_player__bestPossessedInfantryKillstreak : int&)
  query(evt.offender) <| $ [es] (possessedByPlr : EntityId;
                                 human_anim__vehicleSelected : EntityId;
                                 var squad_member__kills : int&;
                                 var squad_member__possessedInfantryKills : int&)
    squad_member__kills += 1
    if possessedByPlr == player_eid && !human_anim__vehicleSelected
      squad_member__possessedInfantryKills += 1
      scoring_player__bestPossessedInfantryKillstreak = max(scoring_player__bestPossessedInfantryKillstreak, squad_member__possessedInfantryKills)

[es(tag=server)]
def count_kills_by_player(evt : OnScoringKillBySquadMember;
                          possessed : EntityId;
                          var scoring_player__killsByPlayer : int&)
  if !!possessed && evt.offender == possessed
    ++scoring_player__killsByPlayer
