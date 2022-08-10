require ecs
require math
require math.base
require DagorMath
require HumanPhys
require EnlistedHuman
require GeomNodeTree
require AnimV20
require CollRes


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
        geomtree_getNodeWtmScalar(animchar.nodeTree, seats_attach_nodes__nodeId, out_tm)
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
def human_vehicle_seats_es(info : UpdateStageInfoAct;
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
def human_vehicle_seats_update_phys_es(info : UpdateStageInfoAct;
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
  human_net_phys.phys.currentState.velocity = float3(0.0)
  human_net_phys.phys.currentState.location.P = DPoint3(nodeTm[3])
  human_net_phys.phys.currentState.walkNormal = nodeTm[1]

[es(track=isInVehicle)]
def human_phys_track_vehicle_seats_es(event : Event;
                                      isInVehicle : bool;
                                      var human_net_phys : HumanActor&;
                                      var disable_collision : bool&)
  human_phys_state_set_isAttached(human_net_phys.phys.currentState, isInVehicle)
  disable_collision = isInVehicle


def update_transform_from_local_seat_tm(is_shooter : bool;
                                        human_anim__vehicleSelected : EntityId;
                                        human_weap__blockAiming : bool = false;
                                        human_net_phys : HumanActor?;
                                        vehicle__localSeatTm : float3x4&;
                                        var transform aka human_transform : float3x4&)
  let isAiming = human_net_phys != null ? human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM) : false
  let shootingPassenger = !human_weap__blockAiming && isAiming
  if shootingPassenger == is_shooter
    query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4)
      let seatWtm = transform * vehicle__localSeatTm
      if shootingPassenger
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
def human_vehicle_seats_non_shooter_pre_animchar_es(info : UpdateStageInfoAct;
                                                    isInVehicle : bool;
                                                    human_anim__vehicleSelected : EntityId;
                                                    human_weap__blockAiming : bool = false;
                                                    human_net_phys : HumanActor?;
                                                    vehicle__localSeatTm : float3x4&;
                                                    var transform : float3x4&)
  if !isInVehicle
    return

  update_transform_from_local_seat_tm(/*is_shooter*/false, human_anim__vehicleSelected, human_weap__blockAiming,
                                      human_net_phys, vehicle__localSeatTm, transform)

[es(before=before_animchar_update_sync, after=after_net_phys_sync)]
def human_vehicle_seats_shooter_pre_animchar_es(info : UpdateStageInfoAct;
                                                isInVehicle : bool;
                                                human_anim__vehicleSelected : EntityId;
                                                human_weap__blockAiming : bool = false;
                                                human_net_phys : HumanActor?;
                                                vehicle__localSeatTm : float3x4&;
                                                var transform : float3x4&)
  if !isInVehicle
    return

  update_transform_from_local_seat_tm(/*is_shooter*/true, human_anim__vehicleSelected, human_weap__blockAiming,
                                      human_net_phys, vehicle__localSeatTm, transform)

[es(tag=server, on_appear, track=seat__isInHatch)]
def human_vehicle_seat_update_hatch_state(evt : Event; seat__isInHatch : bool; seat__ownerEid : EntityId)
  query(seat__ownerEid) <| $ [es] (var human_vehicle__isInHatch : bool&)
    human_vehicle__isInHatch = seat__isInHatch