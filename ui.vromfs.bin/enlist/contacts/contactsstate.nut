from "%enlSqGlob/ui_library.nut" import *

let charClient = require("%enlSqGlob/charClient.nut")
let { contactsLists, blockedUids, getCrossnetworkChatEnabled } = require("contactsWatchLists.nut")
let { pushNotification, removeNotify, subscribeGroup, removeNotifyById, InvitationsStyle,
  InvitationsTypes
} = require("%enlist/mainScene/invitationsLogState.nut")
let { updateContact, validateNickNames, getContactNick } = require("contact.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { matchingCall } = require("%enlist/matchingClient.nut")
let matching_api = require("matching.api")
let eventbus = require("eventbus")
let msgbox = require("%enlist/components/msgbox.nut")
let platform = require("%dngscripts/platform.nut")
let {blocklistUpdate} = require("%enlSqGlob/blocklist.nut")
let isContactsVisible = mkWatched(persist, "isContactsVisible", false)
let { presences, updatePresences } = require("contactPresence.nut")
let { canInterractCrossPlatform } = require("%enlSqGlob/platformUtils.nut")
let { crossnetworkChat, canCrossnetworkChatWithAll,
  canCrossnetworkChatWithFriends } = require("%enlSqGlob/crossnetwork_state.nut")
let { getAppIdsList } = require("%enlist/getAppIdsList.nut")
let { showCrossnetworkChatRestrictionMsgBox } = require("%enlist/restrictionWarnings.nut")
let { INVALID_USER_ID } = require("matching.errors")

let logC = require("%enlSqGlob/library_logs.nut").with_prefix("[CONTACTS STATE] ")

let isOnlineContactsSearchEnabled = true //TODO: remove flag
let isContactsEnabled = true //TODO: Remove flag
let isContactsManagementEnabled = true //TODO: Remove flag

const ADD_MODE = "add"
const DEL_MODE = "del"
const APPROVED_MAIL = "approved_mail"
const REQUESTS_TO_ME_MAIL = "requests_to_me_mail"
let getContactsInviteId = @(uid) $"contacts_invite_{uid}"

userInfo.subscribe(function(uInfo) {
  if (uInfo?.userIdStr)
    updateContact(uInfo.userIdStr, uInfo.name)
})

const GAME_GROUP_NAME = "Enlisted" //WTF?

let searchContactsResults = Watched({})

// forward declarations
local fetchContacts = null

let function execContactsCharAction(userId, charAction) {
  if (userId == INVALID_USER_ID) {
    logC($"trying to do {charAction} with invalid contact")
    return
  }
  charClient[charAction](userId.tointeger(), GAME_GROUP_NAME, {
    success = function () {
      fetchContacts(null)
    }

    failure = function (err) {
      msgbox.show({
        text = loc(err)
      })
    }
  })
}


let buildFullListName = @(name) $"#{GAME_GROUP_NAME}#{name}"
let markRead = @(mail_id) matchingCall("postbox.notify_read", null, { mail_id })

subscribeGroup(APPROVED_MAIL, {
  function onShow(notify) {
    removeNotify(notify)
    markRead(notify.mailId)
  }
  onRemove = @(notify) markRead(notify.mailId)
})

subscribeGroup(REQUESTS_TO_ME_MAIL, {
  function onShow(notify) {
    removeNotify(notify)
    markRead(notify.mailId)
    let contact = updateContact(notify.fromUid)
    let user = getContactNick(contact)
    if (!canInterractCrossPlatform(user, getCrossnetworkChatEnabled(contact.uid))) {
      showCrossnetworkChatRestrictionMsgBox()
      return
    }

    msgbox.show({
      text = loc("contact/mbox_add_to_friends", { user })
      buttons = [
        { text = loc("Yes")
          action = @() execContactsCharAction(notify.fromUid, "contacts_approve_request")
          isCurrent = true
        }
        { text = loc("No")
          action = @() execContactsCharAction(notify.fromUid, "contacts_reject_request")
          isCancel = true
        }
      ]
    })
  }
  onRemove = @(notify) markRead(notify.mailId)
})

let function onNotifyListChanged(body, mailId) {
  let changed = body?.changed
  if (type(changed) != "table")
    return

  let perUidList = {}
  let function handleList(changedListObj, mode, listName) {
    if (mode not in changedListObj)
      return
    foreach (uid in changedListObj[mode]) {
      if (!(uid in perUidList))
        perUidList[uid] <- {}
      perUidList[uid][mode] <- { listName }
    }
  }

  foreach (name, _ in contactsLists) {
    let changedListObj = changed?[buildFullListName(name)]
    if (changedListObj == null)
      continue
    console_print(changedListObj)
    handleList(changedListObj, ADD_MODE, name)
    handleList(changedListObj, DEL_MODE, name)
  }

  foreach (uidInt, data in perUidList) {
    let uid = uidInt.tostring()
    let contact = updateContact(uid)
    if (data?[ADD_MODE].listName == "requestsToMe") {
      validateNickNames([contact],
        function() {
          let nick = getContactNick(contact)
          if (canInterractCrossPlatform(nick, canCrossnetworkChatWithAll.value))
            pushNotification({
              id = getContactsInviteId(uid)
              mailId
              fromUid = uid
              playerName = nick
              nType = InvitationsTypes.TO_FRIEND
              styleId = InvitationsStyle.PRIMARY
              text = loc("contact/incomingInvitation", { user = nick })
              actionsGroup = REQUESTS_TO_ME_MAIL
            })
        })
    }
    else if (data?[DEL_MODE].listName == "requestsToMe")
      removeNotifyById(getContactsInviteId(uid))
    else if (data?[DEL_MODE].listName == "approved")
      validateNickNames([contact],
        @() pushNotification({
          mailId
          text = loc("contact/removedYouFromFriends", { user = getContactNick(contact) })
          isRead = true
          nType = InvitationsTypes.FRIEND_REMOVE
          playerName = getContactNick(contact)
          actionsGroup = APPROVED_MAIL
        }))
  }
}

let function updatePresencesByList(new_presences) {
  logC("Update presences by list: new presences:", new_presences)
  let curPresences = presences.value
  let updPresences = {}
  foreach (p in new_presences)
    updPresences[p.userId] <- p?.update ? (curPresences?[p.userId] ?? {}).__merge(p.presences)
      : p.presences

  logC("Update presences by list: set finale states:", updPresences)
  updatePresences(updPresences)
}

let function updateGroup(new_contacts, uids, groupName) {
  let members = new_contacts?[groupName] ?? []
  local hasChanges = false
  let newUids = {}
  let cnChatWatchVal = groupName == buildFullListName("approved")
    ? canCrossnetworkChatWithFriends.value
    : canCrossnetworkChatWithAll.value

  foreach (member in members) {
    local { userId, nick } = member
    if (!canInterractCrossPlatform(nick, cnChatWatchVal))
      continue

    userId = userId.tostring()
    hasChanges = hasChanges || userId not in uids.value
    updateContact(userId, nick) //register contact name
    newUids[userId] <- true
  }

  if (hasChanges || uids.value.len() != newUids.len())
    uids(newUids)
}

let function updateAllLists(new_contacts) {
  foreach (name, uids in contactsLists)
    updateGroup(new_contacts, uids, buildFullListName(name))
}

let function onUpdateContactsCb(result) {
  if ("groups" in result) {
    updateAllLists(result.groups)
  }

  if ("presences" in result)
    updatePresencesByList(result.presences)
}

fetchContacts = function (postFetchCb=null) {
  matchingCall("mpresence.reload_contact_list", function(result) {
    onUpdateContactsCb(result)
    if (postFetchCb != null)
      postFetchCb()
  })
}

let function searchContactsOnline(nick, callback = null) {
  let request = {
    nick = nick
    maxCount = 100
    ignoreCase = true
    specificAppId = ";".join(getAppIdsList())
  }
  logC(request)
  charClient?.char_request(
    "cln_find_users_by_nick_prefix_json",
    request,
    function (result) {
      if (!(result?.result?.success ?? true)) {
        searchContactsResults({})
        if (callback)
          callback()
        return
      }

      let myUserId = userInfo.value?.userIdStr ?? ""
      let resContacts = {}
      foreach (uidStr, name in result)
        if ((typeof name == "string")
            && uidStr != myUserId
            && uidStr != "") {
          local a
          try {
            a = uidStr.tointeger()
          } catch(e){
            print($"uid is not an integer, uid: {uidStr}")
          }
          if (a == null)
            continue
          updateContact(uidStr, name) //register contact name
          resContacts[uidStr] <- true
        }

      searchContactsResults(resContacts)
      if (callback)
        callback()
    }
  )
}

matching_api.listen_notify("mpresence.notify_presence_update")
matching_api.listen_notify("postbox.notify_mail")

eventbus.subscribe("mpresence.notify_presence_update", onUpdateContactsCb)
eventbus.subscribe("postbox.notify_mail",
  function(mail_obj) {
    if (mail_obj.mail?.subj == "notify_contacts_update") {
      let function handleMail() {
        console_print(mail_obj.mail.body)
        onNotifyListChanged(mail_obj.mail.body, mail_obj.mail_id)
      }
      fetchContacts(handleMail)
    }
  })

if (platform.is_sony)
  eventbus.subscribe("playerProfileDialogClosed", @(res) res?.result.wasCanceled ? null : fetchContacts())

blockedUids.subscribe(function(b) {
  let byUid = {}
  foreach (userId, _ in b)
    byUid[userId.tointeger()] <- true
  blocklistUpdate(byUid)
})

crossnetworkChat.subscribe(@(_) fetchContacts())


//----------- Debug Block -----------------
if (isContactsEnabled) {
  let { get_time_msec } = require("dagor.time")
  let { chooseRandom } = require("%sqstd/rand.nut")

  let fakeList = Watched([])
  fakeList.subscribe(function(f) {
    updatePresencesByList(f)
    updateAllLists({ ["#Enlisted#approved"] = f })
  })
  let function genFake(count) {
    let fake = array(count)
      .map(@(_, i) {
        nick = $"stranger{i}",
        userId = (2000000000 + i).tostring(),
        presences = { online = (i % 2) == 0 }
      })
    let startTime = get_time_msec()
    fakeList(fake)
    logC($"Friends update time: {get_time_msec() - startTime}")
  }
  console_register_command(genFake, "contacts.generate_fake")

  let function changeFakePresence(count) {
    if (fakeList.value.len() == 0) {
      logC("No fake contacts yet. Generate them first")
      return
    }
    let startTime = get_time_msec()
    for(local i = 0; i < count; i++) {
      let f = chooseRandom(fakeList.value)
      f.presences.online = !f.presences.online
      updatePresences({ [f.userId] = f.presences })
    }
    logC($"{count} friends presence update by separate events time: {get_time_msec() - startTime}")
  }
  console_register_command(changeFakePresence, "contacts.change_fake_presence")
}

return {
  searchContactsResults
  isOnlineContactsSearchEnabled
  isContactsEnabled
  isContactsManagementEnabled

  searchContacts = @(nick, callback = null)
    isOnlineContactsSearchEnabled ? searchContactsOnline(nick, callback) : null

  execContactsCharAction
  isContactsVisible
  getContactsInviteId
}