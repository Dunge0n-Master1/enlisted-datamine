import "%dngscripts/ecs.nut" as ecs
let {userstatsSend} = require("%scripts/game/utils/userstats.nut")

let idCounter = persist("idCounter", @() { val = 0 })
let {INVALID_USER_ID} = require("matching.errors")

let function cacheUserStat(statName, userstats_mode) {
  if (statName in userstats_mode.getAll())
    userstats_mode[statName] = userstats_mode[statName] + 1
  else
    userstats_mode[statName] <- 1
}

let function sendAward(awardType, params = null, userstats_mode = null) {
  let { userid = INVALID_USER_ID, appId = null, mode = null } = params
  if (mode && userid != INVALID_USER_ID) {
    let stats = { [awardType] = 1 }
    userstatsSend(userid, appId, stats, mode)
  }
  if (userstats_mode != null) {
    cacheUserStat(awardType, userstats_mode)
    if ((mode ?? "") != "")
      cacheUserStat($"{awardType}_{mode}", userstats_mode)
  }
}

let modifyAwardQuery = ecs.SqQuery("modifyAwardQuery", {comps_rw = [["awards", ecs.TYPE_ARRAY]]})

let function addAward(playerEid, awardType, awardParams = {}) {
  modifyAwardQuery(playerEid, @(_eid, comp) comp["awards"].append({
    id = ++idCounter.val
    type = awardType
  }.__update(awardParams)))
}

return {
  addAward
  sendAward
}
