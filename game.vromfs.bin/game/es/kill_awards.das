require ecs
require ecs.common
require app
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require EnlistedDm
require game.utils.team
require math.base
require strings
require game.es.awards_common

def update_sequential_kill_award(seq_kill_time : float; var last_kill_time : float&; var kills : int&; var awards : Array&)
  let time = get_sync_time()
  if time - last_kill_time > seq_kill_time
    kills = 0

  kills += 1
  last_kill_time = time

  if kills == 2
    add_award(awards, "double_kill") <| $(params)
      set(params, "unique", "multikill")
  elif kills == 3
    add_award(awards, "triple_kill") <| $(params)
      set(params, "unique", "multikill")
  elif kills >= 4
    add_award(awards, "multi_kill") <| $(params)
      set(params, "kills", kills)
      set(params, "unique", "multikill")

[es(tag=server)]
def kill_award_es(evt : EventPlayerKilledEntity;
                  team aka killer_team : int = TEAM_UNASSIGNED;
                  sequential_kills__time : float;
                  var sequential_kills__lastKillTime : float&;
                  var sequential_kills__currentCount : int&;
                  var awards : Array&)
  let victimEid = evt.victimEid
  let killerEid = evt.killerEid
  query(victimEid) <| $ [es] (reportKill : bool = true;
                              transform aka victim_transform : float3x4;
                              dm_parts__type : StringList const?;
                              squad_member__squad : EntityId = INVALID_ENTITY_ID;
                              team aka victim_team : int = TEAM_UNASSIGNED;
                              mounted_gun__active : bool = false;
                              human_attached_gun__isAttached : bool = false;
                              isDriver : bool = false;
                              isPassenger : bool = false;
                              human_vehicle__isInHatch : bool = false)
    if !reportKill
      return

    let isVictimInSquad = squad_member__squad != INVALID_ENTITY_ID

    if victimEid == killerEid || victim_team == TEAM_UNASSIGNED || is_teams_friendly(killer_team, victim_team) || !isVictimInSquad
      return

    let damageType = int(evt.deathDesc_damageTypeId)
    let nodeType = dm_parts__type != null ? get_string(*dm_parts__type, int(evt.deathDesc_collNodeId), "") : ""
    find_query() <| $ [es(REQUIRE=awards__firstBlood)] (eid : EntityId)
      sendEvent(evt.killerPlayerEid, [[EventAddPlayerAwardWithStat stat="first_blood"]])
      destroyEntity(eid)
      return true
    if damageType == int(DamageType DM_PROJECTILE) && nodeType == "head"
      add_award(awards, "headshot")
    if damageType == int(DamageType DM_MELEE) || damageType == int(DamageType DM_BACKSTAB)
      add_award(awards, "melee_kill")

    if mounted_gun__active || human_attached_gun__isAttached
      add_award(awards, "machinegunner_kill")

    let isVictimInCar = isDriver || isPassenger
    if isVictimInCar
      add_award(awards, "car_driver_kills")

    if human_vehicle__isInHatch
      sendEvent(evt.killerPlayerEid, [[EventAddPlayerAwardWithStat stat="tank_commander_kills"]])

    if damageType == int(DamageType DM_PROJECTILE)
      query(killerEid) <| $ [es] (transform : float3x4; awards__longRangeDist : float = 100.)
        if length_sq(transform[3] - victim_transform[3]) > square(awards__longRangeDist)
          add_award(awards, "long_range_kill")

    let gunStatName = get_gun_stat_type_by_props_id(int(evt.deathDesc_gunPropsId))
    if !empty(gunStatName)
      add_award(awards, gunStatName == "grenade" ? "grenade_kill" : "{gunStatName}_kills")

    update_sequential_kill_award(sequential_kills__time, sequential_kills__lastKillTime, sequential_kills__currentCount, awards)

[es(tag=server, REQUIRE=player)]
def player_add_award_with_stat(evt : EventAddPlayerAwardWithStat; var awards : Array&)
  add_award(awards, evt.stat)

[es(tag=server, REQUIRE=player)]
def squad_wipeout_award(evt : EventOnPlayerWipedOutInfantrySquad; var awards : Array&)
  add_award(awards, "infantry_squad_wipeout")
