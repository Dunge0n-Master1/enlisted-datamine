from "%enlSqGlob/ui_library.nut" import *

let { friendsOnlineUids, myRequestsUids, requestsToMeUids
} = require("%enlist/contacts/contactsWatchLists.nut")
let { updateContact, getContactNick } = require("%enlist/contacts/contact.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { addPopup } = require("%enlSqGlob/ui/popup/popupsState.nut")

const FRIEND_NOTIFICATION = "hasFriendOnlineNotification"
let hasFriendOnlineNotification = Watched(get_setting_by_blk_path(FRIEND_NOTIFICATION) ?? true)
hasFriendOnlineNotification.subscribe(function(v) {
  set_setting_by_blk_path(FRIEND_NOTIFICATION, v)
  save_settings()
})

let friendsOnlineCache = Watched(null)
let isNotificationDisabled = @() !isLoggedIn.value
  || !hasFriendOnlineNotification.value
  || isInBattleState.value


let function fillFriendsCache(friends) {
  if (friendsOnlineCache.value == null) {
    let cache = friends.reduce(@(res, f) res.__update({ [f] = true }), {})
    friendsOnlineCache(cache)
    return
  }
  let toAdd = []
  let toDelete = []

  foreach(contact in friends) {
    if (contact not in friendsOnlineCache.value)
      toAdd.append(contact)
  }

  foreach(contact, _v in friendsOnlineCache.value)
    if (!friendsOnlineUids.value.contains(contact)
      && contact not in myRequestsUids.value
      && contact not in requestsToMeUids.value
    )
      toDelete.append(contact)

  if (toAdd.len() > 0 || toDelete.len() > 0)
    friendsOnlineCache.mutate(function(cache) {
      toDelete.each(@(v) delete cache[v])
      toAdd.each(@(v) cache[v] <- true)
    })
  if (isNotificationDisabled())
    return

  toAdd.each(@(contact) userInfo?.value.userId == contact ? null : addPopup({
      id = $"{contact}_online_alert"
      text = loc("contact/onlineNotif", { contact = getContactNick(updateContact(contact)) })
      needPopup = true
      styleName = "silence"
    }))
}


let fillCacheByRequest = function(players) {
  if (friendsOnlineCache.value == null)
    friendsOnlineCache({})
  friendsOnlineCache.mutate(@(v) players.each(@(_, uid) v[uid] <- true))
}

friendsOnlineUids.subscribe(fillFriendsCache)
foreach (v in [myRequestsUids, requestsToMeUids])
  v.subscribe(fillCacheByRequest)


return hasFriendOnlineNotification