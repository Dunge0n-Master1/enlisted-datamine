require ecs
require ecs.safe
require soundEvent
require game.es.sound.sound_events
require enlisted.events_enlisted
require game.events_game
require game.utils.hero
require game.utils.team
require app
require strings
require DagorSystem


def need_cooldown(cooldown : float; phrase : string; is_ally, has_path : bool; narrator_history : Object)
  if cooldown > 0.
    let key = is_ally || !has_path ? phrase : "{phrase}_enemy"
    let lastTime = get_float(narrator_history[key]) ?? -1.
    return lastTime >= 0. && get_sync_time() < lastTime + cooldown
  return false


def add_to_history(phrase : string; is_ally, has_path : bool; var narrator_history : Object&)
  let key = is_ally || !has_path ? phrase : "{phrase}_enemy"
  narrator_history |> set(key, get_sync_time())


def start_narrator_impl(phrase : string;
                        is_ally : bool;
                        team__narrator : Object;
                        var narrator_history : Object&;
                        var narrator_sound_event : SoundEvent&)
  let obj = team__narrator[phrase] ?as Object
  if obj != null
    let hasPath = has(*obj, "path")
    let path = hasPath ? (*obj).path ?? "" : get_string(*obj, is_ally ? "ally" : "enemy", "")
    if !empty(path)
      add_to_history(phrase, is_ally, hasPath, narrator_history)
      release(narrator_sound_event.handle)
      narrator_sound_event |> play(path)


def start_narrator(phrase : string;
                   is_ally : bool;
                   replace : bool;
                   team_id : int;
                   var narrator_sound_event : SoundEvent&;
                   var narrator_queue : Array&;
                   var narrator_history : Object&)

  find_query() <| $ [es] (team__id : int; team__narrator : Object)
    if team__id != team_id
      return false
    let obj = team__narrator[phrase] ?as Object
    if obj == null
      return true
    if need_cooldown((*obj).cooldown ?? 0., phrase, is_ally, has(*obj, "path"), narrator_history)
      return true

    if replace
      release(narrator_sound_event.handle)
      narrator_queue |> clear()

    if length(narrator_queue) == 0 && narrator_sound_event.handle == invalid_sound_event_handle()
      start_narrator_impl(phrase, is_ally, team__narrator, narrator_history, narrator_sound_event)
    else
      using() <| $(var item : Object#)
        item |> set("phrase", phrase)
        item |> set("isAlly", is_ally)
        item |> set("teamId", team_id)
        narrator_queue |> push(item)

    return true


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, no_order)]
def team_narrator_update(evt : Event;
                         var narrator_sound_event : SoundEvent&;
                         var narrator_queue : Array&;
                         var narrator_history : Object&)
  if narrator_sound_event.handle != invalid_sound_event_handle() && !is_playing(narrator_sound_event.handle)
    release(narrator_sound_event.handle)

    if length(narrator_queue) > 0
      let obj = narrator_queue[0] as Object
      if obj != null
        let phrase = (*obj).phrase ?? ""
        let teamId = (*obj).teamId ?? -1
        let isAlly = (*obj).isAlly ?? false
        find_query() <| $ [es] (team__id : int; team__narrator : Object)
          if teamId == team__id
            start_narrator_impl(phrase, isAlly, team__narrator, narrator_history, narrator_sound_event)
            return true
          return false
      erase(narrator_queue, 0)


[es(tag=sound)]
def team_narrator_cmd_team_start(evt : CmdTeamStartNarrator;
                                 team__id : int)
  if team__id == get_local_player_team()
    ecs::query() <| $ [es] (var narrator_sound_event : SoundEvent&; var narrator_queue : Array&; var narrator_history : Object&)
      start_narrator(evt.phrase, is_teams_friendly(evt.team, team__id), evt.replace, team__id, narrator_sound_event, narrator_queue, narrator_history)


[es(tag=sound)]
def team_narrator_start(evt : CmdStartNarrator; var narrator_sound_event : SoundEvent&; var narrator_queue : Array&; var narrator_history : Object&)
  let isOurTeam = true
  start_narrator(evt.phrase, isOurTeam, evt.replace, get_local_player_team(), narrator_sound_event, narrator_queue, narrator_history)


[es(tag=sound)]
def team_narrator_round_result(evt : EventTeamRoundResult; var narrator_sound_event : SoundEvent&; var narrator_queue : Array&; var narrator_history : Object&)
  let isOurTeam = evt.team == get_local_player_team()
  if isOurTeam
    let replace = true
    start_narrator(evt.isWon ? "win" : "lose", isOurTeam, replace, evt.team, narrator_sound_event, narrator_queue, narrator_history)

[es(tag=sound)]
def team_narrator_low_score(evt : EventTeamLowScore; var narrator_sound_event : SoundEvent&; var narrator_queue : Array&; var narrator_history : Object&)
  let localPlayerTeam = get_local_player_team()
  let isAllies = is_teams_friendly(localPlayerTeam, evt.teamId)
  let replace = false
  start_narrator("loosingScores", isAllies, replace, evt.teamId, narrator_sound_event, narrator_queue, narrator_history)

[es(tag=sound)]
def team_narrator_lose_half_score(evt : EventTeamLoseHalfScore; var narrator_sound_event : SoundEvent&; var narrator_queue : Array&; var narrator_history : Object&)
  let localPlayerTeam = get_local_player_team()
  let isAllies = is_teams_friendly(localPlayerTeam, evt.teamId)
  let replace = false
  start_narrator("loseHalfScores", isAllies, replace, evt.teamId, narrator_sound_event, narrator_queue, narrator_history)
