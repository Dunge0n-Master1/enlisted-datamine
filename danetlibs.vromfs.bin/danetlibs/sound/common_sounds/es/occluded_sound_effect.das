require ecs
require soundEvent


[es(tag=sound, on_appear, after=sound_effect_appear)]
def occluded_sound_effect_appear(evt : Event;
                                 sound_control__range : float;
                                 occluded_sound__rangeMul : float;
                                 occluded_sound__nearFarAttenuation : float2;
                                 var occluded_sound__nearFarRange : float2&)
  occluded_sound__nearFarRange = occluded_sound__nearFarAttenuation * (sound_control__range * occluded_sound__rangeMul)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=sound_occlusion_update)]
def occluded_sound_effect_update(evt : Event;
                                 sound_effect__event : SoundEvent;
                                 occluded_sound__volume : float)
  set_volume(sound_effect__event.handle, occluded_sound__volume)
