require ecs
require ecs.safe
require ecs.common
require app
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common
require human_sounds.modules.human_voice_effect_common
require human_sounds.modules.human_sounds_events
require human_sounds_net.modules.human_sounds_net_events
require strings


let MAX_NET_DELAY = 4.


// have two oneshot descs("{name}Start", "{name}End") instead of one non-oneshot
def is_combined_voice_effect(name : string; descs : Object)
  return get_desc(descs, name) == null


def get_human_voice_effect(active_effects : Object; all_ordered_effects : StringList) : string
  for effect in all_ordered_effects
    if active_effects[string(effect)] ?? false
      return string(effect)
  return ""


[es(tag=sound, track=is_watched_sound)]
def human_voice_effect_on_watched(evt : Event;
                                  human_voice_effect__type : string;
                                  is_watched_sound = false;
                                  [[shared_comp]] human_voice_sound__path : Object;
                                  [[shared_comp]] human_voice_sound__descs : Object;
                                  var human_voice_effect__event : SoundEvent&;
                                  sound_tags : Object;
                                  transform : float3x4)
  if is_playing(human_voice_effect__event.handle) && !is_oneshot(human_voice_effect__event.handle)
    release(human_voice_effect__event.handle)
    human_voice_effect__event.handle = play(human_voice_effect__type, human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], false)


[es(tag=sound, on_appear, track=human_voice_effect__activeEffects)]
def human_voice_effect_on_change(evt : Event;
                                 var human_voice_effect__type : das_string&;
                                 var human_voice_effect__isInited : bool&;
                                 var human_voice_effect__event : SoundEvent&;
                                 var human_voice_effect__isActive : bool&;
                                 human_voice_effect__activeEffects : Object;
                                 [[shared_comp]] human_voice_effect__allOrderedEffects : StringList;
                                 is_watched_sound = false;
                                 [[shared_comp]] human_voice_sound__path : Object;
                                 [[shared_comp]] human_voice_sound__descs : Object;
                                 sound_tags : Object;
                                 transform : float3x4)
  let effect = get_human_voice_effect(human_voice_effect__activeEffects, human_voice_effect__allOrderedEffects)
  if effect != human_voice_effect__type
    if !keyoff(human_voice_effect__event.handle)
      release(human_voice_effect__event.handle)
    if empty(effect) && !empty(human_voice_effect__type) && is_combined_voice_effect(string(human_voice_effect__type), human_voice_sound__descs)
      if human_voice_effect__isInited
        release(human_voice_effect__event.handle)
        human_voice_effect__event.handle = play("{human_voice_effect__type}End", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], false)
    elif !empty(effect)
      if is_combined_voice_effect(effect, human_voice_sound__descs)
        if human_voice_effect__isInited
          release(human_voice_effect__event.handle)
          human_voice_effect__event.handle = play("{effect}Start", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], false)
      else
        release(human_voice_effect__event.handle)
        human_voice_effect__event.handle = play(effect, human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], false)
    human_voice_effect__type := effect
  human_voice_effect__isInited = true
  human_voice_effect__isActive = !empty(human_voice_effect__type) || human_voice_effect__event.handle != invalid_sound_event_handle()


[es(tag=sound)]
def human_voice_effect_on_cmd(evt : CmdHumanVoiceEffect;
                              var human_voice_effect__event : SoundEvent&;
                              [[shared_comp]] human_voice_sound__path : Object;
                              [[shared_comp]] human_voice_sound__descs : Object;
                              human_voice_effect__isActive : bool;
                              human_speech__isSpeaking : bool = false;
                              is_watched_sound : bool = false;
                              sound_tags : Object;
                              transform : float3x4)
  if !human_voice_effect__isActive && !human_speech__isSpeaking
    release(human_voice_effect__event.handle)
    human_voice_effect__event.handle = play(evt.phrase, human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], false)


[es(tag=sound)]
def human_voice_effect_on_net_cmd(evt : CmdNetHumanVoiceEffect;
                                  var human_voice_effect__event : SoundEvent&;
                                  [[shared_comp]] human_voice_sound__path : Object;
                                  [[shared_comp]] human_voice_sound__descs : Object;
                                  human_voice_effect__isActive : bool;
                                  human_speech__isSpeaking : bool = false;
                                  is_watched_sound : bool = false;
                                  sound_tags : Object;
                                  transform : float3x4)
  if !human_voice_effect__isActive && !human_speech__isSpeaking && get_sync_time() < evt.time + MAX_NET_DELAY
    release(human_voice_effect__event.handle)
    human_voice_effect__event.handle = play(evt.phrase, human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], false)


[es(tag=sound, no_order, on_event=ParallelUpdateFrameDelayed)]
def human_voice_effect_update(evt : Event;
                              transform : float3x4;
                              var human_voice_effect__event : SoundEvent&;
                              var human_voice_effect__isActive : bool&;
                              human_voice_effect__type : string)
  if human_voice_effect__event.handle != invalid_sound_event_handle()
    if is_playing(human_voice_effect__event.handle)
      set_pos(human_voice_effect__event.handle, transform[3])
      human_voice_effect__isActive = true
      return
    release(human_voice_effect__event.handle)
  human_voice_effect__isActive = !empty(human_voice_effect__type)
