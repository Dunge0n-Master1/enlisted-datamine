require ecs
require game.utils.team
require game.events_game
require enlisted.events_enlisted


[es(tag=server)]
def team_on_death_es(evt : EventAnyEntityDied;
                     team__id : int;
                     team__memberEids : EidList;
                     team__zeroScoreFailTimer : float;
                     team__deathPenalty : float;
                     team__deathPenaltyByMember : float = 0.0;
                     team__minDeathPenalty : float = 0.0;
                     var team__score : float&)
  let victimEid = evt.victim
  let victimTeamId = get_int(victimEid, "team") ?? TEAM_UNASSIGNED

  if victimTeamId != team__id
    return

  let addDeathPenalty = float(length(team__memberEids)) * team__deathPenaltyByMember
  let deathPenalty = max(team__deathPenalty + addDeathPenalty, team__minDeathPenalty)

  if deathPenalty > 0.0
    if deathPenalty >= team__score
      team__score = 0.0
      if team__zeroScoreFailTimer < 0.0
        broadcastEvent([[EventTeamLost team=team__id]])
        return
    else
      team__score -= deathPenalty

  if team__zeroScoreFailTimer > 0.0 && team__score <= 0.0
    let isAliveTeamMemberFound = find_query() <| $ [es(REQUIRE=countAsAlive)] (team : int; isAlive : bool)
      return isAlive && team == team__id
    if !isAliveTeamMemberFound
      broadcastEvent([[EventTeamLost team=team__id]])
