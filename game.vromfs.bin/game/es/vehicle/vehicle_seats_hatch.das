require ecs
require ecs.common
require math.base
require math.ang
require vehicle
require game.utils.hero
require EnlistedHuman
require HumanPhys
require AnimV20
require GeomNodeTree
require DagorSystem
require DagorMath
require ecs.safe

let
  openVel = 5.0f
  timeToClose = 1.0f / openVel
  hatchRot = deg_to_rad(-89.0f)


def get_node_name(nodes, node_no)
  return node_no >= 0 && node_no < length(nodes) ? get_string(nodes[node_no], "") : ""


def get_node_id_and_tm(animchar, node_name; var out_node_id &; var out_node_tm)
  if node_name == ""
    return false

  out_node_id = geomtree_findNodeIndex(*animchar.nodeTree, node_name)
  if out_node_id < 0
    logerr("Hatch node '{node_name}' not found")
    return false

  geomtree_getNodeTmScalar(*animchar.nodeTree, out_node_id, out_node_tm)
  return true

[es(tag=server, on_appear)]
def init_hatch_nodes(evt : Event;
                     seat__id : int;
                     seat__vehicleEid : EntityId;
                     var seat__isHatchControlInversed : bool&;
                     var seats_hatch_nodes__isValid : bool&;
                     var seats_hatch_nodes__nodeIdX : int&;
                     var seats_hatch_nodes__nodeIdY : int&;
                     var seats_hatch_nodes__maxPos : float&;
                     var seats_hatch_nodes__rotAxis : float3&;
                     var seats_hatch_nodes__nodeTmX : float3x4;
                     var seats_hatch_nodes__nodeTmY : float3x4)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array; animchar : AnimcharBaseComponent)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    let hatchNodes = get_ecs_array(*seat, "hatchNodes")
    if hatchNodes == null
      return

    let nodeCount = length(*hatchNodes)
    assert(nodeCount <= 2)

    get_node_id_and_tm(animchar, get_node_name(*hatchNodes, 0), seats_hatch_nodes__nodeIdX, seats_hatch_nodes__nodeTmX)
    get_node_id_and_tm(animchar, get_node_name(*hatchNodes, 1), seats_hatch_nodes__nodeIdY, seats_hatch_nodes__nodeTmY)

    seats_hatch_nodes__maxPos  = get_float(*seat, "maxPosWithOpenHatch") ?? 1.f
    seats_hatch_nodes__rotAxis = get_Point3(*seat, "hatchRotationAxis") ?? float3(1.f, 0.f, 0.f)

    seats_hatch_nodes__isValid = seats_hatch_nodes__nodeIdX >= 0
    seat__isHatchControlInversed = seat?.isHatchControlInversed ?? false

def rotate_hatch_node(var animchar : AnimcharBaseComponent;
                      hatch__node_id : int;
                      hatch__node_tm : float3x4&;
                      rot_m : float3x4&)
  if hatch__node_id >= 0
    let nodeTm = hatch__node_tm * rot_m
    geomtree_setNodeTmScalar(*animchar.nodeTree, hatch__node_id, nodeTm)

[es(tag=server, after=after_net_phys_sync)]
def vehicle_seats_hatch_crouch_es(info : UpdateStageInfoAct; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seats_hatch_nodes__isValid : bool; seat__ownerEid : EntityId; seat__isPlayer : bool; seat__isHatchControlInversed : bool = false; var seat__isInHatch : bool&)
      if !seats_hatch_nodes__isValid || !seat__isPlayer
        return
      seat__isInHatch = false
      query(seat__ownerEid) <| $ [es] (human_net_phys : HumanActor)
        seat__isInHatch = is_control_bit_set(human_net_phys.phys.appliedCT, HumanPhysControlType HCT_CROUCH) ^^ seat__isHatchControlInversed
      return


[es(after=vehicle_seats_hatch_crouch_es)]
def vehicle_seats_hatch_es(info : UpdateStageInfoAct;
                           animchar__updatable : bool;
                           vehicle_seats__seatEids : EidList;
                           var animchar : AnimcharBaseComponent)
  if !animchar__updatable
    return
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (var seats_attach_nodes__attachTm : float3x4;
                              var seats_hatch_nodes__openPos : float&;
                              var seat__isInHatch : bool&;
                              seats_hatch_nodes__maxPos : float;
                              seats_hatch_nodes__rotAxis : float3;
                              seats_hatch_nodes__isValid : bool;
                              seats_hatch_nodes__nodeIdX : int;
                              seats_hatch_nodes__nodeIdY : int;
                              seats_hatch_nodes__nodeTmX : float3x4;
                              seats_hatch_nodes__nodeTmY : float3x4;
                              seats_attach_nodes__initialTm : float3x4;
                              seat__ownerEid : EntityId;
                              seat__isPlayer : bool;
                              seats_switch_time__time : float = -1.f;
                              seats_switch_time__newSeatNo : int = -1)
      let switchTime      = seats_switch_time__time
      let switchNewSeatNo = seats_switch_time__newSeatNo
      let isHatchNodesValid = seats_hatch_nodes__isValid
      let isOwnerAlive = get_bool(seat__ownerEid, "isAlive") ?? true
      let isInHatch = seat__isInHatch
      let isOpen = !!seat__ownerEid && seat__isPlayer && isOwnerAlive && isInHatch && isHatchNodesValid && ((switchTime < 0.0f && switchNewSeatNo < 0) || switchTime > timeToClose)
      if has(seat__ownerEid, "hero") && seat__isPlayer
        query() <| $ [es] (var shooter_cam__alternative_settings : bool&)
          shooter_cam__alternative_settings = isHatchNodesValid
      if !isHatchNodesValid
        return
      seats_hatch_nodes__openPos = clamp(seats_hatch_nodes__openPos + (isOpen ? 1.0f : -1.0f) * openVel * info.dt, 0.0f, 1.0f)
      let curPos = seats_hatch_nodes__openPos
      let trgPos = (isInHatch ? 1.0f : 0.0f) * seats_hatch_nodes__openPos * seats_hatch_nodes__maxPos
      let k = clamp(safediv(seats_hatch_nodes__maxPos - curPos * 2.0f, seats_hatch_nodes__maxPos), 0.0f, 1.0f)
      var pos = seats_attach_nodes__initialTm[3]
      seat__isInHatch = (seats_hatch_nodes__openPos != 0.f)
      pos.y = approach(seats_attach_nodes__attachTm[3].y, pos.y + trgPos, info.dt, 0.1f)
      seats_attach_nodes__attachTm[3] = pos
      let angles = seats_hatch_nodes__rotAxis * (1.0f - k) * hatchRot
      let mRot = make_rot_cw_zyx(angles)
      rotate_hatch_node(animchar, seats_hatch_nodes__nodeIdX, seats_hatch_nodes__nodeTmX, mRot)
      rotate_hatch_node(animchar, seats_hatch_nodes__nodeIdY, seats_hatch_nodes__nodeTmY, mRot)


[es(tag=gameClient, on_event=EventOnSeatOwnersChanged)]
def vehicle_seats_hatch_on_change_owner(evt : Event; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seats_hatch_nodes__isValid : bool)
      if has(seat__ownerEid, "hero") && !seats_hatch_nodes__isValid
        query() <| $ [es] (var shooter_cam__alternative_settings : bool&)
          shooter_cam__alternative_settings = false