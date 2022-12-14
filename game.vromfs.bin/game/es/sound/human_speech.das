require ecs
require ecs.safe
require app
require soundHash
require soundSystem
require soundEvent
require enlisted.events_enlisted
require game.es.sound_net.sound_net_events
require sound_utils_net.modules.sound_desc_common
require sound_utils.modules.sound_player_common
require game.utils.hero
require game.utils.team
require game.events_game
require strings


let SPEECH_MAX_NET_LATENCY = 5.
let SPEECH_WATCHED_VOLUME = 1.5
let SPEECH_TEAM_VOLUME = 1.5

def get_npc_voice(voice_id : int; npc_voices : StringList)
  if length(npc_voices) == 0 || voice_id < 0
    return ""
  return string(npc_voices[voice_id % int(length(npc_voices))])

def start_speech(phrase_idx : int;
                 human_speech__canSpeak : bool;
                 human_sound__playerVoice : string;
                 human_sound__npcVoices : StringList;
                 human_voice_sound__voiceId : int;
                 [[shared_comp]] human_speech__speeches : Array;
                 is_watched_sound : bool;
                 var sound_event_group : SoundEventGroup&;
                 transform : float3x4;
                 team : int = TEAM_UNASSIGNED;
                 human_speech__distThreshold = 50.)
  if human_speech__canSpeak && uint(phrase_idx) < uint(human_speech__speeches.size) && (is_watched_sound || should_play(transform[3], human_speech__distThreshold))
    let desc = human_speech__speeches[phrase_idx] as Object
    if desc != null
      if !(desc?.replace ?? false) && is_playing(get_sound(sound_event_group, sound_hash("speech")))
        return
      let path = is_watched_sound ? human_sound__playerVoice : get_npc_voice(human_voice_sound__voiceId, human_sound__npcVoices)
      let handle = sound_player_common::play_desc_path(*desc, path, sound_hash("speech"), transform[3], sound_event_group)
      if is_watched_sound
        set_volume(handle, SPEECH_WATCHED_VOLUME)
      elif team != TEAM_UNASSIGNED && team == get_local_player_team()
        set_volume(handle, SPEECH_TEAM_VOLUME)

[es(tag=sound)]
def human_speech_cmd(evt : CmdHumanSpeech;
                     human_speech__canSpeak : bool;
                     human_sound__playerVoice : string;
                     human_sound__npcVoices : StringList;
                     human_voice_sound__voiceId : int;
                     [[shared_comp]] human_speech__speeches : Array;
                     is_watched_sound : bool;
                     var sound_event_group : SoundEventGroup&;
                     transform : float3x4;
                     team : int = TEAM_UNASSIGNED)
  if get_sync_time() < evt.time + SPEECH_MAX_NET_LATENCY
    start_speech(evt.phraseIdx,
                 human_speech__canSpeak,
                 human_sound__playerVoice,
                 human_sound__npcVoices,
                 human_voice_sound__voiceId,
                 human_speech__speeches,
                 is_watched_sound,
                 sound_event_group,
                 transform,
                 team)

[es(tag=sound)]
def human_speech_quick_chat(evt : CmdHumanQuickChatSpeech;
                            human_speech__canSpeak : bool;
                            human_sound__playerVoice : string;
                            human_sound__npcVoices : StringList;
                            human_voice_sound__voiceId : int;
                            [[shared_comp]] human_speech__speeches : Array;
                            is_watched_sound : bool;
                            var sound_event_group : SoundEventGroup&;
                            transform : float3x4;
                            team : int;
                            human_speech__hardcoreMaxDistance : float = 50.)
  if get_local_player_team() != team || get_sync_time() >= evt.time + SPEECH_MAX_NET_LATENCY
    return

  let isHardcoreMode = find_query() <| $ [es(REQUIRE=noBotsMode)] () { return true; }
  if isHardcoreMode && !should_play(transform[3], human_speech__hardcoreMaxDistance)
    return

  let unlimitedMaxDistance = -1.
  start_speech(evt.phraseIdx,
               human_speech__canSpeak,
               human_sound__playerVoice,
               human_sound__npcVoices,
               human_voice_sound__voiceId,
               human_speech__speeches,
               is_watched_sound,
               sound_event_group,
               transform,
               team,
               unlimitedMaxDistance)


[es(tag=sound)]
def human_speech_for_any_specific_player(evt : CmdHumanSpeechForAnySpecificPlayer;
                                         human_speech__canSpeak : bool;
                                         human_sound__playerVoice : string;
                                         human_sound__npcVoices : StringList;
                                         human_voice_sound__voiceId : int;
                                         [[shared_comp]] human_speech__speeches : Array;
                                         is_watched_sound : bool;
                                         var sound_event_group : SoundEventGroup&;
                                         transform : float3x4;
                                         team : int = TEAM_UNASSIGNED)
  if get_sync_time() < evt.time + SPEECH_MAX_NET_LATENCY
    start_speech(evt.phraseIdx,
                 human_speech__canSpeak,
                 human_sound__playerVoice,
                 human_sound__npcVoices,
                 human_voice_sound__voiceId,
                 human_speech__speeches,
                 is_watched_sound,
                 sound_event_group,
                 transform,
                 team)


[es(tag=sound)]
def human_speech_cmd_human_speech_for_hero(evt : CmdHumanSpeechForHero;
                                           human_speech__canSpeak : bool;
                                           human_sound__playerVoice : string;
                                           human_sound__npcVoices : StringList;
                                           human_voice_sound__voiceId : int;
                                           [[shared_comp]] human_speech__speeches : Array;
                                           var sound_event_group : SoundEventGroup&;
                                           transform : float3x4;
                                           team : int = TEAM_UNASSIGNED)
  if get_sync_time() < evt.time + SPEECH_MAX_NET_LATENCY
    start_speech(evt.phraseIdx,
                 human_speech__canSpeak,
                 human_sound__playerVoice,
                 human_sound__npcVoices,
                 human_voice_sound__voiceId,
                 human_speech__speeches,
                 true,
                 sound_event_group,
                 transform,
                 team)


[es(tag=sound)]
def human_speech_cmd_hero_speech(evt : CmdHeroSpeech;
                                 human_speech__canSpeak : bool;
                                 human_sound__playerVoice : string;
                                 human_sound__npcVoices : StringList;
                                 human_voice_sound__voiceId : int;
                                 [[shared_comp]] human_speech__speeches : Array;
                                 var sound_event_group : SoundEventGroup&;
                                 transform : float3x4;
                                 team : int = TEAM_UNASSIGNED)
  let phraseIdx = find_desc_idx(evt.phrase, human_speech__speeches)
  if phraseIdx >= 0
    start_speech(phraseIdx,
                 human_speech__canSpeak,
                 human_sound__playerVoice,
                 human_sound__npcVoices,
                 human_voice_sound__voiceId,
                 human_speech__speeches,
                 true,
                 sound_event_group,
                 transform,
                 team)
  else
    sound_debug("There is no human speech desc for phrase '{evt.phrase}'")


[es(tag=sound, on_appear, on_disappear, track=(human_voice_enable, human_voice_effect__type), REQUIRE_NOT=humanSpeechDisable)]
def human_speech_can_speak(evt : Event;
                           human_voice_enable : bool;
                           human_voice_effect__type : string;
                           var human_speech__canSpeak : bool&;
                           var sound_event_group : SoundEventGroup&)
  human_speech__canSpeak = human_voice_enable && empty(human_voice_effect__type)
  if !human_speech__canSpeak
    release_sound(sound_event_group, sound_hash("speech"))


[es(tag=sound, on_disappear, REQUIRE=human_speech__canSpeak)]
def human_speech_disappear(evt : Event;
                           var sound_event_group : SoundEventGroup&)
  release_sound(sound_event_group, sound_hash("speech"))
