require ecs
require soundHash
require soundEvent
require common_shooter.events_common_shooter
require sound_utils.modules.sound_player_common

[es(tag=sound, REQUIRE=humanHitCrySound)]
def human_hit_cry_sound(evt : EventOnEntityHit; eid : EntityId;
                        [[shared_comp]] human_voice_sound__path : Object;
                        [[shared_comp]] human_voice_sound__descs : Object;
                        transform : float3x4;
                        var sound_event_group : SoundEventGroup&;
                        isAlive : bool;
                        sound_tags : Object;
                        is_watched_sound : bool = false)
  if eid == evt.victim
    if isAlive && !has_sound(sound_event_group, sound_hash("voiceEffect"))
      sound_player_common::play("hitCry", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)
