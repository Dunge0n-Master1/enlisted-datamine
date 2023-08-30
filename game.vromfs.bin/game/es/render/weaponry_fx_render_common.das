module weaponry_fx_render_common shared

require ecs
require ecs.safe
require common_shooter.es.weapon.weaponry_fx_common
require fx


def spawn_hit_effect(norm : float3; pos : float3; fx_name : string; allow_paint_from_biome : bool = false; rendinst_pool : int = -1)
  if empty(fx_name) || fx_name == "-"
    return

  let tm = calc_effect_tm(pos, norm)
  let fxTemplate = getTemplateByName(fx_name)
  if fxTemplate == null
    return

  let lowestFxQuality = getTemplateComponent(*fxTemplate, "effect__lowestFxQuality") ?? 0
  if int(get_fx_target()) < (1 << lowestFxQuality)
    return

  if allow_paint_from_biome && (getTemplateComponent(*fxTemplate, "paint_from_biome") ?? false)
    createEntity("hit_fx_readback_info") <| $(init)
      init |> set("transform", tm)
      init |> set("hit_fx_name", fx_name)
  else
    createEntity(fx_name) <| $(init)
      init |> set("transform", tm)
      init |> set("effect__riPoolUsedForColoring", rendinst_pool)
