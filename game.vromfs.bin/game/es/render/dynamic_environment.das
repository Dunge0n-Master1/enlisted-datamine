require ecs
require math
require math.base
require daSkies
require DagorDataBlock

let
  AVG_TO_KM = 0.5f / 1000f
  maxCloudsAltitude = 10f

[es(tag=render, on_event=EventLevelLoaded)]
def scene_weather_load(evt : Event; dynamic_environment__time : float; dynamic_environment__weather_datablock : string; dynamic_environment__skies_seed : int)
  var skies = get_daskies()
  if skies == null
    return
  print("dyn_environment_weather: weather set to '{dynamic_environment__weather_datablock}'")
  set_daskies_time(dynamic_environment__time)
  using <| $(var skiesBlk : DataBlock#)
    datablock_load(skiesBlk, dynamic_environment__weather_datablock)
    load_daSkies(*skies, skiesBlk, dynamic_environment__skies_seed, skiesBlk)

[es(tag=render, track=dynamic_environment__time)]
def dyn_environment_time(evt : Event; dynamic_environment__time : float)
  set_daskies_time(dynamic_environment__time)

[es(tag=render, track=dynamic_environment__weather_datablock, after=dyn_environment_time)]
def dyn_environment_weather(evt : Event; dynamic_environment__weather_datablock : string; dynamic_environment__skies_seed : int)
  print("dyn_environment_weather: change to '{dynamic_environment__weather_datablock}'")
  var skies = get_daskies()
  if skies != null
    print("reload skies settings from '{dynamic_environment__weather_datablock}'")
    using <| $(var skiesBlk : DataBlock#)
      datablock_load(skiesBlk, dynamic_environment__weather_datablock)
      load_daSkies(*skies, skiesBlk, dynamic_environment__skies_seed, skiesBlk)

[es(tag=render, on_event=(EventEntityCreated, EventComponentChanged),
    REQUIRE=dynamic_environment__weather_datablock, track=dynamic_environment__weather_datablock)]
def clouds_update_wind_altitude(evt : Event)
  query() <| $ [es] (var dyn_wind__cumulus_alt_multiplier : float&;
                     var dyn_wind__strata_alt_multiplier : float&)
    let skies = get_daskies()
    if skies != null
      let avgCumulusAlt = (daskies_getCloudsStartAltSettings(*skies) + daskies_getCloudsTopAltSettings(*skies)) * AVG_TO_KM
      dyn_wind__cumulus_alt_multiplier = 1f + clamp(avgCumulusAlt, 0f, maxCloudsAltitude)
      dyn_wind__strata_alt_multiplier = 1f + clamp((*skies).strataClouds.altitude, 0f, maxCloudsAltitude)

[es(tag=render, no_order)]
def clouds_wind_move(info : UpdateStageInfoAct; wind__dir : float; wind__strength : float; wind__noiseStrength : float;
                     dyn_wind__cumulus_alt_multiplier : float; dyn_wind__strata_alt_multiplier : float)
  var windDirX, windDirZ : float
  sincos(deg_to_rad(wind__dir), windDirZ, windDirX)
  let windStrengthDt = beaufort_to_meter_per_second(wind__strength) * wind__noiseStrength * info.dt
  let windStrengthDtX = windDirX * windStrengthDt
  let windStrengthDtZ = windDirZ * windStrengthDt

  let cumulusCloudsMovement = float2(windStrengthDtX * dyn_wind__cumulus_alt_multiplier,
                                     windStrengthDtZ * dyn_wind__cumulus_alt_multiplier)
  move_cumulus_clouds(cumulusCloudsMovement)
  let strataCloudsMovement = float2(windStrengthDtX * dyn_wind__strata_alt_multiplier,
                                    windStrengthDtZ * dyn_wind__strata_alt_multiplier)
  move_strata_clouds(strataCloudsMovement)