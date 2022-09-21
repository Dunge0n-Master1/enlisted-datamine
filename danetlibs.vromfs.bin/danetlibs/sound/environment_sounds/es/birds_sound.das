require ecs
require app
require soundSystem
require sound_utils.modules.sound_utils_events
require DagorMath


[es(tag=sound)]
def birds_sound_shut_up(evt : EventOnWeaponSound;
                        var birds_sound__noiseTime : float&;
                        birds_sound__actionRange = 250.)
  if length_sq(get_listener_pos() - evt.pos) < birds_sound__actionRange * birds_sound__actionRange
    birds_sound__noiseTime = get_sync_time()


[es(tag=sound, no_order)]
def birds_sound_update(info : UpdateStageInfoAct;
                       birds_sound__noiseTime : float;
                       birds_sound__globalVar : string;
                       birds_sound__timeRange : float2)
  let action = cvt(info.curTime - birds_sound__noiseTime, birds_sound__timeRange.x, birds_sound__timeRange.y, 1., 0.)
  set_var_global(birds_sound__globalVar, action)
