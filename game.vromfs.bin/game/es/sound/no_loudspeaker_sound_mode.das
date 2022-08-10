require ecs

[es(tag=sound, REQUIRE=noLoudspeakerSoundMode, on_appear)]
def no_loudspeaker_sound_mode_appear(evt : Event)
  query() <| $ [es(REQUIRE=loudspeakerSound)] (var sound_control__enable : bool&)
    sound_control__enable = false

[es(tag=sound, REQUIRE=noLoudspeakerSoundMode, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def no_loudspeaker_sound_mode_disappear(evt : Event)
  query() <| $ [es(REQUIRE=loudspeakerSound)] (var sound_control__enable : bool&)
    sound_control__enable = true

[es(tag=sound, on_appear, REQUIRE=loudspeakerSound)]
def loudspeaker_sound_appear(evt : Event;
                             var sound_control__enable : bool&)
  let isNoLoudspeakerSoundMode = find_query() <| $ [es(REQUIRE=noLoudspeakerSoundMode)] ()
    return true
  sound_control__enable = !isNoLoudspeakerSoundMode
