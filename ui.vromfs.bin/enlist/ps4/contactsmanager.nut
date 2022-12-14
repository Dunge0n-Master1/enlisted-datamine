from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { get_setting_by_blk_path } = require("settings")
let auth_friends = require("%enlist/ps4/auth_friends.nut")
let pswa = require("ps4.webapi")
let { psn_friendsUpdate, psn_blocked_users, psn_blocked_usersUpdate
} = require("%enlist/ps4/psn_state.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { updatePresences, presences } = require("%enlist/contacts/contactPresence.nut")
let { Contact, isValidContactNick } = require("%enlist/contacts/contact.nut")
let eventbus = require("eventbus")
let voiceApi = require("voiceApi")
let profile = require("%enlist/ps4/profile.nut")
let { searchContactByExternalId } = require("%enlist/contacts/externalIdsManager.nut")
let { psnApprovedUids, psnBlockedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { console2uid, updateUids } = require("%enlist/contacts/consoleUidsRemap.nut")
let { EventLevelLoaded } = require("gameevents")

let logpsn = require("%enlSqGlob/library_logs.nut").with_prefix("[PSN CONTACTS] ")

let gameAppId = get_setting_by_blk_path("authGameId") ?? "cr"

let function psnConstructFriendsList(psn_friends, contacts) {
  let result = []
  let updPresences = {}
  let afriends = contacts?.friends ?? {}
  let uidsList = {}
  let psn2uid = {}

  foreach (f in psn_friends) {
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
  psn_friendsUpdate(result)
  psnApprovedUids(uidsList)

  eventbus.send("PSNAuthContactsRecieved", null)
}

let function psnConstructBlocksList(profile_blocked, psn_contacts, callback) {
  logpsn("psnConstructBlocksList: ", psn_contacts)
  let authBlocked = psn_contacts?.blocklist ?? {}
  let authFriends = psn_contacts?.friends ?? {}
  let users2 = []
  foreach (user in profile_blocked) {
    let accountId = user.accountId
    let userId = authBlocked?[accountId] ?? authFriends?[accountId]
    if (userId != null) {
      user.userId <- userId
      users2.append(user)
    }
  }
  callback(users2)
}

let function onGetPsnFriends(pfriends) {
  logpsn("onGetPsnFriends: AUTH_GAME_ID:", gameAppId)
  auth_friends.request_auth_contacts(gameAppId, false, @(contacts) psnConstructFriendsList(pfriends, contacts))
}

let function onGetBlockedUsers(users) {
  let unblockedList = psn_blocked_users.value.filter(@(u) users.findvalue(@(u2) u.userId == u2.userId) == null)
  let blockedList = users.filter(@(u) psn_blocked_users.value.findvalue(@(u2) u.userId == u2.userId) == null)

  foreach (u in unblockedList)
    voiceApi.unmute_player_by_uid(u.userId.tointeger())

  foreach (u in blockedList)
    voiceApi.mute_player_by_uid(u.userId.tointeger())

  psn_blocked_usersUpdate(users)

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

    foreach (uidStr, _ in res)
      bl[uidStr] <- true

    psnBlockedUids(bl)
  })
}

let function onPresenceUpdate(accountId) {
  let userId = console2uid.value?[accountId.tostring()]
  if (userId != null && userId in presences.value)
    updatePresences({ [userId] = { online = !(presences.value[userId]?.online ?? false) }})
}

let function onFriendsUpdate(_) {
  profile.request_psn_friends(onGetPsnFriends)
}

let function request_blocked_users(callback) {
  profile.request_blocked_users(function(users) {
    auth_friends.request_auth_contacts(gameAppId, false, @(contacts) psnConstructBlocksList(users, contacts, callback))
  })
}

let function onBlocklistUpdate(_) {
  request_blocked_users(onGetBlockedUsers)
}

let function request_psn_contacts() {
  logpsn("request_psn_contacts: AUTH_GAME_ID: ", gameAppId)
  auth_friends.request_auth_contacts(gameAppId, false, function(contacts) {
    profile.request_blocked_users(@(profile_blocked) psnConstructBlocksList(profile_blocked, contacts, onGetBlockedUsers))
    profile.request_psn_friends(@(psn_friends) psnConstructFriendsList(psn_friends, contacts))
  })
}

ecs.register_es("playstation_update_friend_list", {
  [EventLevelLoaded] = function(_evt, _eid, comp) {
    if (comp.menu_level == null) // mean user in battle
      eventbus.unsubscribe("ps4.presence_update", onPresenceUpdate)
    else if (isLoggedIn.value) {
      request_psn_contacts()
      eventbus.subscribe("ps4.presence_update", onPresenceUpdate)
    }
  }
},
{
  comps_ro = [["menu_level", ecs.TYPE_TAG, null]],
  comps_rq = ["level__blk"]
})

let function initHandlers() {
  request_psn_contacts()
  eventbus.subscribe("ps4.presence_update", onPresenceUpdate)
  eventbus.subscribe("ps4.friends_list_update", onFriendsUpdate)
  eventbus.subscribe("ps4.blocklist_update", onBlocklistUpdate)
  pswa.subscribe_to_push_events()
}

let function disposeHandlers() {
  eventbus.unsubscribe("ps4.presence_update", onPresenceUpdate)
  eventbus.unsubscribe("ps4.friends_list_update", onFriendsUpdate)
  eventbus.unsubscribe("ps4.blocklist_update", onBlocklistUpdate)
  pswa.unsubscribe_from_push_events()
}

if (isLoggedIn.value)
  initHandlers()

isLoggedIn.subscribe(@(v) v
  ? initHandlers()
  : disposeHandlers())
