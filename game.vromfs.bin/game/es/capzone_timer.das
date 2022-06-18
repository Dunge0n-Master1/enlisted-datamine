require ecs
require game.utils.team
require game.events_game
require enlisted.events_enlisted

def get_attack_team(capzone__mustBeCapturedByTeam : int; capzone__onlyTeamCanCapture : int)
  if capzone__onlyTeamCanCapture != TEAM_UNASSIGNED
    return capzone__onlyTeamCanCapture
  return capzone__mustBeCapturedByTeam

[es(tag=server)]
def set_capzone_timer_on_first_spawn(evt : EventFirstPlayerSpawned;
                                     capzone_timer__timeLeft : float;
                                     capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                                     capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                                     var capzone_timer__isSet : bool&)
  let isDefenseZone = get_attack_team(capzone__mustBeCapturedByTeam, capzone__onlyTeamCanCapture) != TEAM_UNASSIGNED
  capzone_timer__isSet = capzone_timer__timeLeft > 0. && isDefenseZone

[es(tag=server, track=active)]
def capzone_timer_disable_timer(evt : Event; active : bool; var capzone_timer__timeLeft : float&)
  if !active
    capzone_timer__timeLeft = -1.

[es(tag=server, no_order)]
def capzone_timer(info : UpdateStageInfoAct;
                  active : bool;
                  capzone_timer__isSet : bool;
                  capzone__isNextTrainZone : bool = false;
                  capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                  capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                  var capzone_timer__timeLeft : float&;
                  var capzone_timer__endTime : float&)
  if !capzone_timer__isSet || (!active && !capzone__isNextTrainZone) || capzone_timer__timeLeft <= 0.
    capzone_timer__endTime = -1.
    return
  if capzone_timer__endTime < 0.
    capzone_timer__endTime = info.curTime + capzone_timer__timeLeft

  capzone_timer__timeLeft -= info.dt

  if capzone_timer__timeLeft <= 0.
    let attackTeam = get_attack_team(capzone__mustBeCapturedByTeam, capzone__onlyTeamCanCapture)
    if attackTeam != TEAM_UNASSIGNED
      broadcastEvent([[EventTeamLost team=attackTeam]])

[es(tag=server, track=capzone_timer__endTime, REQUIRE=capzone_timer__endTime)]
def capzone_timer_set_end_time_for_team(evt : Event;
                                        capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                                        capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED)
  let attackTeam = get_attack_team(capzone__mustBeCapturedByTeam, capzone__onlyTeamCanCapture)
  find_query() <| $ [es] (team__id : int; var team__capzoneTimerEndTime : float&)
    if team__id != attackTeam
      return false
    var endTime = -1.
    query() <| $ [es] (capzone_timer__endTime : float;
                       capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                       capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED)
      let capzoneAttackTeam = get_attack_team(capzone__mustBeCapturedByTeam, capzone__onlyTeamCanCapture)
      if (capzone_timer__endTime >= 0. && (endTime < 0. || capzone_timer__endTime < endTime)) && attackTeam == capzoneAttackTeam
        endTime = capzone_timer__endTime
    team__capzoneTimerEndTime = endTime
    return true