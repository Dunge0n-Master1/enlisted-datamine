module narrator_common shared
require ecs
require game.utils.team
require enlisted.events_enlisted

def private play_narrator_text_event(event : string; text : string; is_ally : bool)
  if event != ""
    broadcastEvent([[CmdShowNarratorMessage event=event, text=text, myTeamScores=is_ally]])

def try_play_narrator(phrase : string)
  var isPhraseExist = false
  let heroTeam = get_local_player_team()
  find_query() <| $ [es] (team__id : int; team__narrator : Object)
    if team__id != heroTeam
      return false
    if team__narrator[phrase] != null
      isPhraseExist = true
      broadcastEvent([[CmdStartNarrator phrase=phrase, replace=false]])
    return true
  return isPhraseExist

def play_narrator_major_event(event : string; text : string; is_ally : bool; phrase : string = "")
  try_play_narrator(phrase)
  play_narrator_text_event(event, text, is_ally)

def try_play_narrator_major_event(event : string; text : string; is_ally : bool; phrase : string = "")
  if !try_play_narrator(phrase)
    return false
  play_narrator_text_event(event, text, is_ally)
  return true
