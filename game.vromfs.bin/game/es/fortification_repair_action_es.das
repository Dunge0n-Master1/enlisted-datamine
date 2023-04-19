require ecs
require app
require math.base
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require DngNet
require enlisted.game.es.fortifications_build_common

[es(tag=server, before=fortification_repair_start_es)]
def before_fortification_repair_start_es(evt : EventRepairFortificationStart;
                                         isInVehicle : bool;
                                         human_weap__currentGunEid : EntityId;
                                         squad_member__playerEid : EntityId;
                                         var fortification_repair__repairCost : float&;
                                         var fortification_repair__canRepair : bool&)
  fortification_repair__canRepair = false
  query(evt.target) <| $ [es(REQUIRE=fortification_repair__costPercent, REQUIRE_NOT=builder_preview)] (additiveBuildNeedRepair : bool = false; buildTypeId : int = -1)
    if additiveBuildNeedRepair
      let count = count_available_buildings_by_type(squad_member__playerEid, buildTypeId)
      if count <= 0
        return
    fortification_repair__canRepair = (!isInVehicle && has(human_weap__currentGunEid, "previewTemplate"))
  fortification_repair__repairCost = 0f

[es(tag=server)]
def fortification_repair_start_es(evt : EventRepairFortificationStart;
                                  eid : EntityId;
                                  stockOfBuilderCapabilities : float;
                                  fortification_repair__canRepair : bool;
                                  fortification_repair__time : float;
                                  fortification_repair__repairCost : float;
                                  var fortification_repair__active : bool&;
                                  var fortification_repair__timer : float&;
                                  var fortification_repair__target : EntityId&)
  if !fortification_repair__canRepair
    return

  if fortification_repair__repairCost > stockOfBuilderCapabilities
    sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_no_require_resources", text="building_blocked_no_require_resources"]])
    return

  fortification_repair__active = true
  fortification_repair__timer = get_sync_time() + fortification_repair__time
  fortification_repair__target = evt.target

[es(tag=server, no_order, REQUIRE_NOT=deadEntity)]
def fortification_repair_process_es(info : UpdateStageInfoAct;
                                    eid : EntityId;
                                    fortification_repair__timer : float;
                                    fortification_repair__target : EntityId;
                                    human_use_object__useDist : float;
                                    transform : float3x4;
                                    enter_vehicle__atTime : float = -1.;
                                    isInVehicle : bool = false;
                                    var fortification_repair__active : bool&)
  if !fortification_repair__active || !fortification_repair__target
    return

  let operatorPos = transform[3]
  var rejectResupply = isInVehicle || enter_vehicle__atTime > 0.
  query(fortification_repair__target) <| $ [es] (transform : float3x4; object__useDist : float const?)
    rejectResupply ||= length_sq(transform[3] - operatorPos) > square(object__useDist ?? human_use_object__useDist)

  if rejectResupply
    send_net_event(eid, [[EventRepairFortificationStop]])
    return

  if fortification_repair__timer < info.curTime
    fortification_repair__active = false
    sendEvent(eid, [[EventRepairFortificationFinish]])

[es(tag=server)]
def fortification_repair_stop_es(evt : EventRepairFortificationStop;
                                 var fortification_repair__active : bool&;
                                 var fortification_repair__target : EntityId&)
  fortification_repair__active = false
  fortification_repair__target = INVALID_ENTITY_ID

[es(tag=server)]
def fortification_repair_finish_es(evt : EventRepairFortificationFinish; eid : EntityId)
  send_net_event(eid, [[EventRepairFortificationStop]])
