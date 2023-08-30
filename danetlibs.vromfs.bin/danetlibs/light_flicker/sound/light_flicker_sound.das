require ecs
require soundEvent
require danetlibs.light_flicker.render.light_flicker_common


[es(tag=sound, on_appear, track=light_flicker__state)]
def light_flicker_sound(evt : Event;
                        light_flicker__state : int;
                        light_flicker__lightEids : EidList;
                        var light_flicker_sound__inited : bool&;
                        var light_flicker_sound__enabled : bool&)
  let enabled = light_flicker__state != int(LightFlickerState Off)
  if light_flicker_sound__enabled != enabled
    light_flicker_sound__enabled = enabled
    for lightEid in light_flicker__lightEids
      query(lightEid) <| $ [es(REQUIRE_NOT=disableSoundControl)] (var sound_control__enable : bool&;
                                                                  light_flicker_updater_sound__onPath : string;
                                                                  light_flicker_updater_sound__offPath : string;
                                                                  transform : float3x4)
        sound_control__enable = enabled
        if light_flicker_sound__inited
          oneshot(enabled ? light_flicker_updater_sound__onPath : light_flicker_updater_sound__offPath, transform[3])
  light_flicker_sound__inited = true


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def light_flicker_sound_update(evt : Event;
                               light_flicker_sound__enabled : bool;
                               light_flicker__brightness : float;
                               light_flicker__lightEids : EidList)
  if light_flicker_sound__enabled
    for lightEid in light_flicker__lightEids
      query(lightEid) <| $ [es(REQUIRE_NOT=disableSoundControl)] (light_flicker_updater_sound__event : SoundEvent)
        if light_flicker_updater_sound__event.handle != invalid_sound_event_handle()
          set_var(light_flicker_updater_sound__event.handle, "brightness", light_flicker__brightness)


[es(tag=sound, track=sound_control__shouldPlay)]
def light_flicker_updater_sound_track(evt : Event;
                                      sound_control__shouldPlay : bool;
                                      light_flicker_updater_sound__path : string;
                                      var light_flicker_updater_sound__event : SoundEvent&;
                                      transform : float3x4)
  abandon(light_flicker_updater_sound__event.handle)
  if sound_control__shouldPlay
    light_flicker_updater_sound__event |> play(light_flicker_updater_sound__path, transform[3])
