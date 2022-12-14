require ecs
require DagorMath
require math.base
require game.utils.hero
require DagorShaders
require Dacoll
require DagorMathUtils
require EnlistedCamera
require enlisted.events_enlisted

let probes_outdoor_factorVarId = get_shader_variable_id("probes_outdoor_factor", true)


[es(tag=render, after=shooter_cam_update_tm_es)]
def outdoor_factor_tracer(info : ParallelUpdateFrameDelayed;
                          outdoor_factor__export : bool;
                          var outdoor_factor__currentTrace : int&;
                          var outdoor_factor__outdoorMultiplier : float&)
  if !outdoor_factor__export
    return
  query(get_cur_cam_entity()) <| $ [es] (transform : float3x4; camera__posOnlyBaseOffset : DPoint3 const?)
    let traceStart = float3(0f, 0.5f, 0f) + (camera__posOnlyBaseOffset != null ? float3(*camera__posOnlyBaseOffset) : transform[3])
    let SAMPLES_COUNT = 1000
    let u = frac(float(outdoor_factor__currentTrace) / float(SAMPLES_COUNT))
    let v = float(reverse_bits32(uint(outdoor_factor__currentTrace))) * 2.3283064365386963e-10f
    let theta = acos(1f - u) * 0.5f + PI * 0.25f
    let phi = PI * 2f * v
    let direction = float3(cos(phi) * cos(theta), sin(theta), sin(phi) * cos(theta))
    let t = 5f
    let dir = rayhit_normalized(traceStart, direction, t, ETF_DEFAULT, -1) ? -1.5f : 0.5f
    outdoor_factor__outdoorMultiplier = clamp(outdoor_factor__outdoorMultiplier + dir * info.dt / 4f, 0f, 1f)
    outdoor_factor__currentTrace = (outdoor_factor__currentTrace + 1) % SAMPLES_COUNT

[es(tag=render, after=shooter_cam_update_tm_es)]
def outdoor_factor_tracer_applyer(info : UpdateStageInfoAct;
                                  outdoor_factor__export : bool;
                                  outdoor_factor__outdoorMultiplier : float;
                                  outdoor_factor__forcedOutdoorFactor = -1f)
  if outdoor_factor__export
    DagorShaders::set_real(probes_outdoor_factorVarId, outdoor_factor__forcedOutdoorFactor < 0f ?
      outdoor_factor__outdoorMultiplier : outdoor_factor__forcedOutdoorFactor)


[es(tag=render, track=outdoor_factor__export)]
def reset_probes_outdoor_factor_var(evt : Event; outdoor_factor__export : bool)
  if !outdoor_factor__export
    DagorShaders::set_real(probes_outdoor_factorVarId, 1f)