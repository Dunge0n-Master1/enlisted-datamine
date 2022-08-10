require ecs
require DagorMath
require soundSystem
require strings
require level
require Dacoll


[es(tag=sound, no_order)]
def rain_global_sound_var_update(info : UpdateStageInfoAct;
                                 rain_global_sound_var__name : string;
                                 rain_global_sound_var__mult : float)
  var rain = 0.
  query() <| $ [es] (far_rain__density, far_rain__speed : float)
    rain = far_rain__density * far_rain__speed
  set_var_global(rain_global_sound_var__name, rain * rain_global_sound_var__mult)


[es(tag=sound, no_order)]
def daytime_global_sound_var_update(info : UpdateStageInfoAct;
                                    daytime_global_sound_var__name : string)
  var timeOfDay = 0.
  query() <| $ [es] (level__timeOfDay : float)
    timeOfDay = level__timeOfDay
  set_var_global(daytime_global_sound_var__name, timeOfDay)


[es(tag=sound, no_order)]
def altitude_global_sound_var_update(info : UpdateStageInfoAct;
                                     altitude_global_sound_var__name : string;
                                     altitude_global_sound_var__interval : float;
                                     var altitude_global_sound_var__nextTime : float&)
  if info.curTime >= altitude_global_sound_var__nextTime
    altitude_global_sound_var__nextTime = info.curTime + altitude_global_sound_var__interval
    var altitude = 0.
    var waterHeight = 0.
    let pos = get_listener_pos()
    if traceht_water(pos, waterHeight)
      altitude = pos.y - waterHeight
    else
      let pos2d = pos.xz
      let ground = traceht_lmesh(pos2d)
      altitude = pos.y - ground
    set_var_global(altitude_global_sound_var__name, altitude)


[es(tag=sound, no_order)]
def region_global_sound_var_update(info : UpdateStageInfoAct;
                                   region_global_sound_var__updateInterval : float;
                                   var region_global_sound_var__curNextTime : float2&;
                                   var region_global_sound_var__values : float2&;
                                   var region_global_sound_var__value : float&;
                                   region_global_sound_var__name : string)
  if info.curTime >= region_global_sound_var__curNextTime.y
    // will work only if region name is not empty, should bind something at daNetGame/dasModules/level.cpp if it is not ok
    // or may add & bind some sound specific property to region objects
    let pozXZ = soundSystem::get_listener_pos().xz
    let hasRegionAtPos = !empty(get_region_name_by_pos(pozXZ))

    region_global_sound_var__curNextTime.x = info.curTime
    region_global_sound_var__curNextTime.y = info.curTime + region_global_sound_var__updateInterval
    region_global_sound_var__values.x = region_global_sound_var__value
    region_global_sound_var__values.y = hasRegionAtPos ? 1. : 0.

  region_global_sound_var__value = cvt(info.curTime, region_global_sound_var__curNextTime.x, region_global_sound_var__curNextTime.y,
                                       region_global_sound_var__values.x, region_global_sound_var__values.y)

  set_var_global(region_global_sound_var__name, region_global_sound_var__value)
