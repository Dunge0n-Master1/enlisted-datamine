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


def get_anim_node_offset(animchar; nodeId) : float3
  var rootTm : float3x4
  var nodeTm : float3x4
  geomtree_getNodeWtmScalar(*animchar.nodeTree, 0, rootTm)
  geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, nodeTm)
  swap_xz(rootTm)
  swap_xz(nodeTm)
  let relTm = inverse(rootTm) * nodeTm
  return relTm[3]

[es(tag=server, on_appear)]
def bipod_init_offset(evt : Event;
                      animchar : AnimcharBaseComponent;
                      gun__bipodNode : string;
                      gun__barrelTipNode : string;
                      var gun__bipodOffset : float3&;
                      var gun__barrelTipOffset : float3&;
                      gun__barrelTipOffsetOverride : float3 = float3(0.0, 0.0, 0.0))
  let bipodNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gun__bipodNode)
  if bipodNodeId >= 0
    gun__bipodOffset = get_anim_node_offset(animchar, bipodNodeId)

  let barrelTipNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gun__barrelTipNode)
  if barrelTipNodeId >= 0
    gun__barrelTipOffset = get_anim_node_offset(animchar, barrelTipNodeId)

  if gun__barrelTipOffsetOverride.x != 0.0
    gun__barrelTipOffset = gun__barrelTipOffsetOverride


def bipod_update_height(var human_net_phys : HumanActor&; is_fpv : bool;
                        human_tm : float3x4; human_gun_eid : EntityId; bipod_is_crawl : bool; aim_pitch : float;
                        bipod_anchor_pos : float3; bipod_anchor_height : float; bipod_anchor_offset : float3;
                        var bipod_height_reacher : float&; var bipod_crawl_gun_offset : float3&; var bipod_pitch_limit : float2&)
  let anchorPos = bipod_anchor_pos + float3(0.0, bipod_anchor_height, 0.0)
  let sinPitch = sin(aim_pitch)

  var height = 0.0
  if bipod_is_crawl
    height = -1.0
  else
    let stick = bipod_anchor_offset.x
    let baseY = anchorPos.y - bipod_anchor_offset.y
    let findY = baseY - stick * sinPitch - (1.0 - cos(aim_pitch)) * bipod_anchor_height * 0.5

    let gun1 = is_fpv ? calc_fpv_gun_pos_for_height(human_net_phys, human_tm, aim_pitch, 1.0) : calc_tpv_gun_pos_for_height(human_net_phys, human_tm, aim_pitch, 1.0)
    let gun2 = is_fpv ? calc_fpv_gun_pos_for_height(human_net_phys, human_tm, aim_pitch, 0.0) : calc_tpv_gun_pos_for_height(human_net_phys, human_tm, aim_pitch, 0.0)

    height = cvt(findY, gun1.y, gun2.y, 1.0, 0.0)

    if bipod_anchor_offset.x > 0.0
      let upH = max(gun1.y - baseY, 0.0)
      let dnH = max(baseY - gun2.y, 0.0)
      bipod_pitch_limit.x = clamp(rad_to_deg(atan2(-upH, stick)), BIPOD_DEFAULT_PITCH_MIN, BIPOD_DEFAULT_PITCH_MAX)
      bipod_pitch_limit.y = clamp(rad_to_deg(atan2(dnH, stick)), BIPOD_DEFAULT_PITCH_MIN, BIPOD_DEFAULT_PITCH_MAX)
    else
      bipod_pitch_limit.x = 0.0
      bipod_pitch_limit.y = 0.0

  var animGunTm : float3x4
  bipod_crawl_gun_offset = float3(0.0)
  if get_gun_tm(human_gun_eid, animGunTm)
    let thatPt = animGunTm * bipod_anchor_offset
    var diffY = (anchorPos.y + 0.015 - abs(sinPitch) * 0.02) - thatPt.y
    diffY = clamp(diffY, BIPOD_MIN_GUN_Y_OFFSET, BIPOD_MAX_GUN_Y_OFFSET)
    bipod_crawl_gun_offset.y += diffY + bipod_height_reacher
    if diffY > 0.001
      bipod_height_reacher += diffY * 0.9
    elif diffY < -0.001
      bipod_height_reacher += diffY * 0.9

  bipod_crawl_gun_offset.y = clamp(bipod_crawl_gun_offset.y, BIPOD_MIN_GUN_Y_OFFSET, BIPOD_MAX_GUN_Y_OFFSET)
  bipod_height_reacher = clamp(bipod_height_reacher, BIPOD_MIN_GUN_Y_OFFSET, BIPOD_MAX_GUN_Y_OFFSET)

  human_net_phys.phys.currentState.height = height


[es(tag=netClient, REQUIRE_NOT=hero, after=human_phys_es, before=after_net_phys_sync)]
def bipod_other_human_act_es(info : UpdateStageInfoAct;
                             human_weap__currentGunEid : EntityId;
                             bipod__anchorPos : float3;
                             bipod__anchorHeight : float;
                             bipod__anchorOffset : float3;
                             bipod__isCrawl : bool;
                             bipod__enabled : bool;
                             var bipod__crawlGunOffset : float3&;
                             var bipod__heightReacher : float&;
                             var human_net_phys : HumanActor&)
  if !bipod__enabled
    return

  var humanTm : float3x4
  location_toTM(human_net_phys.phys.previousState.location, humanTm)

  let aimAngle = dir_to_angles(human_net_phys.phys.appliedCT.wishShootDir)

  var tmpPitchLimit : float2
  bipod_update_height(human_net_phys, false,
                      humanTm, human_weap__currentGunEid, bipod__isCrawl, aimAngle.y,
                      bipod__anchorPos, bipod__anchorHeight, bipod__anchorOffset,
                      bipod__heightReacher, bipod__crawlGunOffset, tmpPitchLimit)


let
  BIPOD_MAX_AWAY_DIST       = 0.20
  BIPOD_MAX_AWAY_DIST_OFF   = 1.00
  BIPOD_MAX_AWAY_DIST_OFF_Y = 0.50

  BIPOD_MAX_AWAY_DIST_SQ     = square(BIPOD_MAX_AWAY_DIST)
  BIPOD_MAX_AWAY_DIST_OFF_SQ = square(BIPOD_MAX_AWAY_DIST_OFF)

[es(after=human_phys_es, before=after_net_phys_sync)]
def bipod_human_act_es(evt : CmdPostPhysUpdate;
                       human_weap__currentGunEid : EntityId;
                       bipod__anchorPos : float3;
                       bipod__anchorDir : float3;
                       bipod__anchorHeight : float;
                       bipod__anchorOffset : float3;
                       bipod__anchorNormal : float3;
                       bipod__isCrawl : bool;
                       var bipod__enabled : bool&;
                       var bipod__pitchLimit : float2&;
                       var bipod__validateTimer : float&;
                       var bipod__prevCcdPos : float3&;
                       var bipod__lastValidPos : float3&;
                       var bipod__lastValidDir : float3&;
                       var bipod__isValidPos : bool&;
                       var bipod__crawlGunOffset : float3&;
                       var bipod__heightReacher : float&;
                       var human_net_phys : HumanActor&)
  if !bipod__enabled
    return

  if (human_net_phys.phys.currentState.moveState == HUMoveState EMS_WALK ||
      human_net_phys.phys.currentState.moveState == HUMoveState EMS_SPRINT)
    bipod__enabled = false
    return

  let anchorPos = bipod__anchorPos + float3(0.0, bipod__anchorHeight, 0.0)

  var humanTm, humanItm : float3x4
  location_toTM(human_net_phys.phys.previousState.location, humanTm)
  humanItm = inverse(humanTm)

  let shootDir = human_net_phys.phys.appliedCT.wishShootDir
  let aimAngle = dir_to_angles(shootDir)

  var gunTm : float3x4
  calc_gun_tm(gunTm, human_net_phys, humanTm, aimAngle.y)

  let mountPointPos = gunTm * bipod__anchorOffset

  bipod__isValidPos = true
  if human_net_phys.phys.currentState.aimPosition >= 1.0 && !(bipod__isCrawl && human_net_phys.phys.previousState.height > -1.0)
    bipod__validateTimer -= evt.dt
    if bipod__validateTimer <= 0.0
      let awayOffset = anchorPos - mountPointPos
      if length_sq(awayOffset) > BIPOD_MAX_AWAY_DIST_SQ
        bipod__isValidPos = bipod__isCrawl
        human_net_phys.phys.currentState.location.P.x = double(bipod__lastValidPos.x)
        human_net_phys.phys.currentState.location.P.z = double(bipod__lastValidPos.z)
        if length_sq(awayOffset) > BIPOD_MAX_AWAY_DIST_OFF_SQ || abs(awayOffset.y) > BIPOD_MAX_AWAY_DIST_OFF_Y
          bipod__enabled = false
          return
        else
          bipod__validateTimer = 0.0
      else
        bipod__validateTimer = 0.0

  let offset = -(humanItm * mountPointPos)

  let wasPos = float3(human_net_phys.phys.currentState.location.P)
  var wishPos = calc_human_pos(aimAngle.x, anchorPos, offset, bipod__anchorNormal)
  wishPos.y = wasPos.y

  let offDist = sin(aimAngle.y) * bipod__anchorHeight
  wishPos.x -= bipod__anchorDir.x * offDist
  wishPos.z -= bipod__anchorDir.z * offDist

  human_net_phys.phys.currentState.location.P.x = double(wishPos.x)
  human_net_phys.phys.currentState.location.P.z = double(wishPos.z)
  human_net_phys.phys.currentState.velocity = float3(0.f)
  human_net_phys.phys.currentState.breathOffset = float2(0.f)
  human_net_phys.phys.currentState.moveState = HUMoveState EMS_STAND

  bipod_update_height(human_net_phys, true,
                      humanTm, human_weap__currentGunEid, bipod__isCrawl, aimAngle.y,
                      bipod__anchorPos, bipod__anchorHeight, bipod__anchorOffset,
                      bipod__heightReacher, bipod__crawlGunOffset, bipod__pitchLimit)

  var ccdTm : float3x4
  let ccdPos = human_net_phys.phys.ccdPos
  location_toTM(human_net_phys.phys.currentState.location, ccdTm)
  var ccdNewPos = ccdTm * ccdPos

  var bodyDir = anchorPos - wishPos
  bodyDir.y = 0.0
  bodyDir = normalize(bodyDir)
  human_net_phys.phys.currentState.bodyOrientDir = float2(bodyDir.x, bodyDir.z)

  if distance_sq(ccdNewPos, bipod__prevCcdPos) > square(0.01)
    let collRad = human_net_phys.phys.collRad
    let ccdRad  = human_net_phys.phys.ccdRad
    let speedCollisionHardness = human_net_phys.phys.speedCollisionHardness
    let totalOffset = ccdNewPos - bipod__prevCcdPos

    // NOTE: should be available both on client and server, do not use human_cam__calculatedOffset, it's client only
    let fpvCorrectionOffset = ccdTm[2] * -0.15 + ccdTm[0] * 0.2

    ccdNewPos += fpvCorrectionOffset
    human_net_phys.phys.currentState.location.P.x += double(fpvCorrectionOffset.x)
    human_net_phys.phys.currentState.location.P.z += double(fpvCorrectionOffset.z)

    let wasY = double(human_net_phys.phys.currentState.location.P.y)
    if human_net_phys.phys |> human_phys_processCcdOffset(ccdTm, ccdNewPos, totalOffset, collRad - ccdRad, speedCollisionHardness, false, ccdPos)
      human_net_phys.phys.currentState.location.P = DPoint3(bipod__isValidPos ? bipod__lastValidPos : wasPos)
    else
      human_net_phys.phys.currentState.location.P.x -= double(fpvCorrectionOffset.x)
      human_net_phys.phys.currentState.location.P.z -= double(fpvCorrectionOffset.z)
    human_net_phys.phys.currentState.location.P.y = wasY

    location_toTM(human_net_phys.phys.currentState.location, ccdTm)
    bipod__prevCcdPos = ccdTm * ccdPos

  if bipod__isValidPos
    bipod__lastValidPos = float3(human_net_phys.phys.currentState.location.P)
    bipod__lastValidDir = shootDir

[es(tag=server)]
def human_place_bipod_server_es(evt : RequestBipodPlacing;
                                human_net_phys : HumanActor;
                                var bipod__enabled : bool&;
                                var bipod__isCrawl : bool&;
                                var bipod__anchorPos : float3&;
                                var bipod__anchorDir : float3&;
                                var bipod__anchorHeight : float&;
                                var bipod__anchorOffset : float3&;
                                var bipod__anchorNormal : float3&;
                                var bipod__anchorYawLimit : float2&;
                                var bipod__recoilMult : float&;
                                var bipod__pitchLimit : float2&;
                                var bipod__validateTimer : float&;
                                var bipod__prevCcdPos : float3&;
                                var bipod__lastValidPos : float3&;
                                var bipod__lastValidDir : float3&;
                                var bipod__isValidPos : bool&)
  bipod__enabled        = evt.enabled
  bipod__isCrawl        = evt.isCrawl
  bipod__anchorPos      = evt.anchorPos
  bipod__anchorDir      = evt.anchorDir
  bipod__anchorHeight   = evt.anchorHeight
  bipod__anchorOffset   = evt.anchorOffset
  bipod__anchorNormal   = evt.anchorNormal
  bipod__anchorYawLimit = evt.anchorYawLimit
  bipod__recoilMult     = clamp(evt.recoilMult, 0.0, 1.0)

  if bipod__enabled
    bipod__pitchLimit     = float2(BIPOD_DEFAULT_PITCH_MIN, BIPOD_DEFAULT_PITCH_MAX)
    bipod__validateTimer  = BIPOD_WAIT_BEFORE_VALIDATE

    bipod__prevCcdPos = get_human_ccd_pos(human_net_phys)

    bipod__lastValidPos = float3(human_net_phys.phys.currentState.location.P)
    bipod__lastValidDir = human_net_phys.phys.appliedCT.wishShootDir
    bipod__isValidPos = true


def trace_bipod_attached_ri(pos)
  var riDesc = RendInstDesc()
  var norm : float3
  var matId = PHYSMAT_INVALID
  let traceDir = float3(0, -1, 0) // trace down
  var minHeight = 1.0
  let res = traceray_normalized(pos, traceDir, minHeight, matId, norm, ETF_RI, riDesc, -1)
  if res && riDesc.isValid
    return int(riDesc.riExtraHandle)
  return -1

[es(tag=server)]
def human_bipod_deattached_from_ri_es(evt : EventRendinstDestroyed; var bipod__attachedToRi : int&;
                                      var bipod__enabled : bool&)
  if bipod__enabled && int(evt.riexHandle) == bipod__attachedToRi
    bipod__enabled = false
    bipod__attachedToRi = -1

[es(tag=server, track=bipod__enabled)]
def human_bipod_attached_to_ri_es(evt : Event; bipod__enabled : bool; bipod__placePos : float3; var bipod__attachedToRi : int&)
  if !bipod__enabled
    bipod__attachedToRi = -1
    return

  bipod__attachedToRi = trace_bipod_attached_ri(bipod__placePos)
