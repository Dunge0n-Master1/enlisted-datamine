from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let auth_friends = require("%enlist/ps4/auth_friends.nut")
let ps4 = require("ps4")
let pswa = require("ps4.webapi")
let { friends, blocked } = require("%enlist/ps4/state.nut")
let loginState = require("%enlSqGlob/login_state.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { updatePresences, presences } = require("%enlist/contacts/contactPresence.nut")
let { Contact, isValidContactNick } = require("%enlist/contacts/contact.nut")
let eventbus = require("eventbus")
let voiceApi = require("voiceApi")
let profile = require("%enlist/ps4/profile.nut")
let { searchContactByExternalId } = require("%enlist/contacts/externalIdsManager.nut")
let { psnApprovedUids, psnBlockedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { console2uid, updateUids } = require("%enlist/contacts/consoleUidsRemap.nut")

let logpsn = require("%sqstd/log.nut")().with_prefix("[PSN CONTACTS] ")

let gameAppId = get_setting_by_blk_path("authGameId") ?? "cr"

let function onGetPsnFriends(pfriends) {
  let function onGetAuthContacts(contacts) {
    let result = []
    let updPresences = {}
    let afriends = contacts?.friends ?? {}
    let uidsList = {}
    let psn2uid = {}

    foreach (f in pfriends) {
      let friend = f
      if (friend.accountId in afriends) {
        let currentUid = afriends[friend.accountId]
        if (currentUid == null) {
          logpsn($"Friends mapping error: {friend.accountId} -> {currentUid}")
          continue
        }

        Contact(currentUid, $"{friend.nick}@psn")
        result.append(currentUid)
        updPresences[currentUid] <- { online = friend.online }
        psn2uid[friend.accountId] <- currentUid
        uidsList[currentUid] <- true
      }
    }

    updateUids(psn2uid)
    updatePresences(updPresences)
    friends(result)
    psnApprovedUids(uidsList)

    eventbus.send("PSNAuthContactsRecieved", null)
  }
  logpsn("onGetPsnFriends: AUTH_GAME_ID:", gameAppId)
  auth_friends.request_auth_contacts(gameAppId, false, onGetAuthContacts)
}

let function onGetBlockedUsers(users) {
  let unblockedList = blocked.value.filter(@(u) users.findvalue(@(u2) u.userId == u2.userId) == null)
  let blockedList = users.filter(@(u) blocked.value.findvalue(@(u2) u.userId == u2.userId) == null)

  foreach (u in unblockedList)
    voiceApi.unmute_player_by_uid(u.userId.tointeger())

  foreach (u in blockedList)
    voiceApi.mute_player_by_uid(u.userId.tointeger())

  blocked(users)

  let unknownPsnUids = []
  let knownUids = []
  let updPresences = {}
  let psn2uid = {}

  let contactsList = []
  foreach (user in users) {
    let u = user
    let c = Contact(u.userId)
    if (!isValidContactNick(c)) {
      contactsList.append(c)
      unknownPsnUids.append(u.accountId)
    }
    else
      knownUids.append(u.userId)

    updPresences[u.userId] <- { online = false }
    psn2uid[u.accountId] <- u.userId
  }

  updateUids(psn2uid)
  updatePresences(updPresences)

  searchContactByExternalId(unknownPsnUids, function(res) {
    //update blocklist
    if (unknownPsnUids.len() != res.len())
      logpsn("Requested external ids info not full", unknownPsnUids, res)

    let bl = {}
    foreach (uid in knownUids)
      bl[uid] <- true

    foreach(uidStr, _ in res)
      bl[uidStr] <- true

    psnBlockedUids(bl)
  })
}

let function onPresenceUpdate(accountId) {
  let userId = console2uid.value?[accountId.tostring()]
  if (userId != null && userId in presences.value)
    updatePresences({ [userId] = { online = !(presences.value[userId]?.online ?? false) }})
}

let function onFriendsUpdate() {
  profile.request_psn_friends(onGetPsnFriends)
}

let function request_blocked_users(callback) {
  let function profile_cb(users) {
    auth_friends.request_auth_contacts(gameAppId, false, function(contacts) {
      logpsn("request_auth_contacts:")
      logpsn(contacts)
      let authBlocked = contacts?.blocklist ?? {}
      let authFriends = contacts?.friends ?? {}
      let users2 = []
      foreach (user in users) {
        let accountId = user.accountId
        let userId = authBlocked?[accountId] ?? authFriends?[accountId]
        if (userId != null) {
          user.userId <- userId
          users2.append(user)
        }
      }

      callback(users2)
    })
  }
  profile.request_blocked_users(profile_cb)
}

let function onBlocklistUpdate() {
  request_blocked_users(onGetBlockedUsers)
}

isInBattleState.subscribe(function(val) {
  if (val)
    ps4.set_presence_callback(null)
  else if (loginState.isLoggedIn.value) {
    profile.request_psn_friends(onGetPsnFriends) //update psn friends presences
    ps4.set_presence_callback(onPresenceUpdate)
  }
})

loginState.isLoggedIn.subscribe(function(v) {
  if (v) {
    profile.request_psn_friends(onGetPsnFriends)
    request_blocked_users(onGetBlockedUsers)
    ps4.set_presence_callback(onPresenceUpdate)
    ps4.set_friends_list_callback(onFriendsUpdate)
    ps4.set_blocklist_callback(onBlocklistUpdate)
    pswa.subscribe_to_push_events()
  } else {
    ps4.set_presence_callback(null)
    ps4.set_friends_list_callback(null)
    ps4.set_blocklist_callback(null)
    pswa.unsubscribe_from_push_events()
  }
})