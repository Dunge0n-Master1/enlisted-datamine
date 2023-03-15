require ecs
require enlisted.events_enlisted
require danetlibs.native_dasevents.main.native_events
require enlisted.game.es.fortifications_build_common

[es(tag=server, track=isAlive)]
def additive_building_on_destroy_es(evt : Event; eid : EntityId; dependsOnBuildingEid : EntityId; isAlive : bool)
  if !isAlive
    query(dependsOnBuildingEid) <| $ [es] (var additiveBuildingEid : EntityId&; var additiveBuildNeedRepair : bool&)
      additiveBuildNeedRepair = true
      additiveBuildingEid = eid

[es(tag=server, before=fortification_repair_start_es, after=before_fortification_repair_start_es)]
def additive_building_repair_start_es(evt : EventRepairFortificationStart;
                                      var fortification_repair__canRepair : bool&;
                                      var fortification_repair__repairCost : float&)
  if !fortification_repair__canRepair
    return

  query(evt.target) <| $ [es] (additiveBuildNeedRepair : bool; buildingCost : float; fortification_repair__costPercent : float)
    fortification_repair__canRepair = additiveBuildNeedRepair
    fortification_repair__repairCost += buildingCost * fortification_repair__costPercent

[es(tag=server, before=fortification_repair_finish_es)]
def additive_building_repair_finish_es(evt : EventRepairFortificationFinish;
                                       eid : EntityId;
                                       fortification_repair__target : EntityId;
                                       var stockOfBuilderCapabilities : float&)
  query(fortification_repair__target) <| $ [es] (additiveBuildingEid : EntityId;
                                                 var additiveBuildNeedRepair : bool&;
                                                 buildingCost : float;
                                                 fortification_repair__costPercent : float;
                                                 buildTypeId : int;
                                                 buildByPlayer : EntityId)
    if !additiveBuildNeedRepair
      sendEvent(eid, [[CmdHeroLogEvent event="building_not_need_repair", text="building_not_need_repair"]])
      return

    let totalCost = buildingCost * fortification_repair__costPercent
    if totalCost > stockOfBuilderCapabilities
      sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_no_require_resources", text="building_blocked_no_require_resources"]])
      return

    change_building_limits(buildByPlayer, buildTypeId, -1)
    sendEvent(fortification_repair__target, [[EventAdditiveBuildingRepaired]])
    additiveBuildNeedRepair = false
    stockOfBuilderCapabilities -= totalCost
    destroyEntity(additiveBuildingEid)
