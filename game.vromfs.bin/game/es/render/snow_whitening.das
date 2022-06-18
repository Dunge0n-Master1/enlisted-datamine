require ecs
require math
require DagorShaders
require DagorMath

let
  envi_cover_normal_mask_thresholdVarId = get_shader_variable_id("envi_cover_normal_mask_threshold", true)
  envi_cover_lowest_intensityVarId = get_shader_variable_id("envi_cover_lowest_intensity", true)
  envi_coverVarId = get_shader_variable_id("envi_cover", true)

[es(tag=render, on_appear, REQUIRE = (snow_whitening__speed))]
def snow_whitening_appear(evt : Event; var snow_whitening__baseAmount : float&; var snow_whitening__amount : float&)
  snow_whitening__baseAmount = DagorShaders::get_real(envi_cover_normal_mask_thresholdVarId)
  snow_whitening__amount = 0.0
  DagorShaders::set_real(envi_cover_lowest_intensityVarId, 0.)

[es(no_order, tag=render)]
def snow_whitening_update(
                          info : UpdateStageInfoAct;
                          snow_whitening__speed : float;
                          snow_whitening__baseAmount : float;
                          var snow_whitening__amount : float&;
                          snow_whitening__maxAmount = 0.5)
  snow_whitening__amount = snow_whitening__amount + snow_whitening__speed * info.dt
  DagorShaders::set_int(envi_coverVarId, 1)
  DagorShaders::set_real(envi_cover_normal_mask_thresholdVarId, clamp(snow_whitening__amount, 0., snow_whitening__maxAmount) + snow_whitening__baseAmount)
  DagorShaders::set_real(envi_cover_lowest_intensityVarId, clamp(snow_whitening__amount, 0., 1.))


[es(tag=render, on_disappear, REQUIRE = (snow_whitening__speed, snow_whitening__amount))]
def snow_whitening_disappear(evt : Event; snow_whitening__baseAmount : float)
  DagorShaders::set_real(envi_cover_lowest_intensityVarId, 0.)
  DagorShaders::set_real(envi_cover_normal_mask_thresholdVarId, snow_whitening__baseAmount)
  if snow_whitening__baseAmount < 0.001
    DagorShaders::set_int(envi_coverVarId, 0)
