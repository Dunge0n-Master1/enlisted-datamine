require ecs
require app
require DagorMath
require DagorMathUtils
require HumanPhys
require EnlistedHuman
require AnimV20
require GeomNodeTree
require Dacoll
require GamePhys
require math.base
require math.ang
require game.es.events
require game.events_game
require common_shooter.events_common_shooter
require common_shooter.es.human.bipod_common
require PhysMat
require RendInst

[es(tag=server, on_appear)]
def bipod_init_offset(evt : Event;
                      animchar : AnimcharBaseComponent;
                      gun__bipodNodes : StringList;
                      var gun__bipodOffset : float3&)
  for nodeName in gun__bipodNodes
    let nodeId = geomtree_findNodeIndex(animchar.nodeTree, string(nodeName))
    if nodeId < 0
      continue

    var rootTm : float3x4
    geomtree_getNodeWtmScalar(animchar.nodeTree, 0, rootTm)

    var nodeTm : float3x4
    geomtree_getNodeWtmScalar(animchar.nodeTree, nodeId, nodeTm)

    spawXZ(rootTm)
    spawXZ(nodeTm)

    let relTm = inverse(rootTm) * nodeTm
    gun__bipodOffset = relTm[3]

    break

[es(tag=gameClient, REQUIRE=hero, track=bipod__enabled)]
def bipod_solve_limits_es(evt : Event;
                          bipod__anchorDir : float3;
                          bipod__anchorPos : float3;
                          bipod__anchorNormal : float3;
                          bipod__enabled : bool;
                          transform : float3x4;
                          human_weap__currentGunEid : EntityId;
                          human_net_phys : HumanActor;
                          var bipod__yawLimit : float2&)
  if !bipod__enabled
    return

  bipod_solve_limits(bipod__anchorDir, bipod__anchorPos, bipod__anchorNormal,
                     transform, human_weap__currentGunEid, human_net_phys, bipod__yawLimit)

[es(after=human_phys_es, before=after_net_phys_sync)]
def bipod_human_act_es(evt : CmdPostPhysUpdate;
                       bipod__anchorPos : float3;
                       bipod__anchorNormal : float3;
                       bipod__isCrawl : bool;
                       human_weap__currentGunEid : EntityId;
                       var bipod__enabled : bool&;
                       var human_net_phys : HumanActor&;
                       bipod__crawlLegsFloat : float = 0.8;
                       bipod__anchorDistLimit : float = 4.0) // max 4 meters from anchor by default
  if !bipod__enabled
    return

  if (human_net_phys.phys.currentState.moveState == HUMoveState EMS_WALK ||
      human_net_phys.phys.currentState.moveState == HUMoveState EMS_SPRINT)
    bipod__enabled = false
    return

  var humanTm, humanItm : float3x4
  location_toTM(human_net_phys.phys.previousState.location, humanTm)
  if length_sq(humanTm[3] - bipod__anchorPos) > square(bipod__anchorDistLimit)
    bipod__enabled = false
    return
  humanItm = inverse(humanTm)

  let aimAngle = dir_to_angles(human_net_phys.phys.appliedCT.wishShootDir)

  query(human_weap__currentGunEid) <| $ [es] (gun__bipodOffset : float3)
    var gunTm : float3x4
    calc_gun_tm(gunTm, human_net_phys, humanTm, aimAngle.y)

    var offset = -(humanItm * gunTm * gun__bipodOffset)

    assume walkNormal = human_net_phys.phys.currentState.walkNormal
    let worldOffset = quat(bipod__anchorNormal, aimAngle.x) * offset
    let d = dot(walkNormal, worldOffset)
    if bipod__isCrawl && d < 0.0
      offset += -d * bipod__crawlLegsFloat * walkNormal

    var wishPos = calc_human_pos(aimAngle.x, bipod__anchorPos, offset, bipod__anchorNormal)

    var gunAngles = float2(-aimAngle.x, 0.f)
    if bipod__isCrawl
      let dirToWishPos = normalize(bipod__anchorPos - wishPos)
      gunAngles = -dir_to_angles(dirToWishPos)

    let gunDir = angles_to_dir(gunAngles)
    orient_setYP0(human_net_phys.phys.currentState.location.O, gunDir)

    var ccdTm : float3x4
    location_toTM(human_net_phys.phys.currentState.location, ccdTm)

    let ccdPos = human_net_phys.phys.ccdPos
    let prevWorldCcdPos = ccdTm * ccdPos

    if !bipod__isCrawl
      wishPos.y = float(human_net_phys.phys.currentState.location.P.y)

    human_net_phys.phys.currentState.location.P = DPoint3(wishPos)
    human_net_phys.phys.currentState.velocity = float3(0.f)
    human_net_phys.phys.currentState.breathOffset = float2(0.f)
    human_net_phys.phys.currentState.moveState = HUMoveState EMS_STAND

    assume height = human_net_phys.phys.currentState.height
    if bipod__isCrawl
      height = -1.0
    else
      let humanHt = 1.6
      let zeroHt = humanHt * 0.45
      let htDelta = (bipod__anchorPos.y - wishPos.y) - zeroHt
      if htDelta > 0.0
        height = clamp(htDelta / (humanHt - zeroHt), 0.0, 1.0)
        height = 1.0 - square(1.0 - height)
      else
        height = clamp(htDelta / zeroHt, -0.1, 0.0)
        height = -(height * height * 10.0)
      let pitchHt = 1.1
      height = clamp(height - sin(aimAngle.y) * pitchHt, -0.1, 1.0)

    location_toTM(human_net_phys.phys.currentState.location, ccdTm)

    let collRad = human_net_phys.phys.collRad
    let ccdRad  = human_net_phys.phys.ccdRad
    let speedCollisionHardness = human_net_phys.phys.speedCollisionHardness
    let ccdToPos = ccdTm * ccdPos
    let totalOffset = ccdToPos - prevWorldCcdPos
    human_net_phys.phys |> human_phys_processCcdOffset(ccdTm, ccdToPos, totalOffset, collRad - ccdRad, speedCollisionHardness, true, ccdPos)

[es(tag=server)]
def human_place_bipod_server_es(evt : RequestBipodPlacing;
                                var bipod__enabled : bool&;
                                var bipod__isCrawl : bool&;
                                var bipod__placePos : float3&;
                                var bipod__yawLimit : float2&;
                                var bipod__anchorPos : float3&;
                                var bipod__anchorDir : float3&;
                                var bipod__anchorNormal : float3&)
  bipod__enabled = evt.enabled
  bipod__placePos = evt.placePos
  bipod__yawLimit = evt.yawLimit
  bipod__isCrawl = evt.isCrawl
  bipod__anchorPos = evt.anchorPos
  bipod__anchorDir = evt.anchorDir
  bipod__anchorNormal = evt.anchorNormal

def trace_bipod_attached_ri(pos)
  var riDesc = RendInstDesc()
  var norm : float3
  var matId = PHYSMAT_INVALID
  let traceDir = float3(0, -1, 0) // trace down
  var minHeight = 1.0f
  let res = traceray_normalized(pos, traceDir, minHeight, matId, norm, ETF_RI, riDesc, -1)
  if res && riDesc.isValid
    return int(riDesc.riExtraHandle)
  return -1

[es(tag=server)]
def human_bipod_deattached_from_ri_es(evt : EventRendinstDestroyed; var bipod__attachedToRi : int&; var bipod__enabled : bool&)
  if bipod__enabled && int(evt.riexHandle) == bipod__attachedToRi
    bipod__enabled = false
    bipod__attachedToRi = -1

[es(tag=server, track=bipod__enabled)]
def human_bipod_attached_to_ri_es(evt : Event; bipod__enabled : bool; bipod__placePos : float3; var bipod__attachedToRi : int&)
  if !bipod__enabled
    bipod__attachedToRi = -1
    return

  bipod__attachedToRi = trace_bipod_attached_ri(bipod__placePos)
