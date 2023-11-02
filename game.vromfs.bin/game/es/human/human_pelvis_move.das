require ecs
require PhysVars
require DngHuman
require math
require math.base
require math.ang
require DagorSystem
require DagorMath
require enlisted.events_enlisted


[es(tag=gameClient, on_appear)]
def human_pelvis_move_init_phys_vars(evt : Event;
                                     var human_anim__pelvisMoveEnabledId : int&;
                                     var human_anim__pelvisMoveOffsetId : int&;
                                     var human_anim__pelvisMoveOffsetCourseId : int&;
                                     var phys_vars : PhysVars&)
  human_anim__pelvisMoveEnabledId = phys_vars |> registerPullVar("pelvis_move_enabled", 0.0f)
  human_anim__pelvisMoveOffsetId = phys_vars |> registerVar("pelvis_move_offset", 0.0f)
  human_anim__pelvisMoveOffsetCourseId = phys_vars |> registerVar("pelvis_move_course", 0.0f)

// human root node is bip01 (pelvis) and soldier animchar is placed by this node to actual soldier transform
// because of this we cant animate pelvis movement through animations in any way
// but this looks quite bad.
// we could have a different root node for soldier to have an ability to animate the pelvis itself but that
// would require to edit most of existing animations and soldier skeleton
//
// as a workaround we have this system: we procedurally move soldiers transform around by some offset and
// move legs back by this offset in animtree. This way we can simulate soldier pelvis movement and legs stay in place
[es(tag=gameClient, after=after_net_phys_sync, before=(before_animchar_update_sync, slot_attach_init_tms_es), REQUIRE_NOT=deadEntity)]
def human_pelvis_move_compensation(info : ParallelUpdateFrameDelayed;
                                   human_anim__pelvisMoveEnabledId : int;
                                   human_anim__pelvisMoveOffsetId : int&;
                                   human_anim__pelvisMoveOffsetCourseId : int&;
                                   human_anim__pelvisMoveGunPitchCompensation : float2; // sitting , standing
                                   human_anim__pelvisMoveLeanCompensation : float2; // sitting , standing
                                   isTpsView : bool = false;
                                   hero : Tag const?;
                                   human_net_phys : HumanActor;
                                   var transform : float3x4;
                                   var phys_vars : PhysVars&)
  // only some anim statse have legs pelvis compensation enabled
  // animtree sets pelvis_move_enabled param to 1 if it is
  // no reason to change transform in other cases
  let isPelvisMoveEnabled = phys_vars |> getVar(human_anim__pelvisMoveEnabledId) > 0.5
  let isTpsViewOnSoldier = hero == null || isTpsView
  if !isTpsViewOnSoldier || !isPelvisMoveEnabled
    phys_vars |> setVar(human_anim__pelvisMoveOffsetId, 0.0)
    return

  assume phys = human_net_phys.phys
  assume curState = phys.currentState
  assume prevState = phys.previousState

  let gunDir = curState.gunDir
  let horizontalGunDir = normalize(float3(gunDir.x, 0.0, gunDir.z))
  let horizontalSideGunDir = normalize(float3(gunDir.z, 0.0, -gunDir.x))
  let verticalGunDir = gunDir.y

  let interpK = get_phys_interpk_clamped(phys, info.curTime)
  let standHeight = lerp(prevState.height, curState.height, interpK)
  let lean = lerp(prevState.leanPosition, curState.leanPosition, interpK) / phys.leanDegrees

  let gunPitchOffset = -verticalGunDir * horizontalGunDir * lerp(
    human_anim__pelvisMoveGunPitchCompensation.x, human_anim__pelvisMoveGunPitchCompensation.y, standHeight)

  let leanOffset = horizontalSideGunDir * lean * lerp(
    human_anim__pelvisMoveLeanCompensation.x, human_anim__pelvisMoveLeanCompensation.y, standHeight)

  let horizontalOffset = gunPitchOffset + leanOffset
  // moving transform on a plane will make legs stretch, so we move transform down a bit
  // ideally we can calcualte this offset as if we are moving on a sphere with the center down at the humans legs
  // but for small enough offsets this will do fine
  let verticalOffsetPower = 0.03
  let offset = horizontalOffset + float3(0.0, length(horizontalOffset) * verticalOffsetPower, 0.0)

  transform[3] -= offset

  // nodes are moved in character space
  let forward = float3(1.0, 0.0, 0.0)
  let up = float3(0.0, 1.0, 0.0)
  // signed angle between two vectors in degrees
  let offsetCourse = rad_to_deg(safe_atan2(dot(cross(horizontalOffset, forward), up), dot(forward, horizontalOffset)))

  if is_nan(offsetCourse) || !is_finite(offsetCourse)
    debug("gunDir {gunDir}, gunPitchOffset {gunPitchOffset}, lean {lean}, leanOffset {leanOffset}, standHeight {standHeight}")
    logerr("nan in offsetCourse {offsetCourse} see log for more info")
    return
  phys_vars |> setVar(human_anim__pelvisMoveOffsetCourseId, offsetCourse)
  phys_vars |> setVar(human_anim__pelvisMoveOffsetId, length(horizontalOffset))

