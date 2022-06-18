require ecs
require DagorRandom

[es(tag=server, on_appear)]
def volfog_snow_init_es(evt : Event; var volfog_snow__intensitySeed : int&)
  volfog_snow__intensitySeed = grnd()

[es(tag=server, no_order)]
def volfog_snow_update_intensity_es(info : UpdateStageInfoAct;
                                    volfog_snow__intensityChangeTime : float;
                                    volfog_snow__maxIntensityRange : float2;
                                    var volfog_snow__intensitySeed : int&;
                                    var volfog_snow__maxIntensity : float&;
                                    var volfog_snow__intensityNextChangeTimer : float&)
  if volfog_snow__intensityNextChangeTimer < 0.f
    volfog_snow__intensityNextChangeTimer = info.curTime + volfog_snow__intensityChangeTime
    return

  if volfog_snow__intensityNextChangeTimer >= info.curTime
    return

  volfog_snow__maxIntensity = _rnd_float(volfog_snow__intensitySeed, volfog_snow__maxIntensityRange.x, volfog_snow__maxIntensityRange.y)
  volfog_snow__intensityNextChangeTimer = -1.f
