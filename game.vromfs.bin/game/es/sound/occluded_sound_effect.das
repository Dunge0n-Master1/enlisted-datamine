require ecs
require soundEvent

[es(tag=sound, after=sound_occlusion_update)]
def occluded_sound_effect_update(info : UpdateStageInfoAct;
                                 sound_effect__event : SoundEvent;
                                 occluded_sound__volume : float)
  set_volume(sound_effect__event.handle, occluded_sound__volume)
