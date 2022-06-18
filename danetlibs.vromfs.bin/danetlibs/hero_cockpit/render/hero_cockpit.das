require ecs
require DagorMath
require Dacoll
require DagorShaders
require app
require game.utils.hero
require EnlistedWeapon

let
  hero_cockpit_vecVarId = DagorShaders::get_shader_variable_id("hero_cockpit_vec", false)

[es(tag=render, no_order)]
def set_hero_cockpit_params(info : UpdateStageInfoBeforeRender)
  var shootTm : float3x4
  if human_weap_get_shoot_tm(get_controlled_hero(), get_sync_time(), shootTm)
    let traceDir = shootTm[0]
    let MAX_DISTANCE = 1.5
    let START_BIAS = 0.5 // center of gun can be inside occlusion, when we stand up to wall
    let tracePos = shootTm[3] - START_BIAS * traceDir
    var t : float = START_BIAS + MAX_DISTANCE
    var norm = float3()

    if traceray_normalized(tracePos, traceDir, t, norm, ETF_DEFAULT | ETF_RI_TREES)
      let intersectionPos = tracePos + t * traceDir
      let FADE_DISTANCE = 0.7
      let normalizedDir = traceDir / FADE_DISTANCE
      let vec = float4(normalizedDir, -dot(normalizedDir, intersectionPos) + 1.0)
      DagorShaders::set_color4(hero_cockpit_vecVarId, Color4(vec))
      return

  DagorShaders::set_color4(hero_cockpit_vecVarId, Color4(float4(0.0, 0.0, 0.0, 0.0)))