import "%dngscripts/ecs.nut" as ecs
let profile = require("%scripts/game/utils/profile.nut")
let { INVALID_USER_ID } = require("matching.errors")
let logS = require("%enlSqGlob/library_logs.nut").with_prefix("[sendToProfileServer] ")


let playerQuery = ecs.SqQuery("playerQuery", {
  comps_ro = [
    ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
    ["appId", ecs.TYPE_INT, 0],
    ["army", ecs.TYPE_STRING]
  ]
})

let function sendToProfileServer(playerEid, action, params) {
  if (!profile.isEnabled())
    return $"Skip profile action {action} because of profile not enabled"

  let { userid = INVALID_USER_ID, appId = 0, army = ""
  } = playerQuery.perform(playerEid, @(_eid, comp) comp)

  if (appId <= 0)
    return $"Invalid appId on try to send {action}"
  if (userid == INVALID_USER_ID)
    return $"Invalid userId on try to send {action}"
  if (army == "")
    return $"Missing armyId on try to send {action}"

  logS($"Send action {action} to userId {userid}, armyId = {army}")
  profile.sendJob(action, appId, userid, params.__merge({ armyId = army }))
  return null
}

return sendToProfileServer