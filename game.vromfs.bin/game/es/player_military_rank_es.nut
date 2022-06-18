import "%dngscripts/ecs.nut" as ecs

let userstats = require_optional("userstats")
let dedicated = require_optional("dedicated")

if (userstats == null || dedicated == null)
  return

let { INVALID_USER_ID } = require("matching.errors")
let { addRank, genBotRank } = require("player_military_rank.nut")

const RANK_UNLOCK_ID = "player_military_rank_unlock"

let playerRankQuery = ecs.SqQuery("playerRankQuery", {
  comps_rw = [
    ["player_info__military_rank", ecs.TYPE_INT],
    ["player_info__rating", ecs.TYPE_INT],
  ]
})

let setPlayerRank = @(eid, rank, rating) playerRankQuery.perform(eid, function(_, comp) {
  comp["player_info__military_rank"] = rank
  comp["player_info__rating"] = rating
})

let rankConfigQuery = ecs.SqQuery("rankConfigQuery", {
  comps_rw = [
    ["ratingGrid", ecs.TYPE_ARRAY],
    ["ratingAnyBattle", ecs.TYPE_INT],
    ["ratingNoPenalty", ecs.TYPE_INT],
  ]
})

let function setRankConfig(ratingGrid, ratingAnyBattle, ratingNoPenalty) {
  local found = false
  rankConfigQuery(function (_eid, comp) {
    found = true
    comp.ratingGrid = ratingGrid
    comp.ratingAnyBattle = ratingAnyBattle
    comp.ratingNoPenalty = ratingNoPenalty
  })

  if (!found)
    ecs.g_entity_mgr.createEntity("military_ranks_config", {
      ratingGrid = [ratingGrid, ecs.TYPE_ARRAY]
      ratingAnyBattle = [ratingAnyBattle, ecs.TYPE_INT]
      ratingNoPenalty = [ratingNoPenalty, ecs.TYPE_INT]
    })
}

let function onPlayerConnected(eid, comp) {
  let { appId = 0, userid = INVALID_USER_ID, playerIsBot = null } = comp
  if (playerIsBot != null) {
    setPlayerRank(eid, genBotRank(), 0)
    return
  }

  if (appId == 0 || userid == INVALID_USER_ID)
    return

  userstats.request({
    headers = { appId, userid }
    data = {
      unlocks = [RANK_UNLOCK_ID]
      withMeta = true
    }
    action = "AdmGetUnlocks"
  }, function(result) {
    let unlock = result?.response.unlocks[RANK_UNLOCK_ID]
    if (unlock) {
      let { ratingRequired = [], privateMaxRating = 0, sergeantMaxRating = 0 } = unlock?.meta
      setRankConfig(ratingRequired, privateMaxRating, sergeantMaxRating)

      let { stage, progress } = unlock
      setPlayerRank(eid, stage, progress)
      addRank(userid, stage, progress)
    }
  })
}

ecs.register_es("update_player_military_rank_es", {
  onInit = onPlayerConnected,
}, {
  comps_ro = [
    ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
    ["appId", ecs.TYPE_INT],
    ["playerIsBot", ecs.TYPE_TAG, null]
  ]
  comps_rq = ["player"]
})