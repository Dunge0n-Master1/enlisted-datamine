import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {heroSquadNumAliveMembers} = require("%ui/hud/state/hero_squad.nut")
let {warningUpdate, WARNING_PRIORITIES, addWarnings} = require("%ui/hud/state/warnings.nut")
let { debounce } = require("%sqstd/timers.nut")
let {mkCountdownTimerPerSec} = require("%ui/helpers/timers.nut")

let scoresByTeams = Watched({})

let myTeamCanFailByTime = mkWatched(persist, "myTeamCanFailByTime", false)
let canIncreaseScore = mkWatched(persist, "canIncreaseScore", false)

addWarnings({
  waitTeamScores = { priority = WARNING_PRIORITIES.MEDIUM, timeToShow = 10, locId = "respawn/no_spawn_scores" }
  zeroScoreFailTimer     = { priority = WARNING_PRIORITIES.MEDIUM, timeToShow = 10 },
  scoreIsLow             = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10 },
  scoreIsHalf            = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10 },
})

let failTimerShowTime = 180

let myScore = Watched(0)
let myTeamFailTime = Watched(0)
let myScoreBleed = Watched(0)
let myScoreBleedFast = Watched(0)
let myTeamCanLoseByScore = Watched(false)

let enemyScore = Watched(0)
let enemyTeamFailTime = Watched(0)
let enemyScoreBleed = Watched(0)
let enemyScoreBleedFast = Watched(0)
let enemyTeamCanLoseByScore = Watched(false)

let failEndTime = Computed(@()
  enemyTeamFailTime.value > 0 && (myTeamFailTime.value <= 0 || myTeamFailTime.value > enemyTeamFailTime.value)
    ? enemyTeamFailTime.value
    : myTeamFailTime.value
)

let paramsBySideMap = {
  my = {
    score      = myScore
    bleed      = myScoreBleed
    bleedFast  = myScoreBleedFast
    canLoseByScore = myTeamCanLoseByScore
  }
  enemy = {
    score      = enemyScore
    bleed      = enemyScoreBleed
    bleedFast  = enemyScoreBleedFast
    canLoseByScore = enemyTeamCanLoseByScore
  }
}

local isShownZeroScoreWarn = false
let function updateScoreWarning() {
  let isMySquadDead = heroSquadNumAliveMembers.value == 0
  let needZeroScoreWarn = !isMySquadDead && failEndTime.value > 0 && myTeamCanFailByTime.value
  if (needZeroScoreWarn != isShownZeroScoreWarn) {
    warningUpdate("zeroScoreFailTimer", needZeroScoreWarn)
    isShownZeroScoreWarn = needZeroScoreWarn
  }
  warningUpdate("waitTeamScores", isMySquadDead && myTeamCanFailByTime.value && canIncreaseScore.value)
}

let updateScoreWarningDeb = debounce(@(_) updateScoreWarning(), 0.1)
foreach (w in [failEndTime, heroSquadNumAliveMembers, myTeamCanFailByTime, canIncreaseScore])
  w.subscribe(updateScoreWarningDeb)


local scoreIsLowTriggered = false
local scoreIsHalfTriggered = false
let function setScoreParams(teamScores, side) {
  local normScore
  normScore = teamScores["team__scoreCap"] > 0 ? teamScores["team__score"] / teamScores["team__scoreCap"].tofloat() : null
  paramsBySideMap[side].score(normScore)
  paramsBySideMap[side].canLoseByScore(teamScores["team__squadSpawnCost"] > 0 || teamScores["score_bleed__domBleed"] > 0)

  if (teamScores["team__scoreCap"] > 0 && teamScores["team__squadSpawnCost"] > 0 && side == "my") {
    let needWarnLow = normScore <= 0.15
    let needWarnHalf = normScore <= 0.5
    if (scoreIsLowTriggered != needWarnLow) {
      warningUpdate("scoreIsLow", needWarnLow && !scoreIsLowTriggered)
      scoreIsLowTriggered = needWarnLow
    }
    if (scoreIsHalfTriggered != needWarnHalf) {
      warningUpdate("scoreIsHalf", needWarnHalf  && !needWarnLow && !scoreIsHalfTriggered)
      scoreIsHalfTriggered = needWarnHalf
    }
  }
}

let function setBleedParams(teamScores, side) {
  paramsBySideMap[side].bleed(teamScores["score_bleed__domBleedOn"])
  paramsBySideMap[side].bleedFast(teamScores["score_bleed__domBleedOn"] && teamScores["score_bleed__totalDomBleedOn"])
}

let function setFailTime(_){
  foreach (teamId, teamScores in scoresByTeams.value) {
    if (!teamScores["team__haveScores"])
      continue
    local endTime = -1

    if (teamScores.team__capzoneTimerEndTime > 0 && (endTime < 0 || endTime > teamScores.team__capzoneTimerEndTime))
      endTime = teamScores.team__capzoneTimerEndTime
    let teamTime = teamScores["team__failEndTime"]
    if (teamTime > 0 && (endTime < 0 || endTime > teamTime))
      endTime = teamTime

    let side = (teamId == localPlayerTeam.value) ? "my" : "enemy"
    if (side == "my") {
      myTeamCanFailByTime(teamTime > 0)
      myTeamFailTime(endTime)
      canIncreaseScore(teamScores["team__scoreCap"] > 0)
    } else {
      enemyTeamFailTime(endTime)
    }

    setScoreParams(teamScores, side)
    setBleedParams(teamScores, side)
  }
}

foreach (w in [localPlayerTeam, scoresByTeams])
  w.subscribe(setFailTime)

let teamComps = {
  comps_track = [
    ["team__score", ecs.TYPE_FLOAT],
    ["team__squadSpawnCost", ecs.TYPE_INT, 0],
    ["team__failEndTime", ecs.TYPE_FLOAT, 0.0],
    ["team__capzoneTimerEndTime", ecs.TYPE_FLOAT, -1.0],
    ["team__scoreCap", ecs.TYPE_FLOAT],
    ["team__haveScores", ecs.TYPE_BOOL, true],
    ["score_bleed__domBleed", ecs.TYPE_FLOAT, 0.0],
    ["score_bleed__domBleedOn", ecs.TYPE_BOOL],
    ["score_bleed__totalDomBleedOn", ecs.TYPE_BOOL],
  ]
  comps_ro = [
    ["team__id", ecs.TYPE_INT]
  ]
}

let function trackComponents(_evt, _eid, comp) {
  let val = {}
  foreach (compslist in teamComps) {
    foreach (compdesc in compslist)
      val[compdesc[0]] <- comp[compdesc[0]]
  }
  let teamId = comp["team__id"]
  scoresByTeams.mutate(function(scores) {
    scores[teamId] <- val
  })
}


let function onDestroy(_evt, _eid, comp) {
  let teamId = comp["team__id"]
  scoresByTeams.mutate(function(scores) {
    delete scores[teamId]
  })

}


ecs.register_es("team_game_mode_scores_ui_es", {
  [["onChange","onInit"]] = trackComponents
  onDestroy = onDestroy
}, teamComps)

return {
  anyTeamFailTimer = mkCountdownTimerPerSec(failEndTime)
  failTimerShowTime
  myScore
  myScoreBleed
  myScoreBleedFast
  myTeamCanLoseByScore
  enemyScore
  enemyScoreBleed
  enemyScoreBleedFast
  enemyTeamCanLoseByScore
  myTeamFailTimer = mkCountdownTimerPerSec(myTeamFailTime)
  enemyTeamFailTimer = mkCountdownTimerPerSec(enemyTeamFailTime)
}