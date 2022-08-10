require ecs
require app
require game.events_game
require game.utils.team
require enlisted.events_enlisted

[es(tag=server, on_event=EventTeamRoundResult)]
def disable_fail_timer_game_ended(evt : Event; var team__isGameFinished : bool&)
  team__isGameFinished = true

[es(tag=server, track=(team__score, team__isGameFinished, team__isFailTimerStoppedByCapzone))]
def set_team_fail_timer(evt : Event;
                        team__score : float;
                        team__zeroScoreFailTimer : float;
                        team__isFailTimerStoppedByCapzone : bool;
                        team__isGameFinished : bool;
                        var team__failEndTime : float&)
  if team__zeroScoreFailTimer < 0.
    return
  let isTimerNeeded = !team__isGameFinished && team__score <= 0. && !team__isFailTimerStoppedByCapzone

  if isTimerNeeded
    if team__failEndTime <= 0.
      team__failEndTime = get_sync_time() + team__zeroScoreFailTimer
  else
    team__failEndTime = 0.

[es(tag=server, no_order)]
def check_team_fail_timer(info : UpdateStageInfoAct;
                          team__id : int;
                          team__failEndTime : float;
                          var team__isGameFinished : bool&)
  if team__failEndTime > 0. && info.curTime > team__failEndTime && !team__isGameFinished
    team__isGameFinished = true
    broadcastEvent([[EventTeamLost team=team__id]])


[es(tag=server, track=team__score)]
def fail_timer_team_on_zero_spawn_score_es(evt : Event; team__score : float; team__squadSpawnCost : int; var team__squadsCanSpawn : bool&)
  if team__squadSpawnCost > 0
    team__squadsCanSpawn = team__score > 0.


def is_fail_timer_stopped_by_capzone(team : int)
  return find_query() <| $ [es(REQUIRE=capzone)] (active : bool;
                                                  capzone__owningTeam : int = TEAM_UNASSIGNED;
                                                  capzone__curTeamDominating : int = TEAM_UNASSIGNED;
                                                  capzone__curTeamCapturingZone : int = TEAM_UNASSIGNED;
                                                  capzone__stopFailTimerForTeam : int = TEAM_UNASSIGNED;
                                                  bomb_site__plantingTeam : int = TEAM_UNASSIGNED;
                                                  bomb_site__isBombPlanted : bool = false)
    return active && (
      capzone__stopFailTimerForTeam == team ||
      capzone__owningTeam == team ||
      capzone__curTeamCapturingZone == team ||
      capzone__curTeamDominating == team ||
      (bomb_site__isBombPlanted && bomb_site__plantingTeam == team))

def check_team_fail_timer_stopped_by_zone()
  query() <| $ [es] (team__id : int; team__zeroScoreFailTimer : float; var team__isFailTimerStoppedByCapzone : bool&)
    if team__zeroScoreFailTimer >= 0.
      team__isFailTimerStoppedByCapzone = is_fail_timer_stopped_by_capzone(team__id)

[es(tag=server, on_appear, on_disappear, track=(active, capzone__owningTeam, capzone__stopFailTimerForTeam), REQUIRE=(active, capzone__owningTeam, capzone__stopFailTimerForTeam))]
def fail_timer_track_capzone_status_es(evt : Event)
  check_team_fail_timer_stopped_by_zone()

[es(tag=server, track=capzone__curTeamDominating, REQUIRE=capzone__curTeamDominating)]
def fail_timer_track_capzone_domination(evt : Event)
  check_team_fail_timer_stopped_by_zone()

[es(tag=server, track=capzone__curTeamCapturingZone, REQUIRE=capzone__curTeamCapturingZone)]
def fail_timer_track_capzone_capturing(evt : Event)
  check_team_fail_timer_stopped_by_zone()

[es(tag=server, track=bomb_site__isBombPlanted, REQUIRE=bomb_site__isBombPlanted)]
def fail_timer_track_capzone_bomb_planted(evt : Event)
  check_team_fail_timer_stopped_by_zone()
