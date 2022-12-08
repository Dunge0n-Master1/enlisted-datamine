from "%enlSqGlob/ui_library.nut" import *
let {readPermissions, readPenalties} = require("%enlSqGlob/permission_utils.nut")
let {userInfo, userInfoUpdate} = require("%enlSqGlob/userInfoState.nut")
let {appId} = require("%enlSqGlob/clientState.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let {char_request} = require("%enlSqGlob/charClient.nut")


let function updateUserRightsInternal(cb = null) {
  if (userInfo.value == null)
    return

  let request = {
    appid =  appId.value
  }

  char_request("cln_get_user_rights", request,
    function(result) {
      if ( typeof result != "table" ) {
        log("ERROR: invalid cln_get_user_rights result\n")
        cb?("INTERNAL_SERVER_ERROR")
        return
      }

      let userId = userInfo.value?.userId ?? 0
      let resClientPermJwt = result?.clientPermJwt
      let resDedicatedPermJwt = result?.dedicatedPermJwt
      let resPenaltiesJwt = result?.penaltiesJwt
      let uiv = userInfo.value
      if (resClientPermJwt == null && resDedicatedPermJwt == null && resPenaltiesJwt == null
          && uiv?.penaltiesJwt == null && uiv?.dedicatedPermJwt == null && uiv?.permissions == null) {
        cb?("NOTHING_TO_UPDATE")
        return
      }

      cb?("UPDATED_SUCCESFULL")
      //permissions update only if jwt token was update. Penalties update always
      userInfoUpdate(userInfo.value.__merge({
        permissions = readPermissions(resClientPermJwt, userId)
        penalties = readPenalties(resPenaltiesJwt, userId)
        penaltiesJwt = resPenaltiesJwt
        dedicatedPermJwt = resDedicatedPermJwt
      }))
    }
  )
}

let rightsUpdateTimeout = 300 //5 min
gui_scene.setInterval(rightsUpdateTimeout, updateUserRightsInternal)

let function updateUserRights(cb = null) {
  gui_scene.clearTimer(updateUserRightsInternal)
  updateUserRightsInternal(cb)
  gui_scene.setInterval(rightsUpdateTimeout, updateUserRightsInternal)
}


let activePenalties = Watched([])

let penaltyExpiredTimeSec = @(p) ((p?.start.tointeger() ?? 0) + (p?.duration.tointeger() ?? 0))/1000

let function recalcActivePenalties() {
  let time = serverTime.value
  let userPenalties = userInfo.value?.penalties.value ?? []
  let penalties = userPenalties.filter(@(p) penaltyExpiredTimeSec(p) - time > 0)
  activePenalties(freeze(penalties))
}

let nextPenaltyExpireTime = keepref(Computed(@() activePenalties.value.reduce(function(res, p) {
  let expireTime = penaltyExpiredTimeSec(p)
  return (expireTime <= 0 || (res > 0 && expireTime > res)) ? res : expireTime
}, 0)))

nextPenaltyExpireTime.subscribe(function(t){
  let timeleft = t - serverTime.value
  if (timeleft > 0)
    gui_scene.resetTimeout(timeleft, recalcActivePenalties)
})
userInfo.subscribe(@(_) recalcActivePenalties())
recalcActivePenalties()


let hasClientPermission = @(permission) Computed(@()
  userInfo.value?.permissions.value.contains(permission) ?? false)

let getPenaltyExpiredTime = @(category, penalty, details) Computed(function() {
  return activePenalties.value.reduce(function(res, p) {
    if (p?.category != category || p?.penalty != penalty || p?.details != details)
      return res
    let expireTime = penaltyExpiredTimeSec(p)
    return (expireTime <= 0 || expireTime < res) ? res : expireTime
  }, 0)
})

console_register_command(@() updateUserRights(console_print), "user_rights.update")
console_register_command(@(category, penalty, details)
  console_print(getPenaltyExpiredTime(category, penalty, details)),
  "user_rights.getPenaltyExpiredTime")
console_register_command(@(permission)
  console_print(hasClientPermission(permission)), "user_rights.hasClientPermission")
console_register_command(@()
  console_print(userInfo.value?.permissions.value), "user_rights.allPermissions")

return {updateUserRights, hasClientPermission, getPenaltyExpiredTime}
