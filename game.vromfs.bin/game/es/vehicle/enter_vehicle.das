require ecs
require app
require math
require math.base
require EnlistedHuman


[es(tag=server, track=enter_vehicle__atTime)]
def enter_vehicle_start_timer(evt : Event;
                              enter_vehicle__atTime : float;
                              var enter_vehicle__isInitDataSaved : bool&)
  if enter_vehicle__atTime >= 0.0
    enter_vehicle__isInitDataSaved = false

[es(tag=netClient, track=enter_vehicle__atTime)]
def enter_vehicle_init_restrictions_client(evt : Event;
                                           transform : float3x4;
                                           human_net_phys : HumanActor;
                                           enter_vehicle__atTime : float;
                                           enter_vehicle__vehicleEid : EntityId;
                                           var enter_vehicle__isInitDataSaved : bool&;
                                           var enter_vehicle__initPos : float3&;
                                           var enter_vehicle__initRelativePos : float3&;
                                           var enter_vehicle__initGunDir : float3&)
  if enter_vehicle__atTime < 0.0
    enter_vehicle__isInitDataSaved = false
    return
  enter_vehicle__initPos = transform[3]
  enter_vehicle__initGunDir = human_net_phys.phys.appliedCT.wishShootDir
  query(enter_vehicle__vehicleEid) <| $ [es] (transform : float3x4)
    enter_vehicle__initRelativePos = inverse(transform) * enter_vehicle__initPos
  enter_vehicle__isInitDataSaved = true

[es(tag=server, on_event=CmdPostPhysUpdate)]
def enter_vehicle_init_restrictions(evt : Event;
                                    transform : float3x4;
                                    human_net_phys : HumanActor;
                                    enter_vehicle__atTime : float;
                                    enter_vehicle__vehicleEid : EntityId;
                                    var enter_vehicle__initPos : float3&;
                                    var enter_vehicle__initRelativePos : float3&;
                                    var enter_vehicle__initGunDir : float3&;
                                    var enter_vehicle__initVehiclePos : float3&;
                                    var enter_vehicle__isInitDataSaved : bool&)
  if enter_vehicle__atTime < 0.0
    enter_vehicle__isInitDataSaved = false
    return
  if enter_vehicle__isInitDataSaved
    return
  enter_vehicle__initPos = transform[3]
  enter_vehicle__initGunDir = human_net_phys.phys.appliedCT.wishShootDir
  query(enter_vehicle__vehicleEid) <| $ [es] (transform : float3x4)
    enter_vehicle__initVehiclePos = transform[3]
    enter_vehicle__initRelativePos = inverse(transform) * enter_vehicle__initPos
  enter_vehicle__isInitDataSaved = true

[es(on_event=CmdPostPhysUpdate)]
def enter_vehicle_interrupt_on_gun_move(evt : Event;
                                        human_net_phys : HumanActor;
                                        enter_vehicle__gunMoveAngleThreshold : float;
                                        enter_vehicle__initGunDir : float3;
                                        var enter_vehicle__atTime : float&;
                                        enter_vehicle__isInitDataSaved : bool = true)
  if enter_vehicle__atTime < 0.0 || !enter_vehicle__isInitDataSaved
    return

  let gunDir = human_net_phys.phys.appliedCT.wishShootDir
  let angleThres = deg_to_rad(enter_vehicle__gunMoveAngleThreshold)
  let dotval = clamp(dot(enter_vehicle__initGunDir, gunDir), -1.0, 1.0)
  if dotval < cos(angleThres)
    enter_vehicle__atTime = -1.0

[es(on_event=CmdPostPhysUpdate)]
def enter_vehicle_interrupt_on_pos_change(evt : Event;
                                          transform aka visitor_transform : float3x4;
                                          enter_vehicle__vehicleEid : EntityId;
                                          enter_vehicle__initPos : float3;
                                          enter_vehicle__initRelativePos : float3;
                                          var enter_vehicle__atTime : float&;
                                          enter_vehicle__isInitDataSaved : bool = true)
  if enter_vehicle__atTime < 0.0 || !enter_vehicle__isInitDataSaved
    return

  query(enter_vehicle__vehicleEid) <| $ [es] (transform aka vehicle_transform : float3x4;
                                              enter_vehicle__moveThreshold : float = -1.;
                                              enter_vehicle__moveRelativeThreshold : float = -1.)
    if enter_vehicle__moveRelativeThreshold >= 0.
      let relativeInitPos = vehicle_transform * enter_vehicle__initRelativePos
      if distance_sq(relativeInitPos, visitor_transform[3]) > square(enter_vehicle__moveRelativeThreshold)
        enter_vehicle__atTime = -1.0
        return
    if enter_vehicle__moveThreshold >= 0. && distance_sq(enter_vehicle__initPos, visitor_transform[3]) > square(enter_vehicle__moveThreshold)
      enter_vehicle__atTime = -1.0

[es(tag=server, on_event=CmdPostPhysUpdate)]
def enter_vehicle_interrupt_vehicle_moved(evt : Event;
                                          var enter_vehicle__atTime : float&;
                                          enter_vehicle__vehicleEid : EntityId;
                                          enter_vehicle__isInitDataSaved : bool;
                                          enter_vehicle__initVehiclePos : float3)
  if enter_vehicle__atTime < 0.0 || !enter_vehicle__isInitDataSaved
    return
  query(enter_vehicle__vehicleEid) <| $ [es] (transform : float3x4; enter_vehicle__vehicleMoveThreshold : float)
    if enter_vehicle__vehicleMoveThreshold >= 0. && distance_sq(enter_vehicle__initVehiclePos, transform[3]) > square(enter_vehicle__vehicleMoveThreshold)
      enter_vehicle__atTime = -1.0

[es(tag=server, track=human_vehicle__can_take_seat)]
def enter_vehicle_interrupt_locked(evt : Event; human_vehicle__can_take_seat : bool; var enter_vehicle__atTime : float&)
  if !human_vehicle__can_take_seat
    enter_vehicle__atTime = -1.0
