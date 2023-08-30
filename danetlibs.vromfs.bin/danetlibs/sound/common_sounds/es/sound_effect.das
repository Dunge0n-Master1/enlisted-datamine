require ecs
require soundEvent
require soundSystem


[es(tag=sound, track=sound_control__shouldPlay, REQUIRE_NOT=watchableSoundEffect)]
def sound_effect_track(evt : Event;
                       sound_control__shouldPlay : bool;
                       sound_control__inRange : bool;
                       sound_effect__path : string;
                       sound_effect__localOffset : float3;
                       var sound_effect__event : SoundEvent&;
                       transform : float3x4)
  if sound_control__inRange
    abandon(sound_effect__event.handle)
  else
    release(sound_effect__event.handle)
  if sound_control__shouldPlay
    sound_effect__event |> play(sound_effect__path, transform * sound_effect__localOffset)


[es(tag=sound, track=(sound_control__shouldPlay, is_watched_sound), REQUIRE=watchableSoundEffect)]
def sound_effect_track_watchable(evt : Event;
                                 sound_control__shouldPlay : bool;
                                 sound_control__inRange : bool;
                                 sound_effect__path : string;
                                 sound_effect__watchedPath : string;
                                 sound_effect__localOffset : float3;
                                 is_watched_sound : bool;
                                 var sound_effect__event : SoundEvent&;
                                 transform : float3x4)
  if sound_control__inRange
    abandon(sound_effect__event.handle)
  else
    release(sound_effect__event.handle)
  if sound_control__shouldPlay
    let path = is_watched_sound ? sound_effect__watchedPath : sound_effect__path
    sound_effect__event |> play(path, transform * sound_effect__localOffset)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE=movableSoundEffect)]
def sound_effect_update_moveable(evt : Event;
                                 sound_effect__event : SoundEvent;
                                 sound_effect__localOffset : float3;
                                 transform : float3x4)
  if is_valid(sound_effect__event.handle)
    set_pos(sound_effect__event.handle, transform * sound_effect__localOffset)


[es(tag=sound, track=sound_banks_state__isPresetLoaded, REQUIRE=sound_banks_state__isPresetLoaded)]
def sound_effect_init_path(evt : Event;
                           var sound_effect__path : das_string&;
                           replicated_sound_effect__path : string)
  sound_effect__path := replicated_sound_effect__path


[es(tag=sound, track=sound_banks_state__isPresetLoaded, after=sound_effect_init_path)]
def sound_effect_init(evt : Event;
                      sound_banks_state__isPresetLoaded : bool;
                      sound_effect__autoRange : bool;
                      var sound_control__range : float&;
                      sound_effect__path : string;
                      sound_effect__abandonOnReset : bool;
                      var sound_effect__event : SoundEvent&)
  if sound_banks_state__isPresetLoaded
    if sound_effect__autoRange
      sound_control__range = get_max_distance(sound_effect__path)
      if sound_control__range <= 0.
        sound_control__range = 35.
        sound_debug("unknown range for {sound_effect__path}")
      elif sound_control__range > 8000.
        sound_debug("max distance {sound_control__range} for event {sound_effect__path} seems too big")
    sound_effect__event.abandonOnReset = sound_effect__abandonOnReset
  else
    release_immediate(sound_effect__event.handle)
    if sound_effect__autoRange
      sound_control__range = 0.
