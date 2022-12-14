from "%enlSqGlob/ui_library.nut" import *

let netUtils = require("%enlist/netUtils.nut")
let { subscribe_to_xuid_requests, on_xuid_request_response,
  subscribe_to_batch_uids_requests, on_batch_uids_request_response } = require("%xboxLib/externalIds.nut")
let { searchContactByExternalId } = require("%enlist/contacts/externalIdsManager.nut")


let function request_xuid_for_user(uid, callback) {
  netUtils.request_full_userinfo(uid.tointeger(), function(response) {
    callback?(uid, response?.live_xuid)
  })
}


let function batch_search_uids_by_xuids(xuids, callback) {
  searchContactByExternalId(xuids, function(response) {
    local xbox2uid = {}
    foreach (uid, data in response) {
      let { id = null } = data
      if (id != null)
        xbox2uid[id] <- uid
    }
    callback?(xbox2uid)
  })
}


subscribe_to_xuid_requests(function(uid) {
  request_xuid_for_user(uid, on_xuid_request_response)
})


subscribe_to_batch_uids_requests(function(xuids, requestId) {
  batch_search_uids_by_xuids(xuids, function(xbox2uid) {
    on_batch_uids_request_response(xbox2uid, requestId)
  })
})


return {
  request_xuid_for_user
  batch_search_uids_by_xuids
}