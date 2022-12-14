require ecs
require game.utils.team
require enlisted.events_enlisted
require EnlistedNet

[es(tag=server, on_event=ParallelUpdateFrameDelayed, no_order)]
def train_escort_net_narrator(evt : Event;
                              train__teamOffense : int;
                              train__teamDefense : int;
                              var train_escort_narrator__teamOffensePresence : int&;
                              var train_escort_narrator__teamDefensePresence : int&)
  train_escort_narrator__teamOffensePresence = -1
  train_escort_narrator__teamDefensePresence = -1
  query() <| $ [es] (teamPresence : Object)
    let offense = get_ecs_array(teamPresence, "{train__teamOffense}")
    let defense = get_ecs_array(teamPresence, "{train__teamDefense}")
    train_escort_narrator__teamOffensePresence = offense != null && length(*offense) > 0 ? train__teamOffense : -1
    train_escort_narrator__teamDefensePresence = defense != null && length(*defense) > 0 ? train__teamDefense : -1
    if train_escort_narrator__teamOffensePresence == TEAM_UNASSIGNED
      train_escort_narrator__teamOffensePresence = -1
    if train_escort_narrator__teamDefensePresence == TEAM_UNASSIGNED
      train_escort_narrator__teamDefensePresence = -1


[es(tag=server, track=(train_escort_narrator__teamOffensePresence, train_escort_narrator__teamDefensePresence))]
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
    broadcast_net_event([[CmdTeamStartNarrator team=offense, phrase="trainCaptured", replace=false]])
    //logerr("trainCaptured offense team={offense}")
  elif hasDefense && wasOffence && !hasOffence
    broadcast_net_event([[CmdTeamStartNarrator team=defense, phrase="trainCaptured", replace=false]])
    //logerr("trainCaptured defense team={defense}")
  elif hasOffence && !wasOffence
    broadcast_net_event([[CmdTeamStartNarrator team=offense, phrase="trainCapturing", replace=false]])
    //logerr("trainCapturing offense team={offense}")
  elif hasDefense && !wasDefense
    broadcast_net_event([[CmdTeamStartNarrator team=defense, phrase="trainCapturing", replace=false]])
    //logerr("trainCapturing defense team={defense}")

  train_escort_narrator__prevTeamOffensePresence = offense
  train_escort_narrator__prevTeamDefensePresence = defense

