require ecs
require ecs.common
require ecs.safe
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
    sendEvent(eid, [[EventOnVehicleExtinguished eid=maintainable__operator]])
    query(maintainable__operator) <| $ [es] (extinguisher__eid : EntityId; var extinguisher__active : bool&)
      extinguisher__active = false
      query(extinguisher__eid) <| $ [es] (var extinguisher__usesLeft : int&)
        extinguisher__usesLeft -= 1
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
                               repairable__extinguishRequired : bool)
    if !repairable__extinguishRequired
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

def find_extinguisher_kit(item_container : EidList)
  let itemIndex = find_index_if(each(item_container)) <| $(itemEid) => get_int(itemEid, "extinguisher__usesLeft") ?? 0 > 0
  return item_container?[itemIndex] ?? INVALID_ENTITY_ID

[es(tag=server, on_appear, track=itemContainer)]
def check_item_container_has_extinguisher(evt : Event;
                                          itemContainer : EidList;
                                          var extinguisher__hasExtinguisher : bool&;
                                          var extinguisher__eid : EntityId&)
  extinguisher__eid = find_extinguisher_kit(itemContainer)
  extinguisher__hasExtinguisher = !!extinguisher__eid

[es(tag=server, track=extinguisher__usesLeft)]
def track_extinguisher_uses(evt : Event; eid : EntityId; item__ownerEid : EntityId; extinguisher__usesLeft : int)
  if extinguisher__usesLeft <= 0
    query(item__ownerEid) <| $ [es] (itemContainer : EidList;
                                     var extinguisher__hasExtinguisher : bool&;
                                     var extinguisher__eid : EntityId&)
      if extinguisher__eid == eid
        extinguisher__eid = find_extinguisher_kit(itemContainer)
        extinguisher__hasExtinguisher = !!extinguisher__eid
