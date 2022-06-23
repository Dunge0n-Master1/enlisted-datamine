require ecs
require ecs.common
require EnlistedNet
require vehicle
require player
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events

[es(tag=server, no_order)]
def extinguisher_external(info : UpdateStageInfoAct;
                          eid : EntityId;
                          var extinguishable__extinguishTime : float&;
                          maintainable__operator : EntityId;
                          var extinguishable__inProgress : bool&)
  if !maintainable__operator || !extinguishable__inProgress || extinguishable__extinguishTime <= 0.0
    return
  extinguishable__extinguishTime -= info.dt
  if extinguishable__extinguishTime <= 0.0
    sendEventImmediate(eid, [[CmdStopBurn]])
    query(maintainable__operator) <| $ [es] (var extinguisher__active : bool&)
      extinguisher__active = false
    extinguishable__inProgress = false

def set_extinguishable_state(in_progress : bool;
                             operator_eid : EntityId;
                             target_eid : EntityId;
                             extinguish_time_mult : float = 1.0)
  query(target_eid) <| $ [es] (var maintainable__operator : EntityId&;
                               var extinguishable__extinguishTime : float&;
                               extinguishable__baseExtinguishTotalTime : float;
                               var extinguishable__extinguishTotalTime : float&;
                               var extinguishable__inProgress : bool&;
                               fire_damage__isBurn : bool)
    if !fire_damage__isBurn
      return
    maintainable__operator = operator_eid
    extinguishable__inProgress = in_progress
    if in_progress && extinguishable__extinguishTime < 0.0
      extinguishable__extinguishTotalTime = extinguishable__baseExtinguishTotalTime * extinguish_time_mult;
      extinguishable__extinguishTime = extinguishable__extinguishTotalTime

[es(tag=server, on_event=CmdActivateExtinguisher)]
def extinguisher_activate(evt : Event;
                          eid : EntityId;
                          maintenance__target : EntityId;
                          entity_mods__vehicleExtinguishTimeMult : float = 1.0;
                          var extinguisher__active : bool&)
  extinguisher__active = true
  set_extinguishable_state(true, eid, maintenance__target, entity_mods__vehicleExtinguishTimeMult)

def stop_extinguisher_impl(var extinguisher__active : bool&; maintenance__target : EntityId)
  set_extinguishable_state(false, INVALID_ENTITY_ID, maintenance__target)
  extinguisher__active = false

[es(tag=server, on_event=CmdStopExtinguisher)]
def extinguisher_stop(evt : Event; var extinguisher__active : bool&; maintenance__target : EntityId)
  stop_extinguisher_impl(extinguisher__active, maintenance__target)

[es(tag=server, after=extinguisher_external)]
def check_extinguishing_restrictions(info : UpdateStageInfoAct;
                                     maintenance__target : EntityId;
                                     var extinguisher__active : bool&;
                                     transform : float3x4;
                                     extinguisher__effectiveDistance : float;
                                     maintenance__canMaintainVehicle : bool = true)
  if !extinguisher__active
    return
  let pos = transform[3]
  var isTargetValid = false
  if maintenance__canMaintainVehicle
    query(maintenance__target) <| $ [es] (transform : float3x4; isAlive : bool)
      isTargetValid = isAlive && length_sq(transform[3] - pos) < square(extinguisher__effectiveDistance)
  if !isTargetValid || !maintenance__canMaintainVehicle
    stop_extinguisher_impl(extinguisher__active, maintenance__target)

[es(on_event=EventEnterVehicle)]
def stop_extinguishing_on_enter_vehicle(evt : Event;
                                        maintenance__target : EntityId;
                                        var maintenance__hasTarget : bool&;
                                        var extinguisher__active : bool&;
                                        isInVehicle : bool)
  if !extinguisher__active || isInVehicle
    return
  stop_extinguisher_impl(extinguisher__active, maintenance__target)
  maintenance__hasTarget = false
