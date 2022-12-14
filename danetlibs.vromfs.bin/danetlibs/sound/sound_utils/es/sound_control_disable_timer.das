require ecs
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound)]
def sound_control_disable_timer__update(info : ParallelUpdateFrameDelayed;
                                        sound_control_disable_timer__endTime : float;
                                        var sound_control__enable : bool&)
  if info.curTime >= sound_control_disable_timer__endTime && sound_control_disable_timer__endTime >= 0.
    sound_control__enable = false
