from "%enlSqGlob/ui_library.nut" import *

let { TEAM0_COLOR_FG, TEAM1_COLOR_FG} = require("%ui/hud/style.nut")
let { WARNING_PRIORITIES, addWarnings, warningUpdate } = require("%ui/hud/state/warnings.nut")
let { myScore, enemyScore, myTeamCanLoseByScore, enemyTeamCanLoseByScore } = require("team_scores.nut")
let { debriefingShow } = require("%ui/hud/state/debriefingStateInBattle.nut")

const WE_LEAD = "score/weLead"
const ENEMY_LEAD = "score/enemyLead"
const WE_HALF = "score/weHalf"
const ENEMY_HALF = "score/enemyHalf"
const WE_LOW = "score/weLow"
const ENEMY_LOW = "score/enemyLow"

let positiveMessage = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10, color = TEAM0_COLOR_FG }
let negativeMessage = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10, color = TEAM1_COLOR_FG }

addWarnings({
  [WE_LEAD] = positiveMessage,
  [ENEMY_LEAD] = negativeMessage,
  [WE_HALF] = negativeMessage,
  [ENEMY_HALF] = positiveMessage,
  [WE_LOW] = negativeMessage,
  [ENEMY_LOW] = positiveMessage,
})

let state = keepref(Computed(function() {
  let my = myScore.value ?? 0
  let enemy = enemyScore.value ?? 0
  let isScoreCompetition = myTeamCanLoseByScore.value && enemyTeamCanLoseByScore.value
  return {
    inited             = my > 0 && enemy > 0
    list = {
      [WE_LEAD]        = isScoreCompetition && 0.9 * my >= enemy,
      [ENEMY_LEAD]     = isScoreCompetition && my <= 0.9 * enemy,
      [WE_HALF]        = myTeamCanLoseByScore.value && my <= 0.5,
      [ENEMY_HALF]     = enemyTeamCanLoseByScore.value && enemy <= 0.5,
      [WE_LOW]         = myTeamCanLoseByScore.value && my <= 0.1,
      [ENEMY_LOW]      = enemyTeamCanLoseByScore.value && enemy <= 0.1,
    }
  }
}))
local prevState = state.value

state.subscribe(function(newState) {
  if (newState.inited && prevState.inited && !debriefingShow.value)
    foreach (id, value in newState.list)
      if (value != prevState.list[id])
        warningUpdate(id, value)
  prevState = newState
})

debriefingShow.subscribe(@(_v) state.value.list.each(@(_, id) warningUpdate(id, false)))
