require ecs
require dm
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require danetlibs.native_dasevents.main.native_events

[es(on_appear, tag=server, REQUIRE_NOT=menuVehicle)]
def init_repair_dm_parts_Es(evt : Event;
                            damage_model : DamageModel&;
                            dm_parts_repair_names : StringList;
                            dm_parts__repairGroups : Object;
                            var repairable__repairTimeByPart : FloatList;
                            var dm_parts__canRepair : BoolList;
                            var dm_parts__repairPartGroupIds : UInt8List)
  resize(dm_parts__canRepair, length(damage_model.dmData.parts))
  resize(repairable__repairTimeByPart, length(damage_model.dmData.parts))
  resize(dm_parts__repairPartGroupIds, length(damage_model.dmData.parts))
  for partName in dm_parts_repair_names
    let partId = find_part_id_by_name(damage_model, string(partName))
    if partId >= 0
      dm_parts__canRepair[partId] = true

  var curGroupId = 1
  for data in dm_parts__repairGroups
    let groupNodeList = get_ecs_StringList(data.value)
    for val in *groupNodeList
      let partId = find_part_id_by_name(damage_model, string(val))
      if partId >= 0
        dm_parts__repairPartGroupIds[partId] = uint8(curGroupId)
    curGroupId++

[es(tag=gameClient, after=check_repairing_conditions, REQUIRE=hero)]
def repair_armor_analyzer_update_target(info : UpdateStageInfoAct;
                                        isInVehicle : bool;
                                        human_weap__curGunSlot : int;
                                        human_weap__gunEids : EidList;
                                        maintenance__target : EntityId)
  query() <| $ [es] (var armor_analyzer__target : EntityId&;
                     var armor_analyzer__mode : int&)
    if human_weap__curGunSlot < 0 || isInVehicle
      armor_analyzer__target = INVALID_ENTITY_ID
      return
    var xrayObject = INVALID_ENTITY_ID
    let selectedGun = human_weap__gunEids[human_weap__curGunSlot]
    query(selectedGun) <| $ [es(REQUIRE=(repairKitWeapon, watchedPlayerItem))] ()
      xrayObject = maintenance__target
    armor_analyzer__mode = 5
    armor_analyzer__target = xrayObject

[es(tag=gameClient, REQUIRE=repairKitWeapon, before=start_build_fortification_es)]
def repair_weapon_start_repair(evt : CmdWeapPhysUpdate;
                               gun__owner : EntityId;
                               var repair__started : bool&)
  if !evt.isForReal
    return
  let isShootPressed = evt.gctrl.shoot
  query(gun__owner) <| $ [es] (maintenance__target : EntityId;
                               maintenance__hasTarget : bool;
                               dm_parts__repairDistance : float)

    if isShootPressed && !repair__started && maintenance__hasTarget
      var dmPartId = -1
      query() <| $ [es] (armor_analyzer__partId : int;
                         armor_analyzer__traceRes : float)
        dmPartId = armor_analyzer__partId
        if dmPartId >= 0
          if armor_analyzer__traceRes > dm_parts__repairDistance
            sendEvent(gun__owner, [[CmdHeroLogEvent event="repair_blocked_by_dist", text="repair_blocked_by_dist"]])
          else
            sendEvent(gun__owner, [[CmdStartMaintenance target=maintenance__target, partId=dmPartId]])
      repair__started = true

    if repair__started && !isShootPressed
      repair__started = false
      sendEvent(gun__owner, [[CmdStopMaintenance target=maintenance__target]])
