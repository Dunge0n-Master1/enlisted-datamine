require ecs
require ecs.common
require EnlistedNet
require vehicle
require math
require math.base
require dm
require Dacoll
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common

[es(tag=server, no_order)]
def vehicle_underwater_es(info : UpdateStageInfoAct;
                          transform : float3x4;
                          eid : EntityId;
                          fire_damage__isBurn : bool;
                          drowningHeight : float;
                          var vehicle__isUnderwater : bool&)
  vehicle__isUnderwater = true
  let pos : float3 = transform[3] + normalize(transform[1]) * drowningHeight
  let distToLand : float = 5.
  if !is_valid_water_height(traceht_water_at_time(pos, distToLand, info.curTime, vehicle__isUnderwater))
    return

  if fire_damage__isBurn && vehicle__isUnderwater
    sendEvent(eid, [[CmdStopBurn]])
    sendEvent(eid, [[CmdRestore]])

[es(tag=server, after=vehicle_underwater_es, REQUIRE_NOT=(dm_phys_parts__enginePartIds, deadEntity))]
def vehicle_underwater_destroy_no_engine_es(info : UpdateStageInfoAct;
                                            eid : EntityId;
                                            vehicle__isUnderwater : bool;
                                            underWaterMaxTime : float;
                                            last_driver_leave_time : float;
                                            vehicle_seats__seatEids : EidList;
                                            var underWaterStartTime : float&;
                                            var isAlive : bool&)
  if !vehicle__isUnderwater
    underWaterStartTime = -1.f
    return

  let lastDriverTime : float = get_vehicle_driver(eid) != INVALID_ENTITY_ID ? info.curTime : last_driver_leave_time
  if lastDriverTime + underWaterMaxTime * 2.f < info.curTime
    underWaterStartTime = -1.f
    return
  if underWaterStartTime < 0.f
    underWaterStartTime = info.curTime
    return
  if info.curTime - underWaterStartTime > underWaterMaxTime
    for seatEid in vehicle_seats__seatEids
      let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      query(ownerEid) <| $ [es(REQUIRE_NOT=deadEntity)] ()
        sendEvent(eid, [[CmdKickFromVehicle eid=ownerEid]])
    isAlive = false


[es(tag=server, after=vehicle_underwater_es, REQUIRE_NOT=deadEntity)]
def vehicle_underwater_damage_engine(info : UpdateStageInfoAct;
                                     eid : EntityId;
                                     var damage_model : DamageModel&;
                                     dm_phys_parts__enginePartIds : IntList;
                                     underWaterMaxTime : float;
                                     var underWaterStartTime : float&;
                                     vehicle__isUnderwater : bool;
                                     last_driver_leave_time : float)
  var hasAliveEngines : bool = true
  for partId in dm_phys_parts__enginePartIds
    if int(get_rel_hp_fixed(damage_model.dmData, partId)) == 0
      hasAliveEngines = false
      break
  let lastDriverTime : float = get_vehicle_driver(eid) != INVALID_ENTITY_ID ? info.curTime : last_driver_leave_time
  if lastDriverTime + underWaterMaxTime * 2.f < info.curTime || !vehicle__isUnderwater || !hasAliveEngines
    underWaterStartTime = -1.f
    return
  if underWaterStartTime < 0.f
    underWaterStartTime = info.curTime
    return
  if info.curTime - underWaterStartTime > underWaterMaxTime
    for partId in dm_phys_parts__enginePartIds
      if int(get_rel_hp_fixed(damage_model.dmData, partId)) != 0
        deal_damage_to_part(damage_model, eid, partId, 0, 0, get_max_hp(damage_model.dmData, partId), HitData())
        underWaterStartTime = 0.0
