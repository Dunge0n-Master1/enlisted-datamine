require ecs
require DagorMath
require Dacoll
require DagorShaders
require app
require game.utils.hero
require EnlistedWeapon
require EnlistedHuman

let
  hero_cockpit_vecVarId = DagorShaders::get_shader_variable_id("hero_cockpit_vec", false)
  hero_cockpit_camera_to_pointVarId = DagorShaders::get_shader_variable_id("hero_cockpit_camera_to_point", true)
  MAX_DISTANCE = 1.5 // From center to farest visible point of gun model
  START_FADE_BEFORE_INTERSECTION = 0.3
  FADE_INTERVAL = 0.5
  SAMPLE_OFFSET_ABOVE_CAMERA = 0.25
  SAMPLE_BIAS = 0.25

def set_default_hero_cockpit_vec()
  DagorShaders::set_color4(hero_cockpit_vecVarId, Color4(float4(0.0, 0.0, 0.0, 0.0)))

def set_hero_cockpit_vec_impl()
  let heroEid = get_controlled_hero()
  if heroEid == INVALID_ENTITY_ID
    return false

  let gun = get_human_gun(heroEid)
  if gun == null
    return false

  let curTime = get_sync_time()
  var shootTm : float3x4
  var haveShootTm = false
  query(heroEid) <| $ [es] (human_net_phys : HumanActor)
    human_gun_get_shoot_tm(*gun, human_net_phys.phys, curTime, shootTm)
    haveShootTm = true
  if !haveShootTm
    return false

  var viewTm : float3x4
  // TODO: use human_get_aim_tm_impl here, because we already have human_net_phys
  if !human_weap_get_aim_tm(heroEid, curTime, viewTm)
    return false
  let cameraPos = viewTm[3]
  let sampleDir = -normalize(viewTm[0].xz) * SAMPLE_BIAS
  let cameraTracePos = float4(sampleDir.x, SAMPLE_OFFSET_ABOVE_CAMERA, sampleDir.y, 0.0)
  DagorShaders::set_color4(hero_cockpit_camera_to_pointVarId, Color4(cameraTracePos))

  let traceDir = shootTm[0]
  let startBias = dot(shootTm[3] - cameraPos, traceDir)
  let tracePos = shootTm[3] - startBias * traceDir
  var t : float = startBias + MAX_DISTANCE
  var norm = float3()

  if !traceray_normalized(tracePos, traceDir, t, norm, ETF_DEFAULT | ETF_RI_TREES)
    return false

  let intersectionPos = tracePos + (t - START_FADE_BEFORE_INTERSECTION) * traceDir
  let normalizedDir = traceDir / FADE_INTERVAL
  let vec = float4(normalizedDir, -dot(normalizedDir, intersectionPos) + 1.0)
  DagorShaders::set_color4(hero_cockpit_vecVarId, Color4(vec))
  return true

[es(tag=render, no_order)]
def set_hero_cockpit_params(info : UpdateStageInfoBeforeRender)
  if !set_hero_cockpit_vec_impl()
    set_default_hero_cockpit_vec()
