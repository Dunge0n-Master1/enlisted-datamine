require ecs
require HumanPhys
require ecs.common
require DagorSystem
require DagorDataBlock
require game.es.events
require game.utils.team
require daslib.strings_boost
require enlisted.tutorial.tutorial_common
require enlisted.events_enlisted
require player

[es(no_order, REQUIRE=tutorialPlayerOverride)]
def init_practice_player(info : UpdateStageInfoAct; eid : EntityId)
  let localPlayerEid = get_local_player_eid()
  query(localPlayerEid) <| $ [es] (var squads__revivePointsAfterDeath : int&;
                                   var respawner__respTime : float&;
                                   var respawner__missionStartDelay : float&;
                                   var respawner__canSpawnMinTime : float&)
    squads__revivePointsAfterDeath = 100
    respawner__respTime = 0.0
    respawner__canSpawnMinTime = 0.0
    respawner__missionStartDelay = 0.0
    removeSubTemplate(localPlayerEid, "suicide_penalty")
  destroyEntity(eid)

[es(tag=gameClient, REQUIRE=player)]
def show_squad_menu_es(evt : CmdSwitchSquad)
  tutorial_squad_change()

[es(tag=gameClient, track=human_weap__gunEids, REQUIRE=hero, before=human_weapon_set_gun_info_es)]
def practice_weapon_pickup(evt : Event; team : int; human_weap__gunEids : EidList; var human_weap__weapInfo : Array&)
  for slotId in [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY; HUWeaponSlots EWS_TERTIARY]]
    var weapInfo = getRW_ecs_object(human_weap__weapInfo[int(slotId)])
    if weapInfo == null
      continue

    let gunEid = human_weap__gunEids[int(slotId)]
    query(gunEid) <| $ [es] (gun__ammoHolders : Array;
                             var item__ownedByTeam : int&;
                             var gun__reserveAmmoTemplate : das_string&;
                             var gun__numReserveAmmo : int&;
                             var gun__additionalReserveAmmoTemplates : StringList;
                             var gun__additionalNumReserveAmmos : IntList)
      if gun__ammoHolders.empty || item__ownedByTeam != TEAM_UNASSIGNED
        return

      let holder = string(*get_ecs_string(gun__ammoHolders[0]))
      let holderTemplate = getTemplateByName(holder)
      if holderTemplate == null
        logwarn("Visual template {holder} is not set for <{gunEid}>!")
        return

      item__ownedByTeam = team
      gun__reserveAmmoTemplate := holder
      gun__numReserveAmmo = 5

      clear(gun__additionalReserveAmmoTemplates)
      clear(gun__additionalNumReserveAmmos)
      for i in range(1, length(gun__ammoHolders))
        let additionalHolder = string(*get_ecs_string(gun__ammoHolders[i]))
        let additionalHolderTemplate = getTemplateByName(holder)
        if additionalHolderTemplate == null
          logwarn("Visual template {additionalHolder} (additional ammoholder {i}) is not set for <{gunEid}>!")
          continue

        push(gun__additionalReserveAmmoTemplates, additionalHolder)
        push(gun__additionalNumReserveAmmos, gun__numReserveAmmo)
