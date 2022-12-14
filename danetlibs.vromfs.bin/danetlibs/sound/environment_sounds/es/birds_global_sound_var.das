require ecs
require app
require soundSystem
require sound_utils.modules.sound_utils_events
require sound_utils_net.modules.sound_utils_net_events
require DagorMath


[es(tag=sound)]
def birds_sound_shut_up(evt : EventOnWeaponSound;
                        var birds_global_sound_var__noiseTime : float&;
                        birds_global_sound_var__actionRange = 250.)
  if length_sq(get_listener_pos() - evt.pos) < birds_global_sound_var__actionRange * birds_global_sound_var__actionRange
    birds_global_sound_var__noiseTime = get_sync_time()


[es(tag=sound)]
def birds_sound_update(info : ParallelUpdateFrameDelayed;
                       birds_global_sound_var__noiseTime : float;
                       birds_global_sound_var__name : string;
                       birds_global_sound_var__timeRange : float2)
  let action = cvt(info.curTime - birds_global_sound_var__noiseTime, birds_global_sound_var__timeRange.x, birds_global_sound_var__timeRange.y, 1., 0.)
  set_var_global(birds_global_sound_var__name, action)
