require ecs
require DagorMath
require Dacoll
require DagorShaders
require app
require EnlistedWeapon
require EnlistedHuman
require Gun
require math.base
require EnlistedCamera
require player

//may be move this event to daNetGameLibs. Not enlisted only
[cpp_event(broadcast)]
struct ParallelUpdateFrameDelayed
  curTime : float
  dt : float

let
  GUN_MAX_LENGTH = 1.5 // From gun center to farest visible point of gun model
  TRACE_MAX_BIAS = 1.5 // From gun center to sample point
  START_FADE_BEFORE_INTERSECTION = 0.3
  FADE_INTERVAL = 0.5
  SAMPLE_OFFSET_ABOVE_CAMERA = 0.25
  SAMPLE_BIAS = 0.25

def get_hero_cockpit_vec_impl(var hero_cockpit_vec_value : float4&;
                              var hero_cockpit_camera_to_point_value : float4&)
  let heroEid = get_Eid(get_local_player_eid(), "possessed") ?? INVALID_ENTITY_ID
  if !heroEid
    return false

  var shootTm : float3x4
  var shootTm1 : mat44f
  var wofs : vec4f
  var bbox : bbox3f
  if !get_current_human_gun_bbox(heroEid, shootTm1, wofs, bbox)
    return false

  var humanTraceHandle : TraceMeshFaces?
  var isAiming, inVehicle : bool
  query(heroEid) <| $ [es] (human_net_phys : HumanActor;
                            human_net_phys__isAiming : bool;
                            isInVehicle : bool)
    humanTraceHandle = human_net_phys.phys.traceHandle
    isAiming = human_net_phys__isAiming
    inVehicle = isInVehicle

  if inVehicle
    return false

  shootTm[0] = -shootTm1.col2.xyz
  shootTm[1] = shootTm1.col1.xyz
  shootTm[2] = shootTm1.col0.xyz
  shootTm[3] = shootTm1.col3.xyz + wofs.xyz

  let back = shootTm * float3(0, 0, -1)
  let front = shootTm * float3(0, 0, 1)
  let sampleDir = -normalize(front - back).zx * SAMPLE_BIAS
  let cameraTracePos = float4(sampleDir.x, SAMPLE_OFFSET_ABOVE_CAMERA, sampleDir.y, 0.0)
  hero_cockpit_camera_to_point_value = cameraTracePos

  let traceDir = shootTm[0]
  let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
  let startBias = clamp(dot(shootTm[3] - cameraTm[3], traceDir), -TRACE_MAX_BIAS, TRACE_MAX_BIAS)
  let tracePos = shootTm[3] - startBias * traceDir
  var t : float = startBias + GUN_MAX_LENGTH
  var norm = float3()
  var pmid : int
  var riDesc = RendInstDesc()

  var startFadeDistance = 1000.0
  var applyFade = false
  if traceray_normalized(tracePos, traceDir, t, pmid, norm, ETF_DEFAULT | ETF_RI_TREES, riDesc, -1, humanTraceHandle)
    applyFade = true
    startFadeDistance = t - START_FADE_BEFORE_INTERSECTION

  if isAiming
    query(get_human_gun_eid(heroEid))  <| $ [es] (gun__distanceToDisableAOinAiming : float)
      if gun__distanceToDisableAOinAiming > 0.0
        applyFade = true
        startFadeDistance = min(startFadeDistance, gun__distanceToDisableAOinAiming + startBias)

  if !applyFade
    return false

  let startFadePos = tracePos + startFadeDistance * traceDir
  let normalizedDir = traceDir / FADE_INTERVAL
  hero_cockpit_vec_value = float4(normalizedDir, -dot(normalizedDir, startFadePos) + 1.0)
  return true

[es(tag=render)]
def get_hero_cockpit_params(event : ParallelUpdateFrameDelayed;
                            var hero_cockpit_vec_value : float4&;
                            var hero_cockpit_camera_to_point_value : float4&)
  if !get_hero_cockpit_vec_impl(hero_cockpit_vec_value, hero_cockpit_camera_to_point_value)
    hero_cockpit_vec_value = float4(0.0, 0.0, 0.0, 0.0)

[es(tag=render, no_order)]
def set_hero_cockpit_params(info : UpdateStageInfoBeforeRender;
                            hero_cockpit_vec : ShaderVar;
                            hero_cockpit_vec_value : float4;
                            hero_cockpit_camera_to_point : ShaderVar;
                            hero_cockpit_camera_to_point_value : float4)
  DagorShaders::set_color4(hero_cockpit_vec.varId, Color4(hero_cockpit_vec_value))
  DagorShaders::set_color4(hero_cockpit_camera_to_point.varId, Color4(hero_cockpit_camera_to_point_value))