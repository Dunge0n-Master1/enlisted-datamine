module smoke_occluders_common shared

require ecs
require app
require DagorSystem

def create_smoke_occluders_for_effect(transform : float3x4;
                                      fx_template_name : string)
  let fxTemplate = getTemplateByName(fx_template_name)
  if fxTemplate == null
    logerr("Template '{fx_template_name}' does not exist")
    return

  let effectSmokeOccludersTemplate = get_ecs_string(getTemplateComponent(*fxTemplate, "effect__smokeOccludersTemplate"))
  if effectSmokeOccludersTemplate == null
    return

  let effectWindEmitterDuration = get_float(getTemplateComponent(*fxTemplate, "wind_emitter__duration"))
  let effectGameEffectTimeToDestroy = get_float(getTemplateComponent(*fxTemplate, "game_effect__timeToDestroy"))

  let lifetime = effectWindEmitterDuration ?? effectGameEffectTimeToDestroy ?? -1.0
  if lifetime < 0.0
    logerr("trying to create a smoke occluders by smoke shell with invalid lifetime: {lifetime}. Perhaps, the effect has no the wind_emitter__duration nor game_effect__timeToDestroy")
    return

  peek(*effectSmokeOccludersTemplate) <| $(template_name)
    createEntity(template_name) <| $(var init)
      set(init, "transform", transform)
      set(init, "smoke_occluders__destroyAtTime", get_sync_time() + lifetime)
