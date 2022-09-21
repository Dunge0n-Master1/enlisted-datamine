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


let
  hero_cockpit_vecVarId = DagorShaders::get_shader_variable_id("hero_cockpit_vec", false)
  hero_cockpit_camera_to_pointVarId = DagorShaders::get_shader_variable_id("hero_cockpit_camera_to_point", false)
  MAX_DISTANCE = 1.5 // From center to farest visible point of gun model
  START_FADE_BEFORE_INTERSECTION = 0.3
  FADE_INTERVAL = 0.5
  SAMPLE_OFFSET_ABOVE_CAMERA = 0.25
  SAMPLE_BIAS = 0.25

def set_default_hero_cockpit_vec()
  DagorShaders::set_color4(hero_cockpit_vecVarId, Color4(float4(0.0, 0.0, 0.0, 0.0)))

def set_hero_cockpit_vec_impl()
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
  var isAiming : bool
  query(heroEid) <| $ [es] (human_net_phys : HumanActor;
                            human_net_phys__isAiming : bool)
    humanTraceHandle = human_net_phys.phys.traceHandle
    isAiming = human_net_phys__isAiming

  shootTm[0] = -shootTm1.col2.xyz
  shootTm[1] = shootTm1.col1.xyz
  shootTm[2] = shootTm1.col0.xyz
  shootTm[3] = shootTm1.col3.xyz + wofs.xyz

  let back = shootTm * float3(0, 0, -1)
  let front = shootTm * float3(0, 0, 1)
  let sampleDir = -normalize(front - back).zx * SAMPLE_BIAS
  let cameraTracePos = float4(sampleDir.x, SAMPLE_OFFSET_ABOVE_CAMERA, sampleDir.y, 0.0)
  DagorShaders::set_color4(hero_cockpit_camera_to_pointVarId, Color4(cameraTracePos))

  let traceDir = shootTm[0]
  let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
  let startBias = dot(shootTm[3] - cameraTm[3], traceDir)
  let tracePos = shootTm[3] - startBias * traceDir
  var t : float = startBias + MAX_DISTANCE
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
  let vec = float4(normalizedDir, -dot(normalizedDir, startFadePos) + 1.0)
  DagorShaders::set_color4(hero_cockpit_vecVarId, Color4(vec))
  return true

[es(tag=render, no_order)]
def set_hero_cockpit_params(info : UpdateStageInfoBeforeRender)
  if !set_hero_cockpit_vec_impl()
    set_default_hero_cockpit_vec()
