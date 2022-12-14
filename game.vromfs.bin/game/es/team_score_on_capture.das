require ecs
require enlisted.events_enlisted
require game.es.capzones_common
require game.utils.team
require game.events_game
require DagorMath

def get_min_enemy_team_tickets_part(team : int)
  var res = 1.0
  query() <| $ [es] (team__id : int; team__score : float; team__scoreCap : float)
    if team__id != team
      let part = safediv(team__score, team__scoreCap)
      res = min(part, res)
  return res

def on_capture_penalty(team_id : int;
                       capzone__capPenalty : float const?;
                       team__capturePenalty : float;
                       var team__score : float&)
  let capPen = capzone__capPenalty ?? team__capturePenalty

  if capPen != 0.
    if capPen >= team__score
      team__score = 0.
      broadcastEvent([[EventTeamLost team=team_id]])
    else
      team__score -= capPen

def on_capture_reward(team_id : int;
                      capzone__capReward : float;
                      capzone__capRewardTeam1 : float;
                      capzone__capRewardTeam2 : float;
                      team__scoreCap : float;
                      team__minScoreCap : float;
                      capzone__capRewardPartCap : float;
                      var team__score : float&)
  let capReward = (team_id == 1 && capzone__capRewardTeam1 >= 0. ? capzone__capRewardTeam1
      : team_id == 2 && capzone__capRewardTeam2 >= 0. ? capzone__capRewardTeam2
      : capzone__capReward)

  if capReward != 0.
    let minEnemyTeamTicketsPart = get_min_enemy_team_tickets_part(team_id)
    let scoreCap = max(team__minScoreCap, team__scoreCap * min(1.0, minEnemyTeamTicketsPart * capzone__capRewardPartCap))
    team__score += max(min(capReward, scoreCap - team__score), 0.0)

def on_capzone_captured(zone_eid : EntityId; cap_team : int)
  query() <| $ [es] (team__id : int;
                     team__capturePenalty : float;
                     team__scoreCap : float = 0.;
                     team__minScoreCap : float = 0.;
                     var team__score : float&)
    query(zone_eid) <| $ [es(REQUIRE_NOT=capzone__noTeamScore)] (capzone__capPenalty : float const?;
                                                                 capzone__checkAllZonesInGroup : bool = false;
                                                                 capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                                                                 groupName : string = "";
                                                                 capzone__capRewardPartCap : float = 10000.0;
                                                                 capzone__capReward : float = 0.;
                                                                 capzone__capRewardTeam1 : float = -1.;
                                                                 capzone__capRewardTeam2 : float = -1.)
      if (capzone__checkAllZonesInGroup
          && (cap_team != capzone__mustBeCapturedByTeam || !all_capzones_in_group_captured_by_team(zone_eid, cap_team, groupName)))
        return

      if team__id == cap_team
        on_capture_reward(team__id, capzone__capReward, capzone__capRewardTeam1, capzone__capRewardTeam2,
                          team__scoreCap, team__minScoreCap, capzone__capRewardPartCap, team__score)
      else
        on_capture_penalty(team__id, capzone__capPenalty, team__capturePenalty, team__score)


[es(tag=server)]
def team_score_on_capture(evt : EventZoneCaptured)
  on_capzone_captured(evt.zone, evt.team)

[es(tag=server)]
def team_score_on_capture_delayed(evt : EventZoneIsAboutToBeCaptured)
  on_capzone_captured(evt.zone, evt.team)
