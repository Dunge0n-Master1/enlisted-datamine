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
require DagorSystem


def get_effect(active_effects : Object; all_ordered_effects : StringList) : string
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

  let newId = get_effect(human_voice_effect__activeEffects, human_voice_effect__allOrderedEffects)
  let curId = string(human_voice_effect__type)

  if newId != curId
    if !keyoff(human_voice_effect__event.handle)
      release(human_voice_effect__event.handle)

    let curDesc = human_voice_sound__descs[curId] ?as Object
    let newDesc = human_voice_sound__descs[newId] ?as Object
    let curEndDesc = curDesc?.end ?as Object

    if empty(newId) && curEndDesc != null
      if human_voice_effect__isInited
        if newDesc?.abandoner != null
          abandon(human_voice_effect__event.handle)
        else
          release(human_voice_effect__event.handle)
        human_voice_effect__event.handle = play_desc(*curEndDesc, human_voice_sound__path, sound_tags, is_watched_sound, transform[3], false)
    elif !empty(newId)
      let newStartDesc = newDesc?.start ?as Object
      if newStartDesc != null
        if human_voice_effect__isInited
          if newDesc?.abandoner != null
            abandon(human_voice_effect__event.handle)
          else
            release(human_voice_effect__event.handle)
          human_voice_effect__event.handle = play_desc(*newStartDesc, human_voice_sound__path, sound_tags, is_watched_sound, transform[3], false)
      else
        if newDesc?.abandoner != null
          abandon(human_voice_effect__event.handle)
        else
          release(human_voice_effect__event.handle)
        if newDesc != null
          human_voice_effect__event.handle = play_desc(*newDesc, human_voice_sound__path, sound_tags, is_watched_sound, transform[3], false)

    let curToNew = newDesc?[curId] ?as Object
    if curToNew != null
      play_desc(*curToNew, human_voice_sound__path, sound_tags, is_watched_sound, transform[3])

    human_voice_effect__type := newId
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
  let maxDelay = 3.
  if !human_voice_effect__isActive && !human_speech__isSpeaking && get_sync_time() < evt.time + maxDelay
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
