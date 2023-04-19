require dm
require ecs
require DngDm
require game.es.events
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require common_shooter.es.repair_common

[es(tag=server, before=fortification_repair_finish_es, REQUIRE=human_weap__currentGunEid)]
def engineer_vehicle_repair_finish_es(evt : EventRepairFortificationFinish; eid : EntityId; fortification_repair__target : EntityId)
  query(fortification_repair__target) <| $ [es] (var repairable__repairRequired : bool&;
                                                 var meta_parts_state : MetaPartsState&;
                                                 var damage_model : DamageModel&;
                                                 var fire_protection : FireProtection&;
                                                 var isAlive : bool&;
                                                 var isExploded : bool&)
    isExploded = false
    isAlive = true
    repairable__repairRequired = repair_vehicle(100f, meta_parts_state, damage_model, fire_protection)
    sendEvent(fortification_repair__target, [[CmdStopBurn]])
    sendEvent(fortification_repair__target, [[EventOnRepaired eid=eid]])
    sendEvent(fortification_repair__target, [[CmdRestore]])

[es(tag=server, before=fortification_repair_start_es, after=before_fortification_repair_start_es, REQUIRE=human_weap__currentGunEid)]
def engineer_vehicle_repair_start_es(evt : EventRepairFortificationStart;
                                     eid : EntityId;
                                     var fortification_repair__canRepair : bool&;
                                     var fortification_repair__repairCost : float&)
  if !fortification_repair__canRepair
    return

  query(evt.target) <| $ [es(REQUIRE=object__useDist)] (repairable__repairRequired : bool;
                                                        isAlive : bool;
                                                        isExploded : bool;
                                                        fortification_repair__cost : float)
    fortification_repair__canRepair = repairable__repairRequired || !isAlive || isExploded
    fortification_repair__repairCost = fortification_repair__cost
    if fortification_repair__canRepair
      sendEvent(eid, [[EventInterruptItemUse]])
    else
      sendEvent(eid, [[CmdHeroLogEvent event="engineer_vehicle_not_need_repair", text="engineer_vehicle_not_need_repair"]])
