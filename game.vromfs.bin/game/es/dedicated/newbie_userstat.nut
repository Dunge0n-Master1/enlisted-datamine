import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let dedicated = require_optional("dedicated")
let userstats = require_optional("userstats")

let {INVALID_USER_ID} = require("matching.errors")
let {logerr} = require("dagor.debug")

if (dedicated == null || userstats == null)
  return

const NEWBIE_KILLS_UNLOCK = "new_player_boost_kills"
const NEWBIE_BATTLES_UNLOCK = "new_player_boost_battles"

let newbiePlayerQuery = ecs.SqQuery("newbiePlayerQuery", {
  comps_rw = [
    ["newbie__baseKillCount", ecs.TYPE_INT],
    ["newbie__killCountMax", ecs.TYPE_INT],
  ]
})

let function applyNewbieDamageBoost(eid, progress, nextStage, battle, totalBattles) {
  newbiePlayerQuery(eid, function (_eid, comp) {
    comp.newbie__baseKillCount = progress
    comp.newbie__killCountMax = nextStage
    log($"New player boost applied for player {eid} (kills: {progress}/{nextStage} battles : {battle}/{totalBattles})")
  })
}

let function isFinished(unlock) {
  let { stage = 0, nextStage = 0, progress = 0 } = unlock
  return stage > 0 || progress >= nextStage
}

let function onPlayerConnected(eid, comp) {
  let { appId = 0, userid = INVALID_USER_ID } = comp
  if (appId == 0 || userid == INVALID_USER_ID)
    return
  userstats.request({
    headers = { appId, userid }
    data = {
      withUnprogressed = true,
      unlocks = [NEWBIE_KILLS_UNLOCK, NEWBIE_BATTLES_UNLOCK]
    }
    action = "AdmGetUnlocks"
  }, function(result) {
    let isSuccess = result?.response?.success ?? true
    if (!isSuccess)
      logerr("Error during newbie unlock request {0}".subst(result?.response?.error ?? "unknown error"))
    let unlockKills = result?.response.unlocks[NEWBIE_KILLS_UNLOCK]
    let unlockBattles = result?.response.unlocks[NEWBIE_BATTLES_UNLOCK]

    if (!isFinished(unlockKills) && !isFinished(unlockBattles)) {
      let { nextStage = 0, progress = 0 } = unlockKills
      let battle = unlockBattles?.progress ?? 0
      let totalBattles = unlockBattles?.nextStage ?? 0
      applyNewbieDamageBoost(eid, progress, nextStage, battle, totalBattles)
    }
  })
}

ecs.register_es("newbie_damage_init_state", {
    onInit = onPlayerConnected
  },
  {
    comps_ro = [
      ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
      ["appId", ecs.TYPE_INT],
    ],
    comps_rq = ["newbie__baseKillCount", "newbie__killCountMax"],
    comps_no = ["playerIsBot"]
  },
  {tags = "server"}
)
