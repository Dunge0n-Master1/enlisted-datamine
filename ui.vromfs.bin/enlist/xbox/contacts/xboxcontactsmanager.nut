let relationships = require("%xboxLib/impl/relationships.nut")
let { mute_by_xuids, unmute_by_xuids } = require("%enlist/xbox/voice.nut")
let { xboxFriends, xboxFriendsUpdate, xboxBlockedUsers, xboxBlockedUsersUpdate, xboxMuted, xboxMutedUpdate } = require("xboxContactsState.nut")
let { xboxApprovedUids, xboxBlockedUids, xboxMutedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let loginState = require("%enlSqGlob/login_state.nut")
let { searchContactByExternalId } = require("%enlist/contacts/externalIdsManager.nut")
let { console2uid, uid2console, updateUids } = require("%enlist/contacts/consoleUidsRemap.nut")
let { update_presences_for_users } = require("%enlist/xbox/presence.nut")
let { start_monitoring, stop_monitoring } = require("%xboxLib/impl/presence.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let logxb = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX CONTACTS]")


let CONTACT_GROUP_FRIENDS = "f"
let CONTACT_GROUP_BLOCKED = "b"
let CONTACT_GROUP_MUTED   = "m"

let ignoreRequestedXboxUids = persist("ignoreRequestedXboxUids", @() {})
let uidsListByGroup = {
  [CONTACT_GROUP_FRIENDS] = {
    contactsUidsWatch = xboxApprovedUids
    consoleUidsWatch = xboxFriends
    consoleUidsWatchUpdate = xboxFriendsUpdate
    unknownUidsList = persist("unknownUidsListFriends", @() {})
  },
  [CONTACT_GROUP_BLOCKED] = {
    contactsUidsWatch = xboxBlockedUids
    consoleUidsWatch = xboxBlockedUsers
    consoleUidsWatchUpdate = xboxBlockedUsersUpdate
    unknownUidsList = persist("unknownUidsListBlocked", @() {})
  },
  [CONTACT_GROUP_MUTED] = {
    contactsUidsWatch = xboxMutedUids
    consoleUidsWatch = xboxMuted
    consoleUidsWatchUpdate = xboxMutedUpdate
    unknownUidsList = persist("unknownUidsListMuted", @() {})
  }
}


let function searchUnknownUids() {
  let unknownUids = []

  foreach (data in uidsListByGroup)
    foreach (xboxUid, _ in data.unknownUidsList)
      if (xboxUid not in ignoreRequestedXboxUids)
        unknownUids.append(xboxUid)

  searchContactByExternalId(
    unknownUids,
    function(res) {
      let xbox2uid = {}

      foreach (uid, data in res) {
        let { id = null } = data
        if (id != null)
          xbox2uid[id] <- uid
      }

      updateUids(xbox2uid)

      //Add to ignore list, to not spam server with already requested uids
      foreach (xboxUid in unknownUids)
        if (xboxUid not in console2uid.value)
          ignoreRequestedXboxUids[xboxUid] <- true

      foreach (group, data in uidsListByGroup) {
        let knownUids = {}
        foreach (xboxUid in data.consoleUidsWatch.value) {
          if (xboxUid in console2uid.value)
            knownUids[console2uid.value[xboxUid]] <- true
        }
        uidsListByGroup[group].contactsUidsWatch(knownUids)
      }
    }
  )
}

let pendingGroupChanges = {}
let requestedGroupChange = {}
let function proceedPeopleListAndDo(xuids, group) {
  if (userInfo.value == null) {
    logxb($"Try proceed group {group} when not logged in")
    return
  }

  if (group not in uidsListByGroup) {
    logxb($"Try load unknown group {group} for updating contacts")
    return
  }

  if (group == CONTACT_GROUP_MUTED) {
    //check players to mute, before update existed lists
    // to distinguish differences in lists
    let newXuidsList = xuids
    let oldXuidsList = uidsListByGroup[group].consoleUidsWatch.value
    for (local i = 0; i < oldXuidsList.len(); i++) {
      let oldXuid = oldXuidsList[i]
      let oldIdx = newXuidsList.indexof(oldXuid)
      if (oldIdx != null) {
        oldXuidsList.remove(i)
      }
    }

    unmute_by_xuids(oldXuidsList)
  }

  uidsListByGroup[group].consoleUidsWatchUpdate(xuids.map(@(u) u.tostring()))
  uidsListByGroup[group].unknownUidsList.clear()

  foreach (xboxUid in uidsListByGroup[group].consoleUidsWatch.value)
    if (xboxUid not in console2uid.value)
      uidsListByGroup[group].unknownUidsList[xboxUid] <- true

  foreach (groupName, _ in requestedGroupChange) {
    if (!(pendingGroupChanges?[groupName] ?? false)) {
      logxb($"Not all requested groups updated. Waiting for others")
      return
    }
  }

  pendingGroupChanges.clear()
  requestedGroupChange.clear()

  searchUnknownUids()
}

let getXuidsArray = @(v) (v?.keys() ?? [])
  .filter(@(uid) uid in uid2console.value)
  .map(@(xuid) uid2console.value[xuid].tointeger())

xboxApprovedUids.subscribe(function(v) {
  let xboxUids = getXuidsArray(v)
  if (!xboxUids.len())
    return

  update_presences_for_users(xboxUids)
  start_monitoring(xboxUids)
})

xboxBlockedUids.subscribe(function(v) {
  let xboxUids = getXuidsArray(v)
  if (!xboxUids.len())
    return

  mute_by_xuids(xboxUids)
  stop_monitoring(xboxUids)
})

xboxMutedUids.subscribe(function(v) {
  let xboxUids = getXuidsArray(v)
  if (!xboxUids.len())
    return

  mute_by_xuids(xboxUids)
  stop_monitoring(xboxUids)
})


let function on_friends_list_update(xuids) {
  logxb("on_friends_list_update")
  pendingGroupChanges[CONTACT_GROUP_FRIENDS] <- true
  proceedPeopleListAndDo(xuids, CONTACT_GROUP_FRIENDS)
}


let function on_avoid_list_update(xuids) {
  logxb("on_avoid_list_update")
  pendingGroupChanges[CONTACT_GROUP_BLOCKED] <- true
  proceedPeopleListAndDo(xuids, CONTACT_GROUP_BLOCKED)
}


let function on_muted_list_update(xuids) {
  logxb("on_muted_list_update")
  pendingGroupChanges[CONTACT_GROUP_MUTED] <- true
  proceedPeopleListAndDo(xuids, CONTACT_GROUP_MUTED)
}


let requestFriendsList = @() relationships.retrieve_related_people_list(on_friends_list_update)
let requestBlockList = @() relationships.retrieve_avoid_people_list(on_avoid_list_update)
let requestMuteList = @() relationships.retrieve_muted_people_list(on_muted_list_update)


let function on_relationships_change_event(list, change_type, xuids) {
  logxb("on_relationships_change_event")
  if (xuids.len() == 0) //Nothing changed
    return

  //Todo: make not full list update, but make accurate changes in our lists
  if (list == relationships.ListType.Friends) {
    requestedGroupChange[CONTACT_GROUP_FRIENDS] <- false
    requestFriendsList()
  }
  else if (list == relationships.ListType.Avoid) {
    requestedGroupChange[CONTACT_GROUP_BLOCKED] <- false
    requestBlockList()
  }
  else if (list == relationships.ListType.Mute) {
    if (change_type == relationships.ChangeType.Added)
      mute_by_xuids(xuids)
    else if (change_type == relationships.ChangeType.Removed)
      unmute_by_xuids(xuids)

    requestedGroupChange[CONTACT_GROUP_MUTED] <- false
    requestMuteList()
  }
  else
    logxb($"Received invalid data: ", list, change_type, xuids)
}


relationships.subscribe_to_relationships_change_events(on_relationships_change_event)


loginState.isLoggedIn.subscribe(function(v) {
  if (v) {
    ignoreRequestedXboxUids.clear()
    logxb("Start collect all contacts")
    requestedGroupChange[CONTACT_GROUP_FRIENDS] <- false
    requestedGroupChange[CONTACT_GROUP_BLOCKED] <- false
    requestedGroupChange[CONTACT_GROUP_MUTED] <- false
    requestFriendsList()
    requestBlockList()
    requestMuteList()
  }
})