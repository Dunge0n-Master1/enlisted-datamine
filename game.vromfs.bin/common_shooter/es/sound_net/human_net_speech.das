require ecs
require ecs.safe
require app
require EnlistedNet
require soundSystem
require game.utils.team
require DagorMath
require DagorRandom
require DagorSystem
require game.events_game
require game.es.sound_net.sound_net_events
require sound_utils_net.modules.sound_desc_common
require game.utils.net_utils


def get_speech_time(idx : int; time : FloatList)
  return idx < length(time) ? time[idx] : 0.

def set_speech_time(idx : int; cur : float; var time : FloatList&)
  assert(idx < 999)
  while idx >= length(time)
    push(time, -1000.)
  time[idx] = cur

def is_alone(phrase_idx : int; cur_eid : EntityId; cur_pos : float3; cur_team : int; max_radius : float; var max_time : float&)
  if cur_team == TEAM_UNASSIGNED
    return true
  var isAlone : bool = true
  query() <| $ [es] (eid : EntityId; team : int; transform : float3x4; human_net_speech__time : FloatList; isAlive : bool)
    if isAlive && team == cur_team && distance_sq(cur_pos, transform[3]) < max_radius * max_radius
      max_time = max(get_speech_time(phrase_idx, human_net_speech__time), max_time)
      if eid != cur_eid
        isAlone = false
  return isAlone

def is_disable_after_prev_speech(desc : Object; speeches : Array; time : FloatList)
  let comp = desc["disableAfterSpeech"]
  if comp != null
    for it in *get_ecs_array(*comp)
      let obj = it as Object
      let otherName = get_ecs_string((*obj)["name"])
      if otherName != null
        let otherTime = (*obj).time ?? 10.
        let otherPhraseIdx = find_desc_idx(string(*otherName), speeches)
        if otherPhraseIdx >= 0 && get_sync_time() < get_speech_time(otherPhraseIdx, time) + otherTime
          return true
  return false

def try_speak_impl(phrase_idx : int; desc : Object; var time : FloatList&; team : int; pos : float3; eid : EntityId; importance : float = 1.)
  let phraseType = get_string(desc, "type", "")
  let teamRange = desc.teamRange ?? 0.
  let minMaxTime = desc.minMaxTime ?? float2(0., 0.)
  let curTime = get_sync_time()
  let speechTime = get_speech_time(phrase_idx, time)
  if curTime < speechTime + minMaxTime.x
    return
  var teamSpeechTime : float = speechTime
  if teamRange > 0. && is_alone(phrase_idx, eid, pos, team, teamRange, teamSpeechTime)
    return // there is no friends around to complain to :(
  let teamSpeechInterval = curTime - teamSpeechTime
  if teamSpeechInterval < minMaxTime.x
    return
  if importance <= cvt(teamSpeechInterval, minMaxTime.x, minMaxTime.y, 1., 0.)
    return
  set_speech_time(phrase_idx, curTime, time)
  if phraseType == "possessed"
    send_net_event(eid, [[CmdHumanSpeechForAnySpecificPlayer phraseIdx=phrase_idx, time=curTime]], target_entity_conn(eid))
  elif phraseType == "hero"
    send_net_event(eid, [[CmdHumanSpeechForHero phraseIdx=phrase_idx, time=curTime]], target_entity_conn(eid))
  elif phraseType == "squad"
    send_net_event(eid, [[CmdHumanSpeechForAnySpecificPlayer phraseIdx=phrase_idx, time=curTime]], target_entity_squad(eid))
  elif phraseType == "vehicle"
    send_net_event(eid, [[CmdHumanSpeechForAnySpecificPlayer phraseIdx=phrase_idx, time=curTime]], target_entity_vehicle(eid))
  elif phraseType == "team"
    send_net_event(eid, [[CmdHumanSpeechForAnySpecificPlayer phraseIdx=phrase_idx, time=curTime]], target_entity_pos_range_team(eid))
  elif phraseType == "chat"
    send_net_event(eid, [[CmdHumanQuickChatSpeech phraseIdx=phrase_idx, time=curTime]]) // for bypass team range distance
  elif phraseType == ""
    send_net_event(eid, [[CmdHumanSpeech phraseIdx=phrase_idx, time=curTime]], target_entity_pos_range(eid))
  else
    logerr("unknown speech phraseType {phraseType}")


def take_a_chance(chance : int)
  return chance >= rnd_int(0, 100)

[es(tag=server)]
def human_net_speech_request(evt : CmdRequestHumanSpeech;
                             eid : EntityId;
                             [[shared_comp]] human_speech__speeches : Array;
                             var human_net_speech__time : FloatList&;
                             team : int = TEAM_UNASSIGNED;
                             transform : float3x4;
                             isAlive, isDowned : bool)
  if isAlive && (!isDowned || evt.phrase == "coverme")
    let phraseIdx = find_desc_idx(evt.phrase, human_speech__speeches)
    let desc = get_desc(phraseIdx, human_speech__speeches)
    if desc != null && take_a_chance((*desc).chance ?? 100) && !is_disable_after_prev_speech(*desc, human_speech__speeches, human_net_speech__time)
      try_speak_impl(phraseIdx, *desc, human_net_speech__time, team, transform[3], eid, evt.importance)

def try_speak(phrase : string; speeches : Array; var time : FloatList&; team : int; pos : float3; eid : EntityId; importance : float = 1.)
  let phraseIdx = find_desc_idx(phrase, speeches)
  let desc = get_desc(phraseIdx, speeches)
  if desc != null && take_a_chance((*desc).chance ?? 100) && !is_disable_after_prev_speech(*desc, speeches, time)
    try_speak_impl(phraseIdx, *desc, time, team, pos, eid, importance)
  elif desc == null
    sound_debug("can not speak phrase '{phrase}' because no such phrase")
