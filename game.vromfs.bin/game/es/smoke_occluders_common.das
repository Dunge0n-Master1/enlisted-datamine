module smoke_occluders_common shared

require ecs
require ecs.safe
require strings
require app
require DagorSystem

def create_smoke_occluders_for_effect(transform : float3x4;
                                      fx_template_name : string)
  let fxTemplate = getTemplateByName(fx_template_name)
  if fxTemplate == null
    logerr("Template '{fx_template_name}' does not exist")
    return

  let effectSmokeOccludersTemplate = getTemplateComponent(*fxTemplate, "effect__smokeOccludersTemplate") ?? ""
  if empty(effectSmokeOccludersTemplate)
    return

  let effectWindEmitterDuration = getTemplateComponent(*fxTemplate, "wind_emitter__duration") ?as float
  let effectGameEffectTimeToDestroy = getTemplateComponent(*fxTemplate, "game_effect__timeToDestroy") ?as float

  let lifetime = effectWindEmitterDuration ?? effectGameEffectTimeToDestroy ?? -1.0
  if lifetime < 0.0
    logerr("trying to create a smoke occluders by smoke shell with invalid lifetime: {lifetime}. Perhaps, the effect has no the wind_emitter__duration nor game_effect__timeToDestroy")
    return

  createEntity(effectSmokeOccludersTemplate) <| $(var init)
    set(init, "transform", transform)
    set(init, "smoke_occluders__destroyAtTime", get_sync_time() + lifetime)
