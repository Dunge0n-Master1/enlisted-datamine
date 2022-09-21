from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { squadsByArmies } = require("%enlist/meta/profile.nut")


let expiredRentedSquads = Watched({})

let function updateExpiredRentedSquads(_ = null) {
  let res = {}
  let curTime = serverTime.value
  local nextExpireTime = 0
  foreach (armyId, squads in squadsByArmies.value)
    foreach (guid, squad in squads)
      if ((squad?.expireTime ?? 0) > 0) {
        if ((squad?.expireTime ?? 0) <= curTime)
          res[guid] <- armyId
        else
          nextExpireTime = nextExpireTime <= 0
            ? squad.expireTime
            : min(nextExpireTime, squad.expireTime)
      }
  expiredRentedSquads(res)

  gui_scene.clearTimer(updateExpiredRentedSquads)
  let timeLeft = nextExpireTime - curTime
  if (timeLeft > 0)
    gui_scene.setTimeout(timeLeft, updateExpiredRentedSquads)
}

updateExpiredRentedSquads()
squadsByArmies.subscribe(updateExpiredRentedSquads)

return {
  expiredRentedSquads
}
