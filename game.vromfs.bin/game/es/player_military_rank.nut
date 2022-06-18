import "%dngscripts/ecs.nut" as ecs

let { rnd_int } = require("dagor.random")
let { INVALID_USER_ID } = require("matching.errors")
let { logerr } = require("dagor.debug")

let playerRanks = {}
local minRank = 1
local ratingGrid = []
local ratingAnyBattle = 0
local ratingNoPenalty = 0

let function addRank(userId, rank, rating) {
  if (userId == INVALID_USER_ID) {
    logerr("Attempt to set rank for invalid player")
    return
  }
  minRank = min(minRank, rank) // allow noob bots if players without rank have joined
  playerRanks[userId] <- { rank, rating }
}

let getRank = @(userId) playerRanks?[userId].rank ?? 0

let function genBotRank() {
  let ranks = playerRanks.values()
  let ranksSize = ranks.len()
  let maxRank = ranksSize > 0 ? ranks[rnd_int(0, ranksSize - 1)].rank : minRank
  return rnd_int(minRank, maxRank)
}

let function advanceRank(userId, isFinished, isVictory, isBattleHero) {
  if (userId == INVALID_USER_ID || userId not in playerRanks)
    return 0

  local { rating } = playerRanks[userId]
  if (rating <= ratingAnyBattle) {
    rating += isFinished ? 100 : 0
  }
  else if (rating <= ratingNoPenalty) {
    rating += isFinished && isVictory ? 100 : 0
    rating += isFinished && isBattleHero ? 100 : 0
  }
  else {
    rating += !isFinished ? -100 : isVictory ? 100 : -100
    rating += isFinished && isBattleHero ? 100 : 0
  }

  let newRank = ratingGrid.findindex(@(r) rating < r) ?? ratingGrid.len()
  return newRank
}

let function onConfigUpdate(_evt, comp) {
  ratingGrid = comp.ratingGrid.getAll()
  ratingAnyBattle = comp.ratingAnyBattle
  ratingNoPenalty = comp.ratingNoPenalty
}

ecs.register_es("rankConfigUpdater",
  { onInit = onConfigUpdate },
  {
    comps_ro = [
      ["ratingGrid", ecs.TYPE_ARRAY],
      ["ratingAnyBattle", ecs.TYPE_INT],
      ["ratingNoPenalty", ecs.TYPE_INT],
    ]
  },
  { tags = "server" }
)

return {
  addRank
  getRank
  genBotRank
  advanceRank
}