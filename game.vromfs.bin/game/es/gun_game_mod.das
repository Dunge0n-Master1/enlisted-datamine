require ecs
require app
require DagorSystem
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require enlisted.game.es.offender_cache_common
require HumanPhys
require game.utils.team
require game.utils.sound_utils
require DagorRandom
require game.events_game
require enlisted.events_enlisted
require ecs.safe
require EnlistedHuman
require Grid
require DagorMath
require game.es.awards_common
require EnlistedNet

[es(tag=server, on_appear, REQUIRE=possessed,
    on_event=EventApplyDevMode, after=(apply_dev_mode, apply_dev_mode_client_only))]
def init_player_for_gun_game_mode(evt : Event;
                                  var squads__revivePointsAfterDeath : int&;
                                  var respawner__respTime : float&;
                                  var squads__respawnPenaltyTimeThreshold : float&;
                                  var respawner__respawnWhenInactiveTimeout : float&;
                                  var respawner__canSpawnMinTime : float&)
  if (find_query() <| $ [es(REQUIRE=gunGameModeLogic)] () => true)
    squads__respawnPenaltyTimeThreshold = 0.0
    respawner__respTime = 0.0
    respawner__respawnWhenInactiveTimeout = 0.0
    respawner__canSpawnMinTime = 0.0
    squads__revivePointsAfterDeath = 100

[es(tag=server, on_appear, REQUIRE=gunGameModeLogic)]
def init_gun_game_mod(evt : Event;
                      var gun_game__levelsCount : int&;
                      var gun_game__levels : Array&)
  gun_game__levelsCount = length(gun_game__levels)
  for level in gun_game__levels
    var levelObj = getRW_ecs_object(level)
    if levelObj != null
      let listOfWeap = get_ecs_StringList(*levelObj, "weapons")
      let listOfAmmo = get_ecs_StringList(*levelObj, "ammoTemplates")

      let additionalInfo = (levelObj?.additionalWeapInfo)

      if listOfWeap != null
        let weaponsCount = length(*listOfWeap)
        let selector = rnd_int(0, weaponsCount - 1)

        if additionalInfo != null
          let listOfAdditionalInfo = *additionalInfo as Array
          *levelObj |> set("selectedAdditionalInfo", (*listOfAdditionalInfo)[selector])

        let weaponTemplateName = string((*listOfWeap)[selector])
        *levelObj |> set("selectedSessionWeapon", weaponTemplateName)
        if listOfAmmo != null
          *levelObj |> set("selectedSessionAmmo", (*listOfAmmo)[selector])
        else
          let ammoTemplate = getTemplateByName(weaponTemplateName)
          if ammoTemplate != null
            let holdersArray = getTemplateComponent(*ammoTemplate, "gun__ammoHolders") ?as Array
            if holdersArray != null && length(*holdersArray) > 0
              *levelObj |> set("selectedSessionAmmo", (*holdersArray)[0])

def clear_player_item_container(var itemContainer : EidList)
  for itemEid in itemContainer
    destroyEntity(itemEid)
  clear(itemContainer)

def reset_human_weap_info_templates_for_slot(slot_id : int; var weap_templates : Object; var gun_mods_by_slot : Array; var weap_info : Array)
  let weaponSlotName = get_human_weapon_slot_name(slot_id)

  let gunsCount = min(int(HUWeaponSlots EWS_NUM), length(gun_mods_by_slot))
  for i in range(gunsCount)
    var gunMods = gun_mods_by_slot[i] as Object
    if gunMods != null
      *gunMods |> clear()

  weap_templates |> set(weaponSlotName, "")
  var weapInfoSlot = weap_info[slot_id] |> getRW_ecs_object()
  if weapInfoSlot != null
    *weapInfoSlot |> clear()
    *weapInfoSlot |> set("numReserveAmmo", 0)
    *weapInfoSlot |> set("reserveAmmoTemplate", "")

def gun_game_init_level(eid : EntityId;
                        squad_member__playerEid : EntityId;
                        var human_inventory__dropsLoot : bool&;
                        var human_net_phys : HumanActor;
                        var itemContainer : EidList;
                        var human_weap__weapTemplates : Object;
                        var human_weap__gunModsBySlot : Array;
                        var human_weap__weapInfo : Array)
  find_query() <| $ [es(REQUIRE=gunGameModeLogic)] (gun_game__levels : Array&;
                                                    gun_game__levelsCount : int;
                                                    gun_game__finished : bool)
    human_inventory__dropsLoot = false
    if gun_game__finished
      return false

    clear_player_item_container(itemContainer)
    query(squad_member__playerEid) <| $ [es] (gun_game__currentLevel : int;
                                              var gun_game__currentLevelWeapSlot : int&;
                                              var gun_game__killsForNextLevelRequire : int&;
                                              var gun_game__killsForNextLevel : int&;
                                              var gun_game__levelPropsId : int&)
      if (gun_game__currentLevel >=  gun_game__levelsCount)
        logerr("invalid level for player {squad_member__playerEid} {gun_game__currentLevel} >= {gun_game__levelsCount}")
        return ;
      let level = get_ecs_object(gun_game__levels[gun_game__currentLevel])
      if level != null
        var weapon = level?.selectedSessionWeapon ?? "knife"
        weapon = add_sub_template_name(weapon, "gun_game_mode_weapon_components")

        let ammo = level?.numReserveAmmo ?? 10
        gun_game__killsForNextLevelRequire = level?.levelKills ?? 2
        if (gun_game__killsForNextLevel <= 0)
          gun_game__killsForNextLevel = gun_game__killsForNextLevelRequire
        let ammoTemplate = level?.selectedSessionAmmo ?? ""

        let weaponSlotName = level?.weaponSlot ?? "primary"
        let slotId = int(HUWeaponSlots(weaponSlotName))

        if gun_game__currentLevelWeapSlot >= 0
          reset_human_weap_info_templates_for_slot(gun_game__currentLevelWeapSlot, human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)

        human_weap__weapTemplates |> set(weaponSlotName, weapon)
        var weapInfoSlot = human_weap__weapInfo[slotId] |> getRW_ecs_object()
        if weapInfoSlot != null
          *weapInfoSlot |> set("numReserveAmmo", ammo)
          *weapInfoSlot |> set("reserveAmmoTemplate", ammoTemplate)
          let additionalInfo = level?.selectedAdditionalInfo
          if additionalInfo != null
            let additionalInfoObj = *additionalInfo as Object
            for kv in *additionalInfoObj
              *weapInfoSlot |> set(kv.key, kv.value)

        gun_game__levelPropsId = -1
        reset_weapon_state(human_net_phys.phys)
        sendEvent(eid, [[CmdReinitWeapons]])
        sendEvent(eid, [[HumanWeapSetCurrentGun slot=uint8(slotId)]])
        gun_game__currentLevelWeapSlot = slotId
    return true

[es(tag=server, on_appear, track=gun__owner, REQUIRE=gunGameModeWeapon)]
def init_weapon_for_gun_game_mode(evt : Event;
                                  gun__owner : EntityId;
                                  gun__propsId : int)
  query(gun__owner) <| $ [es] (squad_member__playerEid : EntityId)
    query(squad_member__playerEid) <| $ [es] (var gun_game__levelPropsId : int&)
      gun_game__levelPropsId = gun__propsId


def gun_game_init_level(eid : EntityId)
  query(eid) <| $ [es] (squad_member__playerEid : EntityId;
                        var human_inventory__dropsLoot : bool&;
                        var human_net_phys : HumanActor;
                        var itemContainer : EidList;
                        var human_weap__weapTemplates : Object;
                        var human_weap__gunModsBySlot : Array;
                        var human_weap__weapInfo : Array)
    gun_game_init_level(eid, squad_member__playerEid, human_inventory__dropsLoot, human_net_phys, itemContainer, human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)


[es(tag=server, before=(human_weap_created_server_es, human_weapon_init_es), on_appear, track=squad_member__playerEid, REQUIRE=human)]
def init_soldier_for_gun_game_mod(evt : Event;
                                  eid : EntityId;
                                  squad_member__playerEid : EntityId;
                                  var human_inventory__dropsLoot : bool&;
                                  var human_net_phys : HumanActor;
                                  var itemContainer : EidList;
                                  var human_weap__weapTemplates : Object;
                                  var human_weap__gunModsBySlot : Array;
                                  var human_weap__weapInfo : Array)
  if !squad_member__playerEid
    return
  gun_game_init_level(eid, squad_member__playerEid, human_inventory__dropsLoot, human_net_phys, itemContainer, human_weap__weapTemplates, human_weap__gunModsBySlot, human_weap__weapInfo)

[es(tag=server, on_event=EventFirstPlayerSpawned, REQUIRE=gunGameModeLogic)]
def gun_game_start_timer(evt : Event;
                         gun_game__resetSpawnsTimeout : float;
                         var gun_game__resetSpawnsAtTime : float&)
  gun_game__resetSpawnsAtTime = get_sync_time() + gun_game__resetSpawnsTimeout

[es(tag=server, no_order, REQUIRE=gunGameModeLogic)]
def gun_game_reset_spawn_team_timer(info : UpdateStageInfoAct;
                                    gun_game__resetSpawnsAtTime : float)
  if info.curTime < gun_game__resetSpawnsAtTime || gun_game__resetSpawnsAtTime < 0.
    return
  var team1SpawnExist = false
  var team2SpawnExist = false
  query() <| $ [es(REQUIRE=respbase)] (gun_game__respawnFriendlyRadius : float;
                                       transform : float3x4;
                                       var team aka respawn_team : int&)
    let respawnBasePos = transform[3]
    respawn_team = TEAM_UNASSIGNED
    find_entity_in_grid(ecs_hash("humans"), BSphere3(respawnBasePos, gun_game__respawnFriendlyRadius), GridEntCheck POS) <| $(eid : EntityId)
      var conflictTeamsFound = false
      query(eid) <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int)
        if respawn_team != TEAM_UNASSIGNED && respawn_team != team
          respawn_team = 3 //invalid base team for gun game mode
          conflictTeamsFound = true
          return
        respawn_team = team
      return conflictTeamsFound
    if respawn_team == TEAM_UNASSIGNED
      team1SpawnExist = true
      team2SpawnExist = true
    else
      team1SpawnExist ||= respawn_team == 1
      team2SpawnExist ||= respawn_team == 2
  if !team1SpawnExist || !team2SpawnExist
    find_query() <| $ [es(REQUIRE=respbase)] (var team aka respawn_team : int&)
      respawn_team = TEAM_UNASSIGNED
      return true

def broadcast_new_leader(old_leader : EntityId; new_leader : EntityId)
  broadcast_net_event([[EventGunGameNewLeader
    oldLeaderPlayerEid = old_leader, newLeaderPlayerEid = new_leader]])

def broadcast_level_reach(leader : EntityId; level : int)
  broadcast_net_event([[EventGunGameLevelReached
    playerEid = leader, level = level]])

[es(tag=server, REQUIRE=gunGameModeLogic)]
def gun_game_mode_score(evt : EventAnyEntityDied;
                        gun_game__levelsCount : int;
                        gun_game__announceLevelReach : IntList;
                        var gun_game__finished : bool&;
                        var gun_game__leaderLevel : int&;
                        var gun_game__leaderPlayerEid : EntityId&)
  if gun_game__finished
    return
  assume victimEid = evt.victim
  assume offenderEid = evt.offender
  let offenderInfo = get_offender_from_cache(offenderEid)
  let victimInfo = get_offender_from_cache(victimEid)
  query(offenderInfo.player) <| $ [es] (team : int;
                                        possessed : EntityId;
                                        var gun_game__levelPropsId : int&;
                                        var gun_game__currentLevel : int&;
                                        var gun_game__killsForNextLevel : int&)
    if evt.gunPropsId >= 0 && gun_game__levelPropsId != evt.gunPropsId
      return

    let isFriendly = is_teams_friendly(team, get_int(victimInfo.player, "team") ?? TEAM_UNASSIGNED)
    if isFriendly
      return
    gun_game__killsForNextLevel--
    if (gun_game__killsForNextLevel <= 0)
      let nextGunGameLevel = gun_game__currentLevel + 1
      send_award_stat(offenderInfo.player, offenderInfo.guid, "gunGameLevelup")

      if nextGunGameLevel >= gun_game__levelsCount
        broadcastEvent([[EventTeamWon team=team]])
        gun_game__finished = true
        return

      gun_game__currentLevel = nextGunGameLevel
      gun_game__levelPropsId = -1

      if gun_game__currentLevel > gun_game__leaderLevel
        gun_game__leaderLevel = gun_game__currentLevel
        if gun_game__leaderPlayerEid != offenderInfo.player
          broadcast_new_leader(gun_game__leaderPlayerEid, offenderInfo.player)
          gun_game__leaderPlayerEid = offenderInfo.player
        if gun_game__announceLevelReach |> has_value(gun_game__leaderLevel)
          broadcast_level_reach(gun_game__leaderPlayerEid, gun_game__leaderLevel)

      play_net_sound_from_any_source(offenderEid, "gunGameNextLevel")

      find_query() <| $ [es] (team__id : int;
                              var team__gunGameLevel : int&)
        if team == team__id
          if gun_game__currentLevel > team__gunGameLevel
            team__gunGameLevel = gun_game__currentLevel
          return true
        return false
      gun_game_init_level(possessed)
