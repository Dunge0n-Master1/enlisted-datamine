import "%dngscripts/ecs.nut" as ecs
let {EventTeamRoundResult} = require("dasevents")
let {isNoBotsMode} = require("%enlSqGlob/missionType.nut")
let calcSoldierScore = require("%scripts/game/utils/calcSoldierScore.nut")

let playerContributionToVictoryQuery = ecs.SqQuery("playerContributionToVictoryQuery", {
  comps_rw = [["scoring_player__contributionToVictory", ecs.TYPE_FLOAT], ["soldierStats", ecs.TYPE_OBJECT]]
})
let aliveSoldiersQuery = ecs.SqQuery("aliveSoldiersQuery", {
  comps_no = ["deadEntity"],
  comps_ro = [["guid", ecs.TYPE_STRING], ["squad_member__playerEid", ecs.TYPE_EID], ["team", ecs.TYPE_INT]]
})

ecs.register_es("award_contribution_to_victory",
  {
    [EventTeamRoundResult] = function(evt, _, __) { // broadcast
      let isNoBots = isNoBotsMode()
      aliveSoldiersQuery(function(_, soldier) {
        if (evt.isWon != (evt.team == soldier.team))
          return // is not winning team
        playerContributionToVictoryQuery(soldier.squad_member__playerEid, function(_, player) {
          if (!(soldier.guid in player.soldierStats))
            return
          let previousLifeScore = player.soldierStats?[soldier.guid].previousLifeScore ?? 0
          let currentScore = calcSoldierScore(player.soldierStats[soldier.guid] ?? {}, isNoBots)
          let contributionToVictory = currentScore - previousLifeScore
          player.soldierStats[soldier.guid].contributionToVictory <- contributionToVictory
          player.scoring_player__contributionToVictory = max(player.scoring_player__contributionToVictory, contributionToVictory)
        })
      })
    }
  },
  {},
  {tags="server", before="send_battle_result_es"})
