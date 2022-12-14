require vehicle
require ecs
require app
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common

[es(tag=server, on_event=EventOnSeatOwnersChanged)]
def vehicle_inactive_update_timer_es(evt : Event;
                                     vehicle_seats__seatEids : EidList;
                                     var inactiveTimer : float&;
                                     inactiveDeleteTimer : float)
  var needDestroy = true
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if ownerEid != INVALID_ENTITY_ID
      needDestroy = false
      break
  inactiveTimer = needDestroy ? get_sync_time() + inactiveDeleteTimer : 0.0;

[es(tag=server, no_order)]
def vehicle_respawn_delete_inactive_es(info : UpdateStageInfoAct;
                                       eid : ecs::EntityId;
                                       inactiveTimer : float;
                                       lastOffender : EntityId = INVALID_ENTITY_ID;
                                       last_offender__gunPropsId : int = -1;
                                       last_offender__shellId : int = -1)
  if inactiveTimer > 0.0 && info.curTime > inactiveTimer
    setOptional(eid, "vehicle__isDestroyedWithoutCrew", true)
    sendEvent(eid, [[CmdExplosionFatal offender=lastOffender, gunPropsId=last_offender__gunPropsId, shellId=last_offender__shellId]])
    removeSubTemplate(eid, "destroy_inactive_vehicle")

[es(tag=server, no_order)]
def vehicle_shredder_distance_check_es(info : UpdateStageInfoAct;
                                       ownedBySquad : EntityId;
                                       transform : float3x4;
                                       destroyTimerCheckDistance : float;
                                       inactiveDeleteTimer : float;
                                       isExploded : bool;
                                       var inactiveTimer : float&)
  if inactiveTimer <= 0.0 || isExploded
    return
  if vehicle_has_owner_around(transform[3], ownedBySquad, destroyTimerCheckDistance)
    inactiveTimer = get_sync_time() + inactiveDeleteTimer
