module bipod_common shared

require ecs
require math
require math.base
require math.ang
require Dacoll
require DagorMath
require DagorMathUtils
require AnimV20
require GeomNodeTree
require HumanPhys
require EnlistedHuman

let sphereRadius = 0.2f
let bodySphereRadius = 0.25f
let groundOffsetForCrawl = bodySphereRadius + 0.25f

struct BodyMinMaxPointsInfo
  headMin : float3 = float3()
  bodyMin : float3 = float3()
  legsMin : float3 = float3()
  headMax : float3 = float3()
  bodyMax : float3 = float3()
  legsMax : float3 = float3()

struct BodyFromToPointsInfo
  headTo : float3 = float3()
  bodyTo : float3 = float3()
  legsTo : float3 = float3()
  headFrom : float3 = float3()
  bodyFrom : float3 = float3()
  legsFrom : float3 = float3()

def spawXZ(var tm : float3x4)
  let tmp = tm[0]
  tm[0] = -tm[2]
  tm[2] = tmp

def get_gun_tm(gunEid; var gunTm : float3x4) : bool
  var isGunFound = false
  query(gunEid) <| $ [es] (animchar : AnimcharBaseComponent)
    geomtree_getNodeWtmScalar(animchar.nodeTree, 0, gunTm)
    spawXZ(gunTm)
    isGunFound = true
  return isGunFound

let
  BIPOD_HEIGHT = 0.25
  BIPOD_HEIGHT_CRAWL = 0.15
  BIPOD_SPHERE_CAST_DIST = 2.
  BIPOD_PLACEMENT_TOLERANCE = 0.25
  MAX_INCLINE_SIN = 0.866025 /* sin(deg_to_rad(60.)) */
  MIN_DIST_TO_PLACE_POS = 0.75
  BIPOD_SUPPORT_OFFSET_X = 0.05
  BIPOD_SUPPORT_OFFSET_Y = 0.1
  DEFAULT_SPHERE_CAST_MASK = int(PhysLayer EPL_ALL) & ~(int(PhysLayer EPL_CHARACTER) | int(PhysLayer EPL_KINEMATIC) | int(PhysLayer EPL_DEBRIS))

struct BipodPlacingResult
  canBePlaced : bool = false
  placePos : float3 = float3(0.f)
  placeNormal : float3 = float3(0.f)

def check_bipod_placing_point(point, bipodHeight, sphereCastDist, maxInclineSin; trace_handle : TraceMeshFaces?)
  var queryOut = ShapeQueryOutput()
  var placePos = float3(0.f)
  var placeNormal = float3(0.f)
  var canBePlaced = false

  let traceTo = point + float3(0., -sphereCastDist, 0.)
  if sphere_cast_ex(point, traceTo, 0.05, queryOut, -1, trace_handle, DEFAULT_SPHERE_CAST_MASK)
    let inclineSin = abs(queryOut.norm.y)
    let placeHeight = queryOut.t * sphereCastDist
    placePos = queryOut.res
    placeNormal = queryOut.norm
    canBePlaced = placeHeight <= (bipodHeight + BIPOD_PLACEMENT_TOLERANCE) && inclineSin >= maxInclineSin

  return [[BipodPlacingResult placePos = placePos, placeNormal=placeNormal, canBePlaced = canBePlaced]]

def find_placing_point(from, to : int; gunTm, bipodOffset; trace_handle : TraceMeshFaces?)
  var res : BipodPlacingResult
  for step in range(from, to)
    let pos = gunTm * (bipodOffset + float3(float(step) * BIPOD_SUPPORT_OFFSET_X, BIPOD_SUPPORT_OFFSET_Y, 0.))
    res = check_bipod_placing_point(pos, BIPOD_HEIGHT, BIPOD_SPHERE_CAST_DIST, MAX_INCLINE_SIN, trace_handle)
    if res.canBePlaced
      return res
  return res

def calc_bipod_placing(gunEid : EntityId;
                       isCrawl : bool;
                       crawlLimits : float4;
                       pitchLimits : float2;
                       aimAngle : float2;
                       aimTm : float3x4;
                       bipodOffset : float3;
                       trace_handle : TraceMeshFaces?)
  var res : BipodPlacingResult

  var gunTm : float3x4
  if !get_gun_tm(gunEid, gunTm)
    return res

  res = find_placing_point(-1, 4, gunTm, bipodOffset, trace_handle)
  if res.canBePlaced
    find_query() <| $ [es] (camera__active : bool; transform : float3x4)
      if !camera__active
        return false
      let saneDistFromCameraSq = square(BIPOD_SPHERE_CAST_DIST)
      if distance_sq(transform[3], res.placePos) > saneDistFromCameraSq
        res.canBePlaced = false
      else
        var queryOut = ShapeQueryOutput()
        if sphere_cast_ex(transform[3], res.placePos, 0.05, queryOut, -1, trace_handle, DEFAULT_SPHERE_CAST_MASK)
          res.canBePlaced &&= queryOut.t >= MIN_DIST_TO_PLACE_POS
      return true

  if !res.canBePlaced
    return res

  let anchorDir = calculate_anchor_dir(isCrawl, res.placeNormal, aimTm)

  if isCrawl
    if aimAngle != clamp_angles_by_dir(aimAngle, crawlLimits, anchorDir)
      res.canBePlaced = false
  else
    if aimAngle.y != clamp(aimAngle.y, deg_to_rad(pitchLimits.x), deg_to_rad(pitchLimits.y))
      res.canBePlaced = false

  return res

def calculate_anchor_dir(isCrawl : bool; normal : float3; aimTm : float3x4)
  return normalize(isCrawl ?
                   cross(cross(normal, aimTm[0]), normal) :
                   float3(aimTm[0].x, 0., aimTm[0].z))

def calc_human_pos(yaw, anchorPos, offset, normal)
  return anchorPos + quat(normal, yaw) * offset

def calc_gun_tm(var gunTm; humanPhys; humanTm; gunPitch)
  human_phys_calcGunTm(humanPhys.phys, PrecomputedPresetMode FPV, humanTm, gunPitch, humanPhys.phys.currentState.leanPosition, humanPhys.phys.currentState.height, gunTm)

def calc_body_points(wishYaw : float;
                     prevYaw : float;
                     anchorOffset : float3;
                     anchorPos : float3;
                     anchorNormal : float3;
                     human_net_phys : HumanActor;
                     var bodyFromToPoints : BodyFromToPointsInfo&)
  let isCrawl = human_net_phys.phys.currentState.isCrawl

  let humanHeight = cvt(human_net_phys.phys.currentState.height, -1.f, 1.f, 0.f, 1.5f)
  let height      = float3(0., humanHeight, 0.)

  // This is just approximate points for head, body and legs
  // Maybe in the future actual nodes will be used but this is enough for now
  let head = (isCrawl ? float3(0.7, groundOffsetForCrawl, -0.25) : float3(0.2, 0., -0.25)) + height
  let body = (isCrawl ? float3(0., groundOffsetForCrawl, 0.) : float3(0.)) + 0.5 * height
  let legs = float3(-0.7, groundOffsetForCrawl, 0.) + 0.5 * height

  let prevPos = calc_human_pos(prevYaw, anchorPos, anchorOffset, anchorNormal)
  let wishPos = calc_human_pos(wishYaw, anchorPos, anchorOffset, anchorNormal)

  let prevOrient = quat(anchorNormal, prevYaw)
  let wishOrient = quat(anchorNormal, wishYaw)

  bodyFromToPoints.headFrom = prevPos + prevOrient * head
  bodyFromToPoints.headTo   = wishPos + wishOrient * head

  bodyFromToPoints.bodyFrom = prevPos + prevOrient * body
  bodyFromToPoints.bodyTo   = wishPos + wishOrient * body

  bodyFromToPoints.legsFrom = prevPos + prevOrient * legs
  bodyFromToPoints.legsTo   = wishPos + wishOrient * legs

def is_safe_angle(isCrawl, bodyFromToPoints)
  var queryOut = ShapeQueryOutput()
  return (!sphere_cast(bodyFromToPoints.headFrom, bodyFromToPoints.headTo, sphereRadius, queryOut, -1) &&
          !sphere_cast(bodyFromToPoints.bodyFrom, bodyFromToPoints.bodyTo, bodySphereRadius, queryOut, -1) &&
          !(isCrawl && sphere_cast(bodyFromToPoints.legsFrom, bodyFromToPoints.legsTo, sphereRadius, queryOut, -1)))

def bipod_solve_limits(bipod__anchorDir : float3;
                       bipod__anchorPos : float3;
                       bipod__anchorNormal : float3;
                       transform : float3x4;
                       human_weap__currentGunEid : EntityId;
                       human_net_phys : HumanActor;
                       var bipod__yawLimit : float2&) : BodyMinMaxPointsInfo

  var body_points = BodyMinMaxPointsInfo()

  query(human_weap__currentGunEid) <| $ [es] (gun__bipodOffset : float3)
    var gunTm : float3x4
    calc_gun_tm(gunTm, human_net_phys, transform, 0.)

    let anchorOffset = -(inverse(transform) * gunTm * gun__bipodOffset)
    let anchorAngles = dir_to_angles(bipod__anchorDir)
    let anchorYaw = norm_ang(anchorAngles.x)
    let step = deg_to_rad(2.)

    var bodyFromToPointsMin = BodyFromToPointsInfo()

    var minYaw = 0.
    while minYaw > -TWOPI
      let curYaw = anchorYaw + minYaw
      calc_body_points(norm_ang(curYaw - step), norm_ang(curYaw), anchorOffset, bipod__anchorPos, bipod__anchorNormal, human_net_phys, bodyFromToPointsMin)
      if is_safe_angle(human_net_phys.phys.currentState.isCrawl, bodyFromToPointsMin)
        minYaw -= step
      else
        break

    body_points.headMin = bodyFromToPointsMin.headFrom
    body_points.bodyMin = bodyFromToPointsMin.bodyFrom
    body_points.legsMin = bodyFromToPointsMin.legsFrom

    var bodyFromToPointsMax = BodyFromToPointsInfo()

    var maxYaw = 0.
    while maxYaw < TWOPI
      let curYaw = anchorYaw + maxYaw
      calc_body_points(norm_ang(curYaw + step), norm_ang(curYaw), anchorOffset, bipod__anchorPos, bipod__anchorNormal, human_net_phys, bodyFromToPointsMax)
      if is_safe_angle(human_net_phys.phys.currentState.isCrawl, bodyFromToPointsMax)
        maxYaw += step
      else
        break

    body_points.headMax = bodyFromToPointsMax.headFrom
    body_points.bodyMax = bodyFromToPointsMax.bodyFrom
    body_points.legsMax = bodyFromToPointsMax.legsFrom

    let minDYaw = PI * 0.12
    if minYaw > -minDYaw
      minYaw = -minDYaw
    if maxYaw < minDYaw
      maxYaw = minDYaw

    bipod__yawLimit.x = clamp(minYaw, -TWOPI, 0.)
    bipod__yawLimit.y = clamp(maxYaw, 0., TWOPI)

  return body_points