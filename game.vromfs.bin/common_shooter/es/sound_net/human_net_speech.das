require ecs
require ecs.safe
require app
require EnlistedNet
require soundSystem
require game.utils.team
require DagorMath
require math.base
require DagorRandom
require DagorSystem
require human_sounds_net.modules.human_sounds_net_events
require sound_utils_net.modules.sound_desc_common
require game.utils.net_utils


def get_speech_last_time(idx : int; human_net_speech__lastNextTime : Point2List)
  return idx < length(human_net_speech__lastNextTime) ? human_net_speech__lastNextTime[idx].x : 0.

def get_speech_next_time(idx : int; human_net_speech__lastNextTime : Point2List)
  return idx < length(human_net_speech__lastNextTime) ? human_net_speech__lastNextTime[idx].y : 0.

def set_speech_time(idx : int; last_time : float; next_time : float; var human_net_speech__lastNextTime : Point2List&)
  assert(uint(idx) < 100u)
  while idx >= length(human_net_speech__lastNextTime)
    push(human_net_speech__lastNextTime, float2(-100., 0.))
  human_net_speech__lastNextTime[idx] = float2(last_time, next_time)


def take_a_chance(chance : int)
  return chance >= rnd_int(0, 100)


def is_alone(phrase_idx : int; cur_eid : EntityId; cur_pos : float3; cur_team : int; max_radius : float; var max_speech_next_time : float&)
  if cur_team == TEAM_UNASSIGNED
    return true
  var isAlone : bool = true
  query() <| $ [es] (eid : EntityId; team : int; transform : float3x4; human_net_speech__lastNextTime : Point2List; isAlive : bool)
    if isAlive && team == cur_team && distance_sq(cur_pos, transform[3]) < square(max_radius)
      max_speech_next_time = max(get_speech_next_time(phrase_idx, human_net_speech__lastNextTime), max_speech_next_time)
      if eid != cur_eid
        isAlone = false
  return isAlone


def should_skip_after_other_speech(desc : Object; speeches : Array; human_net_speech__lastNextTime : Point2List; cur_time : float)
  let comp = desc["skipAfterSpeech"]
  if comp != null
    for it in *get_ecs_array(*comp)
      let obj = it as Object
      let otherName = get_ecs_string((*obj)["name"])
      if otherName != null
        let otherTime = (*obj).time ?? 10.
        let otherPhraseIdx = find_desc_idx(string(*otherName), speeches)
        if otherPhraseIdx >= 0 && cur_time < get_speech_last_time(otherPhraseIdx, human_net_speech__lastNextTime) + otherTime
          return true
  return false


[es(tag=server)]
def human_net_speech_request(evt : CmdRequestHumanSpeech;
                             eid : EntityId;
                             [[shared_comp]] human_speech__speeches : Array;
                             var human_net_speech__lastNextTime : Point2List&;
                             team : int = TEAM_UNASSIGNED;
                             transform : float3x4;
                             isAlive, isDowned : bool)

  if !isAlive || (isDowned && evt.phrase != "coverme")
    return

  let phraseIdx = find_desc_idx(evt.phrase, human_speech__speeches)
  let desc = get_desc(phraseIdx, human_speech__speeches)
  if desc == null || !take_a_chance((*desc).chance ?? 100)
    return

  let curTime = get_sync_time()

  if should_skip_after_other_speech(*desc, human_speech__speeches, human_net_speech__lastNextTime, curTime)
    return

  let teamRange = (*desc).teamRange ?? 0.
  var speechNextTime : float = get_speech_next_time(phraseIdx, human_net_speech__lastNextTime)
  if teamRange > 0. && is_alone(phraseIdx, eid, transform[3], team, teamRange, speechNextTime)
    return // there is no friends around to complain to :(
  if curTime < speechNextTime
    return

  let minMaxCooldown = (*desc).minMaxCooldown ?? float2(0., 0.)
  set_speech_time(phraseIdx, curTime, curTime + rnd_float(minMaxCooldown.x, minMaxCooldown.y), human_net_speech__lastNextTime)

  let eventType = get_string(*desc, "type", "")
  if eventType == "watched"
    send_net_event(eid, [[CmdHumanWatchedSpeech phraseIdx=phraseIdx, time=curTime]], target_entity_conn(eid))
  elif eventType == "chat"
    send_net_event(eid, [[CmdHumanQuickChatSpeech phraseIdx=phraseIdx, time=curTime]]) // for bypass team range distance
  elif eventType == "target"
    send_net_event(eid, [[CmdHumanSpeech phraseIdx=phraseIdx, time=curTime]], target_entity_conn(eid))
  elif eventType == "squad"
    send_net_event(eid, [[CmdHumanSpeech phraseIdx=phraseIdx, time=curTime]], target_entity_squad(eid))
  elif eventType == "vehicle"
    send_net_event(eid, [[CmdHumanSpeech phraseIdx=phraseIdx, time=curTime]], target_entity_vehicle(eid))
  elif eventType == "team"
    send_net_event(eid, [[CmdHumanSpeech phraseIdx=phraseIdx, time=curTime]], target_entity_pos_range_team(eid))
  elif eventType == ""
    send_net_event(eid, [[CmdHumanSpeech phraseIdx=phraseIdx, time=curTime]], target_entity_pos_range(eid))
  else
    logerr("unknown eventType {eventType}")
