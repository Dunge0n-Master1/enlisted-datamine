from "%enlSqGlob/ui_library.nut" import *

let netUtils = require("%enlist/netUtils.nut")
let { updateUids } = require("%enlist/contacts/consoleUidsRemap.nut")
let logX = require("%sqstd/log.nut")().with_prefix("[XUIDS] ")

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let requestedUids = sharedWatched("requestedUids", @() [])


let function request_known_xuid(userId, callback) {
  let function response_handler(response) {
    if (response?.user_id == null) {
      logX("No user_id returned in response")
      return
    }

    if (response?.live_xuid) {
      updateUids({ [response.live_xuid] = response.user_id })
      logX($"UserID {userId} has known xuid {response.live_xuid}")
      callback?(response.user_id, response.live_xuid)
    } else {
      requestedUids.value.mutate(@(v) v.append(userId))
      logX($"UserID {userId} doesn't contain known xuid, remembering")
      callback?(userId, null)
    }
  }

  if (userId in requestedUids.value) {
    logX($"UserID {userId} was requested already and doesn't contain known xuid")
    callback?(userId, null)
    return
  }

  logX($"Requesting XUID for UserID {userId}")
  netUtils.request_full_userinfo(userId, response_handler)
}


return {
  request_known_xuid
}