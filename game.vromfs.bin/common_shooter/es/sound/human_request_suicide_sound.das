require ecs
require sound_utils.modules.sound_player_common


[es(tag=sound, REQUIRE=humanSound, on_event=RequestSuicide)]
def human_request_suicide_sound(evt : Event;
                                [[shared_comp]] sound_paths : Object;
                                transform : float3x4;
                                sound_tags : Object;
                                is_watched_sound : bool)
  if is_watched_sound
    sound_player_common::play_path("suicide", sound_paths, sound_tags, is_watched_sound, transform[3])
