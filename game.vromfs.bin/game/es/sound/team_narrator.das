require ecs
require soundEvent
require game.es.sound.sound_events
require enlisted.events_enlisted
require game.events_game
require game.utils.hero
require game.utils.team
require app
//require DagorSystem


def start_narrator(phrase : string;
                   path : string;
                   replace : bool;
                   cooldown : float;
                   var narrator_sound_event : SoundEvent&;
                   var narrator_history : Object&)
  //logerr("start_narrator={phrase}, path={path}")
  if replace || !is_playing(narrator_sound_event.handle)
    if cooldown > 0.
      let lastTime = get_float(narrator_history, phrase) ?? 0.
      if lastTime > 0. && get_sync_time() < lastTime + cooldown
        return
      narrator_history |> set(phrase, get_sync_time())
    release(narrator_sound_event.handle)
    narrator_sound_event |> play(path)


def start_narrator(phrase : string;
                   pathId : string;
                   team__narrator : Object;
                   replace : bool;
                   var narrator_sound_event : SoundEvent&;
                   var narrator_history : Object&)
  let childComp = team__narrator[phrase]
  let obj = childComp != null ? get_ecs_object(*childComp) : null
  let path = obj != null ? get_ecs_string(*obj, pathId) : null
  if path != null
    start_narrator(phrase, string(*path), replace, get_float(*obj, "cooldown") ?? 0., narrator_sound_event, narrator_history)


def start_narrator(phrase : string;
                   replace : bool;
                   var narrator_sound_event : SoundEvent&;
                   var narrator_history : Object&;
                   narrator_team : int)
  find_query() <| $ [es] (team__id : int;
                          team__narrator : Object)
    if team__id == narrator_team
      start_narrator(phrase, "path", team__narrator, replace, narrator_sound_event, narrator_history)
      return true
    return false


[es(tag=sound)]
def team_narrator_start(evt : CmdStartNarrator; var narrator_sound_event : SoundEvent&; var narrator_history : Object&)
  let localPlayerTeam = get_local_player_team()
  start_narrator(evt.phrase, evt.replace, narrator_sound_event, narrator_history, localPlayerTeam)

[es(tag=sound)]
def team_narrator_round_result(evt : EventTeamRoundResult; var narrator_sound_event : SoundEvent&; var narrator_history : Object&)
  let localPlayerTeam = get_local_player_team()
  if evt.team == localPlayerTeam
    start_narrator(evt.isWon ? "win" : "lose", true, narrator_sound_event, narrator_history, localPlayerTeam)

[es(tag=sound)]
def team_narrator_low_score(evt : EventTeamLowScore; var narrator_sound_event : SoundEvent&; var narrator_history : Object&)
  let localPlayerTeam = get_local_player_team()
  if localPlayerTeam == evt.teamId
    start_narrator("weLoosingScores", false, narrator_sound_event, narrator_history, localPlayerTeam)
  elif !is_teams_friendly(localPlayerTeam, evt.teamId)
    start_narrator("theyLoosingScores", false, narrator_sound_event, narrator_history, localPlayerTeam)

[es(tag=sound)]
def team_narrator_lose_half_score(evt : EventTeamLoseHalfScore; var narrator_sound_event : SoundEvent&; var narrator_history : Object&)
  let localPlayerTeam = get_local_player_team()
  if localPlayerTeam == evt.teamId
    start_narrator("weLoseHalfScores", false, narrator_sound_event, narrator_history, localPlayerTeam)
  elif !is_teams_friendly(localPlayerTeam, evt.teamId)
    start_narrator("theyLoseHalfScores", false, narrator_sound_event, narrator_history, localPlayerTeam)

[es(tag=sound)]
def team_narrator_cmd_team_start(evt : CmdTeamStartNarrator;
                                 team__id : int;
                                 team__narrator : Object)
  if team__id == get_local_player_team()
    ecs::query() <| $ [es] (var narrator_sound_event : SoundEvent&; var narrator_history : Object&)
      start_narrator(evt.phrase, is_teams_friendly(evt.team, team__id) ? "ally" : "enemy", team__narrator, evt.replace, narrator_sound_event, narrator_history)
