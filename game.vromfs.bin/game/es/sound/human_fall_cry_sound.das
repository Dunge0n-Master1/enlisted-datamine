require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common

[es(tag=sound, after=(human_fall_sound_is_falling_update, human_fall_sound_with_spawn_is_falling_update))]
def human_fall_cry_sound(info : UpdateStageInfoAct;
                         sound_tags : Object;
                         [[shared_comp]] human_voice_sound__path : Object;
                         [[shared_comp]] human_voice_sound__descs : Object;
                         var sound_event_group : SoundEventGroup&;
                         is_watched_sound : bool;
                         human_fall_cry_sound__enabled : bool = true;
                         human_fall_cry_sound__interval : float;
                         var human_fall_cry_sound__time : float&;
                         human_fall_sound__isFalling : bool;
                         transform : float3x4;
                         isAlive : bool;
                         isDowned : bool)
  if human_fall_cry_sound__enabled && human_fall_sound__isFalling && isAlive && !isDowned
    if info.curTime >= human_fall_cry_sound__time + human_fall_cry_sound__interval
      human_fall_cry_sound__time = info.curTime
      sound_player_common::play("fallCry", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("fallCry"), sound_event_group)
  else
    reject_sound(sound_event_group, sound_hash("fallCry"))
