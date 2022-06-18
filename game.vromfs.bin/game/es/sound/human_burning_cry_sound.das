require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common

[es(tag=sound, REQUIRE=humanBurningCrySound, track=burning__isBurning, track=is_watched_sound)]
def human_burning_cry_sound(evt : Event;
                            [[shared_comp]] human_voice_sound__path : Object;
                            [[shared_comp]] human_voice_sound__descs : Object;
                            transform : float3x4;
                            var sound_event_group : SoundEventGroup&;
                            burning__isBurning : bool;
                            isAlive : bool;
                            isDowned : bool = false;
                            sound_tags : Object;
                            is_watched_sound : bool = false;
                            human_net_phys__isUnderwater : bool = false;
                            human_net_phys__isHoldBreath : bool = false)
  if burning__isBurning && isAlive && !isDowned && !human_net_phys__isHoldBreath && !human_net_phys__isUnderwater
    sound_player_common::play("burningCry", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("burningCry"), sound_event_group)
  else
    reject_sound(sound_event_group, sound_hash("burningCry"))
