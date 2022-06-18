from "%enlSqGlob/ui_library.nut" import *

let { userstatUnlocks } = require("%enlSqGlob/userstats/userstat.nut")
let { allUnlocks } = require("%enlSqGlob/userstats/unlocksState.nut")

const RANK_UNLOCK = "player_military_rank_unlock"

let rankUnlock = Computed(function() {
  let rankUnlock = allUnlocks.value?[RANK_UNLOCK]
  if (rankUnlock == null)
    return null

  local rankState = []
  rankUnlock.stages.each(@(stage, idx) stage.progress >= rankUnlock.meta.godRating ? null
    : rankState.append({
        progress = stage.progress / 100
        ratingOnNextSeason = rankUnlock.meta.ratingOnNextSeason[idx]
        index = idx + 1
      })
  )

  let ranksQuantity = rankState.len()
  allUnlocks.value
    .each(function(unlock) {
      let { rank_unlock = 0 } = unlock?.meta
      if (rank_unlock != 0 && rank_unlock <= ranksQuantity){
        rankState[rank_unlock - 1].rewardLocId <- unlock.name
      }
    })

  return rankState
})

let playerRank = Computed(function() {
  let ratingInfo = userstatUnlocks.value?.unlocks[RANK_UNLOCK]
  let { stage = 0, progress = 0, nextStage = 0 } = ratingInfo
  if (stage == 0)
    return null

  return {
    rank = stage
    rating = progress
    nextRank = nextStage
  }
})

return {
  playerRank
  rankUnlock
}