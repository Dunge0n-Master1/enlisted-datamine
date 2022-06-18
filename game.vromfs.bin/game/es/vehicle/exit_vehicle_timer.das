require ecs
require game.es.events
require game.es.vehicle.vehicle_seats_common

[es(tag=server, no_order)]
def exit_vehicle_timer_es(info : UpdateStageInfoAct;
                          eid : EntityId;
                          possessedByPlr : EntityId;
                          human_anim__vehicleSelected : EntityId;
                          var exit_vehicle__atTime : float&)
  if exit_vehicle__atTime < 0.f
    return
  if possessedByPlr == INVALID_ENTITY_ID
    exit_vehicle__atTime = -1.f
  elif info.curTime >= exit_vehicle__atTime
    exit_vehicle_now(eid, human_anim__vehicleSelected)
    exit_vehicle__atTime = -1.f
