import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let dedicated = require_optional("dedicated")
let userstats = require_optional("userstats")

let {INVALID_USER_ID} = require("matching.errors")
let {logerr} = require("dagor.debug")
let logUS = require("%enlSqGlob/library_logs.nut").with_prefix("[userstats] ")

if (dedicated == null || userstats == null)
  return

const NEWBIE_KILLS_UNLOCK = "new_player_boost_kills"
const NEWBIE_BATTLES_UNLOCK = "new_player_boost_battles"


let newbieAimAssistPlayerQuery = ecs.SqQuery("newbieAimAssistPlayerQuery", {
  comps_rw = [["ab_test__isAimAssistTestEnabled", ecs.TYPE_BOOL]]
})

let function isFinished(unlock) {
  if (unlock == null)
    return false

  let { stage = 0, nextStage = 0, progress = 0 } = unlock
  return stage > 0 || progress >= nextStage
}

let function onPlayerConnected(eid, comp) {
  let { appId = 0, userid = INVALID_USER_ID, platform = "" } = comp
  logUS($"Player created: {appId}, {userid}, {platform}")
  if (appId == 0 || userid == INVALID_USER_ID || ["ps4", "ps5"].indexof(platform) == null)
    return
  userstats.request({
    headers = { appId, userid }
    data = {
      withUnprogressed = true,
      unlocks = [NEWBIE_KILLS_UNLOCK, NEWBIE_BATTLES_UNLOCK]
    }
    action = "AdmGetUnlocks"
  }, function(result) {
    logUS($"Userstats result for {userid}.", result?.response.unlocks)
    let isSuccess = result?.response?.success ?? true
    if (!isSuccess)
      logerr("Error during newbie unlock request {0}".subst(result?.response?.error ?? "unknown error"))
    let unlockKills = result?.response.unlocks[NEWBIE_KILLS_UNLOCK]
    let unlockBattles = result?.response.unlocks[NEWBIE_BATTLES_UNLOCK]
    newbieAimAssistPlayerQuery(eid, function(_eid, comp) {
      comp.ab_test__isAimAssistTestEnabled = !isFinished(unlockKills) && !isFinished(unlockBattles)
      logUS($"AB test for AIM assist {userid} enabled =", comp.ab_test__isAimAssistTestEnabled)
    })
  })
}

ecs.register_es("newbie_aim_assist_state", {
    onInit = onPlayerConnected
  },
  {
    comps_ro = [
      ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
      ["appId", ecs.TYPE_INT],
      ["platform", ecs.TYPE_STRING],
    ],
    comps_no = ["playerIsBot"]
  },
  {tags = "server"}
)
