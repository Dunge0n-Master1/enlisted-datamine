require ecs
require ecs.safe
require app
require EnlistedNet
require strings
require soundSystem
require game.utils.team
require math.base
require DagorMath
require DagorRandom
require DagorSystem
require EnlistedDm
require game.events_game
require game.es.sound_net.sound_net_events
require sound_utils_net.modules.sound_desc_common
require game.utils.net_utils
require common_shooter.events_common_shooter


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


[es(on_event=EventWeapOnReload, tag=server)]
def human_net_speech_reload(evt : Event; eid : EntityId;
                            [[shared_comp]] human_speech__speeches : Array;
                            var human_net_speech__time : FloatList&;
                            team : int = TEAM_UNASSIGNED;
                            transform : float3x4)
  try_speak("reload", human_speech__speeches, human_net_speech__time, team, transform[3], eid)


def is_headshot(dm_parts__type : StringList&; coll_node_id : int)
  return coll_node_id >= 0 && string(dm_parts__type[coll_node_id]) == "head"

def is_concussed(eid : EntityId)
  return get_bool(eid, "hasConcussedSound") ?? false

/*
def is_single_shot(human_eid : EntityId)
  // TODO: need to detect recent shots from human
  let hadRecentShots = true
  if hadRecentShots
    return false
  var gunEid = INVALID_ENTITY_ID
  query(human_eid) <| $ [es] (human_weap__gunEids : EidList;
                              human_weap__curGunSlot : int;
                              human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID)
    if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
      gunEid = human_attached_gun__attachedGunEid
    elif human_weap__curGunSlot >= 0
      gunEid = human_weap__gunEids[human_weap__curGunSlot]

  var burstSize = 0
  query(gunEid) <| $ [es] (gun__firingModeIndex : int;
                           gun__firingModes : Array)
    if gun__firingModeIndex >= 0 && gun__firingModeIndex < length(gun__firingModes)
      let modeObj = get_ecs_object(gun__firingModes[gun__firingModeIndex])
      if modeObj != null
        burstSize = (*modeObj).burstSize ?? 1
  return burstSize == 1
*/

[es(tag=server)]
def human_net_speech_hit(evt : EventOnEntityHit;
                         eid : EntityId;
                         transform : float3x4;
                         isAlive : bool;
                         hitpoints__maxHp : float;
                         human_net_speech__isFarKillThreshold : float = 100.)

  if evt.victim == evt.offender || !isAlive
    return

  if evt.victim != eid && evt.offender != eid
    return

  if evt.hitResult == int(HitResult HIT_RES_NONE)
    return

  assume dd = evt
  if dd.damageType != int(DamageType DM_PROJECTILE) && dd.damageType != int(DamageType DM_EXPLOSION) && dd.damageType != int(DamageType DM_MELEE) && dd.damageType != int(DamageType DM_BACKSTAB)
    return

  let killed = (evt.hitResult == int(HitResult HIT_RES_KILLED)) && !is_concussed(evt.victim)

  if evt.victim == eid
    if !killed && (dd.damageType == int(DamageType DM_PROJECTILE) || dd.damageType == int(DamageType DM_EXPLOSION))
      let importance = saturate(safediv(dd.deltaHp, hitpoints__maxHp))
      sendEvent(evt.victim, [[CmdRequestHumanSpeech phrase="wounded", importance=importance]])

  elif evt.offender == eid
    query(evt.victim) <| $ [es(REQUIRE=human_net_phys)] (hitpoints__maxHp : float; dm_parts__type : StringList&)
      var phrase = "enemyHit"
      if killed
        if dd.damageType == int(DamageType DM_EXPLOSION)
          phrase = "enemyKillExplode"
        elif is_headshot(dm_parts__type, dd.collNodeId)
          phrase = "enemyHeadshot"
        //elif dd.deltaHp >= hitpoints__maxHp && is_single_shot(evt.offender)
        //  phrase = "enemyKillSingleShot"
        elif length_sq(dd.hitPos - transform[3]) > square(human_net_speech__isFarKillThreshold)
          phrase = "enemyKillFar"
        elif (dd.damageType == int(DamageType DM_MELEE))
          phrase = "enemyKillMelee"
        else
          phrase = "enemyKill"

      let importance = saturate(safediv(dd.deltaHp, hitpoints__maxHp))
      sendEvent(evt.offender, [[CmdRequestHumanSpeech phrase=phrase, importance=importance]])
