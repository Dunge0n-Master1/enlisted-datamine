require ecs
require soundEvent
require soundSystem


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE=watchedByPlr)]
def human_fall_wind_sound_update(evt : Event;
                                 human_fall_wind_sound__startSpeed : float;
                                 human_fall_wind_sound__path : string;
                                 var human_fall_wind_sound__event : SoundEvent&;
                                 human_net_phys__velocity : float3;
                                 isInVehicle : bool)

  let enable = -human_net_phys__velocity.y >= human_fall_wind_sound__startSpeed && !isInVehicle
  if human_fall_wind_sound__event.enabled != enable
    human_fall_wind_sound__event.enabled = enable
    abandon(human_fall_wind_sound__event.handle)
    if enable
      human_fall_wind_sound__event |> play(human_fall_wind_sound__path, get_listener_pos())
  if human_fall_wind_sound__event.enabled
    set_pos(human_fall_wind_sound__event.handle, get_listener_pos())
    set_var(human_fall_wind_sound__event.handle, "speed", -human_net_phys__velocity.y)


[es(tag=sound, on_disappear, REQUIRE=watchedByPlr)]
def human_fall_wind_sound_disappear(evt : Event;
                                    var human_fall_wind_sound__event : SoundEvent&)
  release(human_fall_wind_sound__event.handle)
