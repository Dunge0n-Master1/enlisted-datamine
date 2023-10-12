require ecs
require DngHuman
require HumanPhys
require DagorMath
require math.base
require AnimV20
require GeomNodeTree
require DagorSystem
require enlisted.events_enlisted

[es(tag=render, before=cockpit_camera_offseter, after=after_net_phys_sync, REQUIRE=watchedByPlr)]
def human_fpv_cam_lookat(info : ParallelUpdateFrameDelayed; transform : float3x4; human_net_phys : HumanActor;
                         human_cam__standPos : float3; human_cam__crouchPos : float3; human_cam__crawlPos : float3;
                         var camera__look_at : DPoint3;
                         human_cam__leftLeanOffs : float3;
                         human_cam__rightLeanOffs : float3;
                         human_cam__lookDownOffs : float3;
                         human_cam__lookUpOffs : float3;
                         human_cam__crawlLookDownOffs : float3;
                         human_cam__crawlLookUpOffs : float3;
                         human_anim__previousHeight : float;
                         var human_cam__fpvActive : bool&;
                         var human_cam__offsetMult : float&;
                         isInVehicle : bool = false;
                         bipod__enabled : bool = false;
                         human_ladder__attached : bool = false)
  assume phys = human_net_phys.phys
  // Height calculation
  assume curSt = phys.currentState
  assume prevSt = phys.previousState

  human_cam__fpvActive = !human_phys_state_get_isAttached(curSt) && curSt.standState != HUStandState ESS_DOWNED && !human_ladder__attached && !isInVehicle && !bipod__enabled
  let wishOffsetMult = human_cam__fpvActive ? 1.0 : 0.0
  human_cam__offsetMult = move_to_scalar(human_cam__offsetMult, wishOffsetMult, info.dt, bipod__enabled ? 5.0 : 2.0)
  if human_cam__offsetMult <= 0.0
    return

  let interpK = get_phys_interpk_clamped(phys, info.curTime)
  let height = human_anim__previousHeight

  let crawlHeight = float3(height + 1.0)

  let htOffs = (height >= 1.0
      ? human_cam__standPos
      : (height >= 0.0
          ? lerp(human_cam__crouchPos, human_cam__standPos, float3(height))
          : lerp(human_cam__crawlPos, human_cam__crouchPos, crawlHeight)))

  // Lean calculation
  let lean = lerp(prevSt.leanPosition, curSt.leanPosition, interpK)
  let leanOffs = (lean == 0.
      ? float3()
      : (lean < 0.0 ? human_cam__leftLeanOffs : human_cam__rightLeanOffs) * abs(lean / phys.leanDegrees))

  let upOffs = height > 0.0 ? human_cam__lookUpOffs : lerp(human_cam__crawlLookUpOffs, human_cam__lookUpOffs, crawlHeight)
  let downOffs = height > 0.0 ? human_cam__lookDownOffs : lerp(human_cam__crawlLookDownOffs, human_cam__lookDownOffs, crawlHeight)

  // Apply vertical offset from gun angles
  let angle = lerp(prevSt.gunAngles.y, curSt.gunAngles.y, interpK)
  let gunAngleOffs = (angle >= 0.0
      ? upOffs * cvt(angle, 0.0, HALF_PI, 0.0, 1.0)
      : downOffs * cvt(angle, 0.0, -HALF_PI, 0.0, 1.0))

  // Apply offset (for swimming)
  let posOffs = lerp(prevSt.posOffset, curSt.posOffset, float3(interpK))

  // use local rotation (without translation) to improve accuracy
  let rotatedVector = rotate(transform, htOffs + leanOffs + gunAngleOffs - posOffs)
  camera__look_at = DPoint3(transform[3]) + DPoint3(rotatedVector)

[es(tag=render, after=camera_set_sync, before=before_camera_sync, REQUIRE=watchedByPlr)]
def human_fpv_cam_pos(info : UpdateStageInfoAct; animchar : AnimcharBaseComponent; human_cam__camNodeId : int; var camera__look_at : DPoint3&;
                      human_cam__offsetMult : float)
  if human_cam__camNodeId < 0
    return
  let wposRel = geomtree_getNodeWposRel(*animchar.nodeTree, human_cam__camNodeId)
  let wofs = geomtree_getWtmOfs(*animchar.nodeTree)
  camera__look_at = lerp(DPoint3(wposRel) + DPoint3(wofs), camera__look_at, human_cam__offsetMult)

[es(tag=render, on_appear)]
def cockpit_camera_init(evt : Event; animchar : AnimcharBaseComponent; human_cam__camNodeName : string; var human_cam__camNodeId : int&)
  human_cam__camNodeId = geomtree_findNodeIndex(*animchar.nodeTree, human_cam__camNodeName)

[es(tag=render, before=(animchar_es, human_anim_es), after=human_fpv_cam_lookat, REQUIRE=watchedByPlr, REQUIRE_NOT=deadEntity)]
def cockpit_pre_animchar_offset(info : ParallelUpdateFrameDelayed; var transform : float3x4; human_cam__calculatedOffset : DPoint3; human_cam__offsetMult : float)
  transform[3] = transform[3] + float3(human_cam__calculatedOffset * human_cam__offsetMult)

[es(tag=render, after=animchar_es, before=(post_animchar_sync, gun_flash_fx_es))]
def cockpit_camera_offseter(info : ParallelUpdateFrameDelayed; camera__active : bool; camera__target : EntityId; isHeroCockpitCam : bool)
  if !camera__active
    return
  query(camera__target) <| $ [es(REQUIRE_NOT=deadEntity)] (var animchar : AnimcharBaseComponent;
                                                           var animchar_node_wtm : AnimcharNodesMat44&;
                                                           var animchar_render__root_pos : vec4f&;
                                                           camera__look_at : DPoint3;
                                                           human_cam__camNodeId : int;
                                                           var human_cam__calculatedOffset : DPoint3;
                                                           human_cam__offsetMult : float)
    if human_cam__offsetMult <= 0.0 || human_cam__camNodeId < 0 || !isHeroCockpitCam
      human_cam__calculatedOffset = DPoint3(0.0lf, 0.0lf, 0.0lf)
      return
    let wposRel = geomtree_getNodeWposRel(*animchar.nodeTree, human_cam__camNodeId)
    let originRel = geomtree_getNodeWposRel(*animchar.nodeTree, 0)
    let wofs = geomtree_getWtmOfs(*animchar.nodeTree)
    let localPos = camera__look_at - DPoint3(wofs)
    let additionalOffset = localPos - DPoint3(wposRel)
    // adjust animchar to local position to calculate most precise location
    human_cam__calculatedOffset = human_cam__calculatedOffset + additionalOffset * human_cam__offsetMult
    let rootPos = float3(DPoint3(wofs) + DPoint3(originRel) + additionalOffset * human_cam__offsetMult)
    geomtree_changeRootPos(*animchar.nodeTree, rootPos, true) // last argument MUST be true (it setups wofs), otherwise precision will be lost
    geomtree_invalidateWtm(*animchar.nodeTree)
    animchar_recalc_wtm(animchar)
    animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

