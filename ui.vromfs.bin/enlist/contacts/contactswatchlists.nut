from "%enlSqGlob/ui_library.nut" import *

let { ndbTryRead, ndbWrite } = require("nestdb")
let { isContactOnline, onlineStatus } = require("contactPresence.nut")
let { canCrossnetworkChatWithAll,
  canCrossnetworkChatWithFriends } = require("%enlSqGlob/crossnetwork_state.nut")

let isInternalContactsAllowed = true

let predefinedContactsList = ["approved", "myRequests", "requestsToMe", "rejectedByMe", "myBlacklist", "meInBlacklist"]

let contactsLists = predefinedContactsList
  .reduce(function(res, name) {
    console_print($"registerList {name}")

    let persistKey = $"contact_list_{name}"
    let uids = Watched(ndbTryRead(persistKey) ?? {})
    uids.subscribe(function(u) {
      ndbWrite(persistKey, u)
    })

    res[name] <- uids
    return res
  },
  {})

let approvedUids = isInternalContactsAllowed ? contactsLists.approved : Watched({})
let psnApprovedUids = Watched({})
let xboxApprovedUids = Watched({})
let myRequestsUids = contactsLists.myRequests
let requestsToMeUids = contactsLists.requestsToMe
let rejectedByMeUids = contactsLists.rejectedByMe
let myBlacklistUids = contactsLists.myBlacklist
let psnBlockedUids = Watched({})
let xboxBlockedUids = Watched({})
let xboxMutedUids = Watched({})
let meInBlacklistUids = contactsLists.meInBlacklist

let friendsUids = Computed(@() {}.__update(approvedUids.value, psnApprovedUids.value, xboxApprovedUids.value))
let blockedUids = Computed(@() {}.__update(myBlacklistUids.value, psnBlockedUids.value, xboxBlockedUids.value))

let friendsOnlineUids = Computed(@()
  friendsUids.value.filter(@(_, userId) isContactOnline(userId, onlineStatus.value)).keys()
)

let getCrossnetworkChatEnabled = @(userId) userId.tostring() in friendsUids.value
  ? canCrossnetworkChatWithFriends.value
  : canCrossnetworkChatWithAll.value


return {
  contactsLists
  approvedUids
  psnApprovedUids
  xboxApprovedUids
  myRequestsUids
  requestsToMeUids
  rejectedByMeUids
  myBlacklistUids
  psnBlockedUids
  xboxBlockedUids
  xboxMutedUids
  meInBlacklistUids
  friendsUids
  blockedUids
  friendsOnlineUids
  getCrossnetworkChatEnabled
  isInternalContactsAllowed
}