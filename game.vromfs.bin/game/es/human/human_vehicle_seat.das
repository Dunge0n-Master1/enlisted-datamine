require ecs
require math
require math.base
require DagorMath
require HumanPhys
require EnlistedHuman
require GeomNodeTree
require AnimV20
require CollRes
require game.es.vehicle.vehicle_seats_common
require game.es.human.human_vehicle_common
require vehicle
require enlisted.events_enlisted


def get_seat_tm(human_eid, vehicle_eid; var out_tm)
  var res = false
  query(vehicle_eid) <| $ [es] (vehicle_seats__seatEids : EidList;
                                animchar : AnimcharBaseComponent;
                                collres : CollisionResource;
                                transform : float3x4)
    var ownerSeatEid = INVALID_ENTITY_ID
    for seatEid in vehicle_seats__seatEids
      let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      if ownerEid == human_eid
        ownerSeatEid = seatEid
        break

    query(ownerSeatEid) <| $ [es] (seats_attach_nodes__nodeId : int;
                                   seats_attach_nodes__collNodeId : int;
                                   seats_attach_nodes__ignoreAttachNodeRotation : bool;
                                   seats_attach_nodes__nodeItm : float3x4;
                                   seats_attach_nodes__attachTm : float3x4)
      if seats_attach_nodes__nodeId >= 0
        geomtree_getNodeWtmScalar(*animchar.nodeTree, seats_attach_nodes__nodeId, out_tm)
      elif seats_attach_nodes__collNodeId >= 0
        collres_get_collision_node_tm(collres, seats_attach_nodes__collNodeId,
                                      transform, null, out_tm)
      else
        out_tm = transform

      if seats_attach_nodes__ignoreAttachNodeRotation
        let nodePos = out_tm[3]
        out_tm = out_tm * seats_attach_nodes__nodeItm
        out_tm[3] = nodePos
      elif det(out_tm) < 0.0f
        orthonormalize(out_tm)

      out_tm = out_tm * seats_attach_nodes__attachTm
      res = true
  return res

[es(before=before_animchar_update_sync)]
def human_vehicle_seats_es(info : ParallelUpdateFrameDelayed;
                           eid : EntityId;
                           isInVehicle : bool;
                           human_anim__vehicleSelected : EntityId;
                           var vehicle__localSeatTm : float3x4&;
                           var vehicle__globalSeatTm : float3x4&)
  if !isInVehicle
    return

  var nodeTm = IDENT_TM
  if !get_seat_tm(eid, human_anim__vehicleSelected, nodeTm)
    return
  query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4)
    let inverseTm = inverse(transform);
    vehicle__localSeatTm = inverseTm * nodeTm
    vehicle__globalSeatTm = nodeTm

[es(before=human_phys_es)]
def human_vehicle_seats_update_phys_es(info : ParallelUpdateFrameDelayed;
                                       eid : EntityId;
                                       isInVehicle : bool;
                                       human_anim__vehicleSelected : EntityId;
                                       var human_net_phys : HumanActor&)
  if !isInVehicle
    return

  var nodeTm = IDENT_TM
  if !get_seat_tm(eid, human_anim__vehicleSelected, nodeTm)
    return
  human_net_phys.phys.currentState.bodyOrientDir = nodeTm[0].xz
  human_net_phys.phys.currentState.moveState = HUMoveState EMS_STAND
  // Human in vehicle has velocity of the vehicle, currently to aid server-side hit verification
  human_net_phys.phys.currentState.velocity = get_Point3(human_anim__vehicleSelected, "net_phys__currentStateVelocity") ?? float3(0.0)
  human_net_phys.phys.currentState.location.P = DPoint3(nodeTm[3])
  human_net_phys.phys.currentState.walkNormal = nodeTm[1]

[es(track=isInVehicle, on_appear)]
def human_phys_track_vehicle_seats_es(event : Event;
                                      isInVehicle : bool;
                                      var human_net_phys : HumanActor&;
                                      var disable_collision : bool&)
  human_phys_state_set_isAttached(human_net_phys.phys.currentState, isInVehicle)
  disable_collision = isInVehicle


def update_transform_from_local_seat_tm(is_shooter : bool;
                                        human_anim__vehicleSelected : EntityId;
                                        human_vehicle__isHoldingGunPassenger : bool = false;
                                        vehicle__localSeatTm : float3x4&;
                                        var transform aka human_transform : float3x4&)
  if human_vehicle__isHoldingGunPassenger == is_shooter
    query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4)
      let seatWtm = transform * vehicle__localSeatTm
      if human_vehicle__isHoldingGunPassenger
        let helperTm = vehicle__localSeatTm * transform
        let up = normalize(helperTm[1])
        let left = normalize(cross(human_transform[0], up))
        let forward = normalize(cross(up, left))
        human_transform[0] = forward
        human_transform[1] = up
        human_transform[2] = left
        human_transform[3] = seatWtm[3]
      else
        human_transform = seatWtm

[es(before=before_animchar_update_sync, after=(human_weap_update_es, human_locomotion_es, after_net_phys_sync))]
def human_vehicle_seats_non_shooter_pre_animchar_es(info : ParallelUpdateFrameDelayed;
                                                    isInVehicle : bool;
                                                    human_anim__vehicleSelected : EntityId;
                                                    human_vehicle__isHoldingGunPassenger : bool = false;
                                                    vehicle__localSeatTm : float3x4&;
                                                    var transform : float3x4&)
  if !isInVehicle
    return

  update_transform_from_local_seat_tm(/*is_shooter*/false, human_anim__vehicleSelected, human_vehicle__isHoldingGunPassenger,
                                      vehicle__localSeatTm, transform)

[es(before=before_animchar_update_sync, after=after_net_phys_sync)]
def human_vehicle_seats_shooter_pre_animchar_es(info : ParallelUpdateFrameDelayed;
                                                isInVehicle : bool;
                                                human_anim__vehicleSelected : EntityId;
                                                human_vehicle__isHoldingGunPassenger : bool = false;
                                                vehicle__localSeatTm : float3x4&;
                                                var transform : float3x4&)
  if !isInVehicle
    return

  update_transform_from_local_seat_tm(/*is_shooter*/true, human_anim__vehicleSelected, human_vehicle__isHoldingGunPassenger,
                                      vehicle__localSeatTm, transform)

[es(tag=server, on_appear, track=seat__isInHatch)]
def human_vehicle_seat_update_hatch_state(evt : Event; seat__isInHatch : bool; seat__ownerEid : EntityId)
  query(seat__ownerEid) <| $ [es] (var human_vehicle__isInHatch : bool&)
    human_vehicle__isInHatch = seat__isInHatch


[es(tag=server, track=isInVehicle)]
def human_vehicle_seat_disable_hatch_state_on_exit_vehicle(evt : Event; isInVehicle : bool; var human_vehicle__isInHatch : bool&)
  if !isInVehicle
    human_vehicle__isInHatch = false

[es(on_appear, track=(isInVehicle, isInVehicleHidden, isPassenger, human_vehicle__isInHatch, human_vehicle__occupiedSeatEid))]
def human_vehicle_update_can_hold_weapon(evt : Event;
                                         isInVehicle : bool;
                                         isInVehicleHidden : bool;
                                         isPassenger : bool;
                                         human_vehicle__isInHatch : bool;
                                         human_vehicle__occupiedSeatEid : EntityId;
                                         var human_vehicle__canHoldWeapon : bool&)
  var canControlTurrets = false
  var isHoldGunModeAllowed = true
  query(human_vehicle__occupiedSeatEid) <| $ [es] (seat__availableControls : VehicleControlsState;
                                                   seat__isHoldGunModeAllowed : bool)
    canControlTurrets = seat__availableControls.canControlTurrets
    isHoldGunModeAllowed = seat__isHoldGunModeAllowed

  human_vehicle__canHoldWeapon = is_hold_gun_mode_allowed(isInVehicle, isInVehicleHidden, isPassenger, isHoldGunModeAllowed, human_vehicle__isInHatch, canControlTurrets)


[es(track=(human_net_phys__isHctAim, human_weap__throwMode, human_weap__blockAiming, human_weap__currentGunSlot, human_vehicle__canHoldWeapon, human_vehicle__isHoldGunMode))]
def human_vehicle_update_holding_gun_passenger_mode(evt : Event;
                                                    human_net_phys__isHctAim : bool;
                                                    human_weap__throwMode : bool;
                                                    human_weap__blockAiming : bool;
                                                    human_weap__currentGunSlot : int;
                                                    human_vehicle__canHoldWeapon : bool;
                                                    human_vehicle__isHoldGunMode : bool;
                                                    var human_vehicle__isHoldingGunPassenger : bool&)
  human_vehicle__isHoldingGunPassenger = (human_vehicle__canHoldWeapon
                                     && (human_net_phys__isHctAim || human_weap__throwMode || human_vehicle__isHoldGunMode)
                                     && !human_weap__blockAiming
                                     && is_gun_slot_allowed_to_hold_gun_in_hatch(human_weap__currentGunSlot))


[es(tag=input, REQUIRE=hero, on_appear, track=(human_weap__currentGunEid, human_vehicle__isHoldingGunPassenger))]
def human_vehicle_update_shooting_passenger_mode(evt : Event;
                                                 human_weap__currentGunEid : EntityId;
                                                 human_vehicle__isHoldingGunPassenger : bool;
                                                 var human_vehicle__isShootingPassenger : bool&)
  human_vehicle__isShootingPassenger = human_vehicle__isHoldingGunPassenger && !has(human_weap__currentGunEid, "notShootableGun")


[es(tag=server, track=(human_vehicle__canHoldWeapon, human_net_phys__isHoldGunModeBit))]
def human_vehicle_update_hold_gun_mode(evt : Event;
                                       human_vehicle__canHoldWeapon : bool;
                                       human_net_phys__isHoldGunModeBit : bool;
                                       var human_vehicle__isHoldGunMode : bool&)
  human_vehicle__isHoldGunMode = human_net_phys__isHoldGunModeBit && human_vehicle__canHoldWeapon
