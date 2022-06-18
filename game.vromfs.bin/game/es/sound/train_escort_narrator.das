require ecs
require enlisted.events_enlisted
//require DagorSystem
require game.utils.team
require game.es.stat_bq_common


[es(tag=sound, track=(train_escort_narrator__teamOffensePresence, train_escort_narrator__teamDefensePresence))]
def train_escort_narrator_on_team_presence(evt : Event;
                                           train_escort_narrator__teamOffensePresence : int;
                                           train_escort_narrator__teamDefensePresence : int;
                                           var train_escort_narrator__prevTeamOffensePresence : int&;
                                           var train_escort_narrator__prevTeamDefensePresence : int&)

  let offense = train_escort_narrator__teamOffensePresence
  let defense = train_escort_narrator__teamDefensePresence
  let prevOffense = train_escort_narrator__prevTeamOffensePresence
  let prevDefense = train_escort_narrator__prevTeamDefensePresence

  //logerr("offense={offense} defense={defense}")

  let wasOffence = prevOffense != -1
  let wasDefense = prevDefense != -1
  let hasOffence = offense != -1
  let hasDefense = defense != -1

  if hasOffence && wasDefense && !hasDefense
    broadcastEvent([[CmdTeamStartNarrator team=offense, phrase="trainCaptured", replace=false]])
    //logerr("trainCaptured offense team={offense}")
  elif hasDefense && wasOffence && !hasOffence
    broadcastEvent([[CmdTeamStartNarrator team=defense, phrase="trainCaptured", replace=false]])
    //logerr("trainCaptured defense team={defense}")
  elif hasOffence && !wasOffence
    broadcastEvent([[CmdTeamStartNarrator team=offense, phrase="trainCapturing", replace=false]])
    //logerr("trainCapturing offense team={offense}")
  elif hasDefense && !wasDefense
    broadcastEvent([[CmdTeamStartNarrator team=defense, phrase="trainCapturing", replace=false]])
    //logerr("trainCapturing defense team={defense}")

  train_escort_narrator__prevTeamOffensePresence = offense
  train_escort_narrator__prevTeamDefensePresence = defense
