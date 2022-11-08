require ecs
require DagorShaders
require DagorMath

let
  redout_blackout_colorVarId = get_shader_variable_id("redout_blackout_color", true)

[es(tag=gameClient, REQUIRE=hero, no_order)]
def redeploy_blackout_effect(info : UpdateStageInfoAct;
                             redeploy__atTime : float;
                             redeploy__delay : float)
  if redeploy__atTime > 0.0
    let progress = cvt(info.curTime, redeploy__atTime - redeploy__delay, redeploy__atTime, 0.0, 1.0)
    DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.0, 0.0, 0.0, progress)))


[es(tag=gameClient, REQUIRE=hero, track=redeploy__atTime)]
def redeploy_remove_blackout_effect(evt : Event;
                                    redeploy__atTime : float)
  if redeploy__atTime < 0.0
    DagorShaders::set_color4(redout_blackout_colorVarId, Color4(float4(0.0, 0.0, 0.0, 0.0)))
