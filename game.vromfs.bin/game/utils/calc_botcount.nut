import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")

let callBotCountQuery = ecs.SqQuery("callBotCountQuery", {comps_ro = [["team__memberCount", ecs.TYPE_FLOAT], ["team.countAdd", ecs.TYPE_FLOAT],
                                       ["team__id", ecs.TYPE_INT], ["team.botCount", ecs.TYPE_INT, 0], ["team.maxBotsCount", ecs.TYPE_INT, -1],]})
let function calc_team_bot_count(team_id) {
  local maxTeamPlayers = 0
  local maxTeamId = TEAM_UNASSIGNED
  local myTeamPlayers = 0
  local botsCount = 0
  local maxBotsCount = -1
  callBotCountQuery.perform(
    function(_eid, comp) {
      let teamMem = comp["team__memberCount"] - comp["team.countAdd"]
      if (comp["team__id"] == team_id) {
        myTeamPlayers = teamMem
        botsCount = comp["team.botCount"]
        maxBotsCount = comp["team.maxBotsCount"]
      }
      if (teamMem > maxTeamPlayers) {
        maxTeamPlayers = teamMem
        maxTeamId = comp["team__id"]
      }
    })

  if (maxTeamId != team_id && botsCount > 0)
    botsCount = (maxTeamPlayers / max(myTeamPlayers, 1)) * (botsCount + 1) - 1
  if (maxBotsCount >= 0 && botsCount >= 0)
    botsCount = min(botsCount, maxBotsCount)

  return botsCount
}

return calc_team_bot_count
