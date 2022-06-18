require ecs
require DagorMath
require soundSystem
require strings
require level

// will work only if region name is not empty, should bind something at daNetGame/dasModules/level.cpp if it is not ok;
// may add and bind some sound specific property to region objects
def has_region_at_pos(pos : float2)
  return !empty(get_region_name_by_pos(pos))

[es(tag=sound, no_order)]
def ambient_sound_regionquery_update(info : UpdateStageInfoAct;
                                     ambient_sound_regionquery__updateInterval : float;
                                     var ambient_sound_regionquery__curNextTime : float2&;
                                     var ambient_sound_regionquery__values : float2&;
                                     var ambient_sound_regionquery__result : float&)
  if info.curTime >= ambient_sound_regionquery__curNextTime.y
    ambient_sound_regionquery__curNextTime.x = info.curTime
    ambient_sound_regionquery__curNextTime.y = info.curTime + ambient_sound_regionquery__updateInterval
    ambient_sound_regionquery__values.x = ambient_sound_regionquery__result
    ambient_sound_regionquery__values.y = has_region_at_pos(soundSystem::get_listener_pos().xz) ? 1. : 0.

  ambient_sound_regionquery__result = cvt(info.curTime, ambient_sound_regionquery__curNextTime.x, ambient_sound_regionquery__curNextTime.y,
                                                        ambient_sound_regionquery__values.x, ambient_sound_regionquery__values.y)
