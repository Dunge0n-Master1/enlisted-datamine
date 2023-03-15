from "%enlSqGlob/ui_library.nut" import *

#explicit-this

let {checkMultiplayerPermissions} = require("%enlist/permissions/permissions.nut")
let { debounce } = require("%sqstd/timers.nut")
let {nestWatched} = require("%dngscripts/globalState.nut")
let { fabs } = require("math")
let { pushNotification, removeNotifyById, removeNotify, subscribeGroup
} = require("%enlist/mainScene/invitationsLogState.nut")
let popupsState = require("%enlist/popup/popupsState.nut")    // CODE SMELLS: ui state in logic module!
let { blockedUids } = require("%enlist/contacts/contactsWatchLists.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { Contact, validateNickNames, getContactNick } = require("%enlist/contacts/contact.nut")
let { onlineStatus, isContactOnline, updateSquadPresences } = require("%enlist/contacts/contactPresence.nut")
let MSquadAPI = require("squadAPI.nut")
let matching_api = require("matching.api")
let msgbox = require("%enlist/components/msgbox.nut")
let {join_voice_chat, leave_voice_chat} = require("%enlist/voiceChat/voiceState.nut")
let {leaveChat, createChat, joinChat} = require("%enlist/chat/chatApi.nut")
let squadState = require("%enlist/squad/squadState.nut")
let { squadId, isInSquad, isSquadLeader, isInvitedToSquad, selfUid,
  squadSharedData, squadServerSharedData, squadMembers,
  squadSelfMember, myExtSquadData, notifyMemberRemoved, notifyMemberAdded
} = squadState

let logSq = require("%enlSqGlob/library_logs.nut").with_prefix("[SQUAD] ")
let sessionManager = require("%enlist/squad/consoleSessionManager.nut")
let eventbus = require("eventbus")
let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let { crossnetworkPlay, CrossPlayStateWeight, crossnetworkChat } = require("%enlSqGlob/crossnetwork_state.nut")
let { consoleCompare, canInterractCrossPlatformByCrossplay } = require("%enlSqGlob/platformUtils.nut")
let { availableSquadMaxMembers } = require("%enlist/state/queueState.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { hasValidBalance } = require("%enlist/currency/currencies.nut")

const INVITE_ACTION_ID = "squad_invite_action"
const SQUAD_OVERDRAFT = 0

let setOnlineBySquad = @(userId, online) updateSquadPresences({ [userId.tostring()] = online })

let SquadMember = function(userId)  {
  let realnick = Contact(userId.tostring()).value.realnick
  return {
    userId
    isLeader = squadId.value == userId
    state = {}
    realnick
  }
}

let function applyRemoteDataToSquadMember(member, msquad_data) {
  logSq($"[SQUAD] applyRemoteData for {member.userId} from msquad")
  logSq(msquad_data)

  let newOnline = msquad_data?.online
  if (newOnline != null)
    setOnlineBySquad(member.userId, newOnline)

  let data = msquad_data?.data
  if (typeof(data) != "table")
    return {}

  let oldVal = member.state
  foreach (k,v in data){
    if (k in oldVal && oldVal[k] == v)
      continue
    member.state = oldVal.__merge(data)
    break
  }

  return data
}


let delayedInvites = mkWatched(persist, "delayedInvites", null)
let isSquadDataInited = nestWatched("isSquadDataInited", false)
let squadChatJoined = nestWatched("squadChatJoined", false)

let myExtDataRW = {}
let myDataRemote = nestWatched("myDataRemoteWatch", {})
let myDataLocal = Watched({})

let voiceChatId          = @(s) $"squad-channel-{s}"

squadId.subscribe(function(_val) {
  isSquadDataInited(false)
})
squadMembers.subscribe(@(list) validateNickNames(list.map(@(m) Contact(m.userId.tostring()))))

let getSquadInviteUid = @(inviterSquadId) $"squad_invite_{inviterSquadId}"

let function sendEvent(handlers, val) {
  foreach (h in handlers)
    h(val)
}

let function isFloatEqual(a, b, eps = 1e-6) {
  let absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}

let isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

let updateMyData = debounce(function() {
  if (squadSelfMember.value == null)
    return //no need to try refresh when no self member

  let needSend = myDataLocal.value.findindex(@(value, key) !isEqualWithFloat(myDataRemote.value?[key], value)) != null
  if (needSend) {
    logSq("update my data: ", myDataLocal.value)
    MSquadAPI.setMemberData(myDataLocal.value)
  }
}, 0.1)

foreach (w in [squadSelfMember, myDataLocal, myDataRemote])
  w.subscribe(@(_) updateMyData())

let function linkVarToMsquad(name, var) {
  myDataLocal.mutate(@(v) v[name] <- var.value)
  var.subscribe(@(_val) myDataLocal.mutate(@(v) v[name] <- var.value))
}

linkVarToMsquad("name", keepref(Computed(@() userInfo.value?.name))) //always set

let function bindSquadROVar(name, var) {
  myExtSquadData[name] <- var
  linkVarToMsquad(name, var)
}

let function bindSquadRWVar(name, var) {
  myExtSquadData[name] <- var
  myExtDataRW[name] <- var
  linkVarToMsquad(name, var)
}

let function setSelfRemoteData(member_data) {
  myDataRemote(clone member_data)
  foreach (k, v in member_data) {
    if (k in myExtDataRW) {
      myExtDataRW[k].update(v)
    }
  }
}

let function reset() {
  squadId(null)
  isInvitedToSquad({})

  if (squadSharedData.squadChat.value != null) {
    squadChatJoined(false)
    let chat_id = squadSharedData.squadChat.value?.chatId
    leaveChat(chat_id, null)
    if (chat_id)
      leave_voice_chat(voiceChatId(chat_id))
  }

  foreach (w in squadSharedData)
    w.update(null)
  foreach (w in squadServerSharedData)
    w.update(null)

  foreach (member in squadMembers.value) {
    setOnlineBySquad(member.userId, null)
    sendEvent(notifyMemberRemoved, member.userId)
  }
  squadMembers.update({})
  delayedInvites(null)

  myExtSquadData.ready(false)
  myDataRemote({})
}

let function setSquadLeader(squadIdVal){
  squadMembers.mutate(function(s){
    foreach (uid, member in s){
      s[uid].isLeader = member.userId == squadIdVal
    }
  })
}
squadId.subscribe(setSquadLeader)
setSquadLeader(squadId.value)

let function removeInvitedSquadmate(user_id) {
  if (!(user_id in isInvitedToSquad.value))
    return false
  isInvitedToSquad.mutate(@(value) delete value[user_id])
  return true
}

let function addInvited(user_id) {
  if (user_id in isInvitedToSquad.value)
    return false
  isInvitedToSquad.mutate(@(value) value[user_id] <- true)
  validateNickNames([Contact(user_id.tostring())])
  return true
}

let function applySharedData(dataTable) {
  if (!isInSquad.value)
    return

  foreach (key, w in squadServerSharedData)
    if (key in dataTable)
      w.update(dataTable[key])

  if (!isSquadLeader.value)
    foreach (key, w in squadSharedData)
      w.update(squadServerSharedData[key].value)
}

let function checkDisbandEmptySquad() {
  if (squadMembers.value.len() == 1 && !isInvitedToSquad.value.len())
    MSquadAPI.disbandSquad()
}

let function revokeSquadInvite(user_id) {
  if (!removeInvitedSquadmate(user_id))
    return

  MSquadAPI.revokeInvite(user_id)
  checkDisbandEmptySquad()
}

let function revokeAllSquadInvites() {
  foreach (uid, _ in isInvitedToSquad.value)
    revokeSquadInvite(uid)
}

let function leaveSquadSilent(cb = null) {
  if (!isInSquad.value) {
    cb?()
    return
  }

  if (squadMembers.value.len() == 1)
    revokeAllSquadInvites()

  sessionManager.leave()
  MSquadAPI.leaveSquad({ onAnyResult = function(...) {
    reset()
    cb?()
  }})
}

let showSizePopup = @(text, isError = true)
    popupsState.addPopup({ id = "squadSizePopup", text = text, styleName = isError ? "error" : "" })


let requestMemberData = @(uid, isMe,  isNewMember, cb = @(_res) null)
  MSquadAPI.getMemberData(uid,
    { onSuccess = function(response) {
        let member = squadMembers.value?[uid]
        if (member) {
          let data = applyRemoteDataToSquadMember(member, response)
          if (isMe && data)
            setSelfRemoteData(data)
          if (isNewMember) {
            sendEvent(notifyMemberAdded, uid)
          }
        }
        squadMembers.trigger()
        cb(response)
      }
    })

let function updateSquadInfo(squad_info) {
  if (squadId.value != squad_info.id)
    return

  foreach (uid in squad_info.members) {
    local isNewMember = false
    let isMe = (uid == selfUid.value)
    if (uid not in squadMembers.value) {
      if (isMe && squad_info.members.len() > availableSquadMaxMembers.value) {
        logSq("Leave from squad, right after join. Squad was already full.")
        leaveSquadSilent(@() showSizePopup(loc("squad/popup/squadFull")))
        continue
      }

      let sMember = SquadMember(uid)
      squadMembers.mutate(@(m) m[uid] <- sMember)
      removeInvitedSquadmate(uid)
      isNewMember = true
      if (isMe) {
        requestMemberData(uid, isMe, isNewMember)
        continue
      }
    }

    requestMemberData(uid, isMe, isNewMember)
  }
  squadMembers.trigger()

  foreach (uid in squad_info?.invites ?? [])
    addInvited(uid)

  if (squad_info?.data)
    applySharedData(squad_info.data)

  isSquadDataInited(true)
}

local fetchSquadInfo = null

let function acceptInviteImpl(invSquadId) {
  if (!checkMultiplayerPermissions()){
    logSq("accept squad invitation is not allowed because of multiplayer permissions")
    return
  }
  MSquadAPI.acceptInvite(invSquadId,
      { onSuccess = function(...) {
          squadId.update(invSquadId)
          fetchSquadInfo()
        }
        onFailure = function(resp) {
          let errId = resp?.error_id ?? ""
          msgbox.show({
            text = loc($"squad/nonAccepted/{errId}",
              ": ".concat(loc("squad/inviteError"), errId)) })
          eventbus.send("ipc.squadIsFull", null)
          logSq("sessionManager.leave on mpi.acceptinvite failure")
          sessionManager.leave()
        }
      })
}

let function acceptSquadInvite(invSquadId) {
  if (!isInSquad.value)
    acceptInviteImpl(invSquadId)
  else
    leaveSquadSilent(@() acceptInviteImpl(invSquadId))
}

let function processSquadInvite(contact) {
  // we are already in that squad. do nothing
  if (isInSquad.value && squadId.value == contact.value.uid) {
    return
  }

  pushNotification({
    id = getSquadInviteUid(contact.value.uid)
    inviterUid = contact.value.uid
    styleId = "toBattle"
    text = loc("squad/invite", {playername=getContactNick(contact)})
    actionsGroup = INVITE_ACTION_ID
    needPopup = true
  })
}

let function onInviteRevoked(inviterSquadId, invitedMemberId) {
  if (inviterSquadId == squadId.value)
    removeInvitedSquadmate(invitedMemberId)
  else
    removeNotifyById(getSquadInviteUid(inviterSquadId))
}

let function addInviteByContact(inviter) {
  if (inviter.value.uid == selfUid.value) // skip self invite
    return

  if (inviter.value.userId in blockedUids.value) {
    logSq("got squad invite from blacklisted user", inviter.value)
    MSquadAPI.rejectInvite(inviter.value.uid)
    return
  }

  if (!canInterractCrossPlatformByCrossplay(inviter.value.realnick, crossnetworkPlay.value)) {
    logSq($"got squad invite from crossplatform user, is crosschat available: {crossnetworkChat.value}", inviter.value)
    MSquadAPI.rejectInvite(inviter.value.uid)
    return
  }

  if (consoleCompare.xbox.isPlatform && consoleCompare.xbox.isFromPlatform(inviter.value.realnick)) {
    logSq("got squad invite from xbox player. It will be silently accepted or hidden", inviter.value)
    return
  }

  processSquadInvite(inviter)
}

let function onInviteNotify(invite_info) {
  if ("invite" in invite_info) {
    let uid = invite_info?.leader.id
    let inviter = uid != null ? Contact(invite_info.leader.id.tostring(), invite_info?.leader.name) : null

    if (invite_info.invite.id == selfUid.value) {
      if (inviter!=null)
        addInviteByContact(inviter)
    }
    else
      addInvited(invite_info.invite.id)
  }
  else if ("replaces" in invite_info) {
    onInviteRevoked(invite_info.replaces, selfUid.value)
    let uid = invite_info?.leader.id.tostring()
    if (uid != null)
      addInviteByContact(Contact(uid))
  }
}


fetchSquadInfo = function(cb = null) {
  MSquadAPI.getSquadInfo({
    onAnyResult = function (result) {
      if (result.error != 0) {
        if (result?.error_id == "NOT_SQUAD_MEMBER")
          squadId.update(null)
        if (cb)
          cb(result)
        return
      }

      if ("squad" in result) {
        squadId.update(result.squad.id)
        updateSquadInfo(result.squad)
        if (cb)
          cb(result)
      }

      let validateList = (result?.invites ?? []).map(@(id) Contact(id.tostring()))

      validateNickNames(validateList, function() {
        foreach (sender in validateList)
          addInviteByContact(sender)
      })
    }
  })
}

let function onMemberDataChanged(user_id, request) {
  let member = squadMembers.value?[user_id]
  if (member == null)
    return

  let data = applyRemoteDataToSquadMember(member, request)
  let isMe = (user_id == selfUid.value)
  if (isMe && data)
    setSelfRemoteData(data)
  squadMembers.trigger()
}

let function addMember(member) {
  let userId = member.userId
  logSq("addMember", userId, member.name)

  let squadMember = SquadMember(member.userId)
  let realnick = Contact(member.userId.tostring()).value.realnick
  squadMember.realnick = realnick
  setOnlineBySquad(squadMember.userId, true)
  removeInvitedSquadmate(member.userId)

  squadMembers.mutate(@(val) val[userId] <- squadMember)
  sendEvent(notifyMemberAdded, userId)

  if (squadMembers.value.len() == availableSquadMaxMembers.value && isInvitedToSquad.value.len() > 0 && isSquadLeader.value) {
    revokeAllSquadInvites()
    showSizePopup(loc("squad/squadIsReadyExtraInvitesRevoken"))
  }
}

let function removeMember(member) {
  let userId = member.userId

  if (userId == selfUid.value) {
    msgbox.show({
        text = loc("squad/kickedMsgbox")
      })
    reset()
  }
  else if (userId in squadMembers.value) {
    let m = squadMembers.value[userId]
    setOnlineBySquad(m.userId, null)
    if (userId in squadMembers.value) //function above can clear userid
      squadMembers.mutate(@(v) delete v[userId])
    sendEvent(notifyMemberRemoved, userId)
    checkDisbandEmptySquad()
  }
}

  // public methods
let function leaveSquad(cb = null) {
  msgbox.show({
    text = loc("squad/leaveSquadQst")
    buttons = [
      { text = loc("Yes"), action = @() leaveSquadSilent(cb) }
      { text = loc("No") }
    ]
  })
}

let function dismissSquadMember(user_id) {
  let member = squadMembers.value?[user_id]
  if (!member)
    return
  msgbox.show({
    text = loc("squad/kickPlayerQst", { name = getContactNick(Contact(member.userId.tostring())) })
    buttons = [
      { text = loc("Yes"), action = @() MSquadAPI.dismissMember(user_id) }
      { text = loc("No"), isCancel = true, isCurrent = true }
    ]
  })
}

let function dismissAllOfflineSquadmates() {
  if (!isSquadLeader.value)
    return
  foreach (member in squadMembers.value){
    if (!isContactOnline(member.userId.tostring(), onlineStatus.value))
      MSquadAPI.dismissMember(member.userId)
  }
}

let function transferSquad(user_id) {
  let is_leader = isSquadLeader.value
  MSquadAPI.transferSquad(user_id,
  {
    onSuccess = function(_) {
      squadId.update(user_id)
      if (is_leader) {
        sessionManager.updateData(user_id)
      }
    }
  })
}

let function createSquadAndDo(afterFunc = null) {
  if (isInSquad.value) {
    logSq($"CreateSquadAndDo: don't create squad, do action")
    afterFunc?()
    return
  }

  if (afterFunc)
    delayedInvites([afterFunc])

  let inviteDelayed = function() {
    if (delayedInvites.value == null)
      return
    foreach (f in delayedInvites.value)
      f()
    delayedInvites(null)
  }

  let cleanupDelayed = @() delayedInvites(null)

  MSquadAPI.createSquad({
    onSuccess = @(_)
      fetchSquadInfo(
        function(r) {
          if (r.error != 0) {
            cleanupDelayed()
            return
          }

          if (sessionManager.isAvailableConsoleSession)
            sessionManager.create(squadId.value, inviteDelayed)
          else
            inviteDelayed()

          createChat(function(chat_resp) {
            if (chat_resp.error == 0) {
              squadChatJoined(true)
              squadSharedData.squadChat({
                chatId = chat_resp.chatId
                chatKey = chat_resp.chatKey
              })
            }
          })
        }
      )
    onFailure = @(_) cleanupDelayed()
  })
}

let function inviteToSquad(user_id, needConsoleInvite = true) {
  if (!checkMultiplayerPermissions()){
    logSq("invite to squad is not allowed because of multiplayer permissions")
    return
  }
  if (isInSquad.value) {
    if (user_id in squadMembers.value) {// user already in squad
      logSq($"Invite: member {user_id}: already in squad")
      return
    }

    if (squadMembers.value.len() >= availableSquadMaxMembers.value) {
      logSq($"Invite: member {user_id}: squad already full")
      return showSizePopup(loc("squad/popup/squadFull"))
    }

    if (squadMembers.value.len() + isInvitedToSquad.value.len() >= availableSquadMaxMembers.value + SQUAD_OVERDRAFT) {
      logSq($"Invite: member {user_id}: too many invites")
      return showSizePopup(loc("squad/popup/tooManyInvited"))
    }
  }

  if (!hasValidBalance.value) {
    logSq($"Invite: member {user_id}: negative balance")
    return showSizePopup(loc("gameMode/negativeBalance"))
  }

  let _doInvite = function() {
    MSquadAPI.invitePlayer(user_id, {
      onFailure = function(resp) {
        let errId = resp?.error_id ?? ""
        showSizePopup(loc($"error/{errId}"), false)
      }
    })
  }

  local doInvite = _doInvite
  if (needConsoleInvite && sessionManager.isAvailableConsoleSession && uid2console.value?[user_id.tostring()] != null)
    doInvite = @() sessionManager.invite(user_id, _doInvite)

  if (delayedInvites.value != null) { // squad is creating now
    delayedInvites.mutate(@(inv) inv.append(doInvite))
    logSq($"Invite: member {user_id}: saved to delayed. Postpone")
    return
  }

  createSquadAndDo(doInvite)
}

local isSharedDataRequestInProgress = false
let function syncSharedDataImpl() {
  let function isSharedDataDifferent() {
    foreach (key, w in squadSharedData)
      if (w.value != squadServerSharedData[key].value)
        return true
    return false
  }

  if (isSharedDataRequestInProgress || !isSquadLeader.value || !isSharedDataDifferent())
    return

  let thisFunc = callee()
  isSharedDataRequestInProgress = true
  let requestData = squadSharedData.map(@(w) w.value)
  MSquadAPI.setSquadData(requestData,
    { onSuccess = function(_res) {
        isSharedDataRequestInProgress = false
        applySharedData(requestData)
        thisFunc()
      }
      onFailure = function(_res) {
        isSharedDataRequestInProgress = false
      }
    })
}

local syncSharedDataTimer = null
let function syncSharedData(...) {
  if (syncSharedDataTimer || !isSquadLeader.value)
    return
  //wait for more changes in shared data before sync it with server
  syncSharedDataTimer = function() {
    gui_scene.clearTimer(syncSharedDataTimer)
    syncSharedDataTimer = null
    syncSharedDataImpl()
  }
  gui_scene.setInterval(0.1, syncSharedDataTimer)
}

foreach (w in squadSharedData)
  w.subscribe(syncSharedData)

subscribeGroup(INVITE_ACTION_ID, {
  onShow = @(notify) msgbox.show(hasValidBalance.value ? {
    text = loc("squad/acceptInviteQst")
    buttons = [
      { text = loc("Yes"), isCurrent = true,
        function action() {
          removeNotify(notify)
          acceptSquadInvite(notify.inviterUid)
        }
      }
      { text = loc("No"), isCancel = true,
        function action() {
          removeNotify(notify)
          MSquadAPI.rejectInvite(notify.inviterUid)
        }
      }
    ]
  } : {
    text = loc("gameMode/negativeBalance")
    buttons = [
      { text = loc("Ok"), isCurrent = true,
        function action() {
          removeNotify(notify)
          MSquadAPI.rejectInvite(notify.inviterUid)
        }
      }
    ]
  })

  onRemove = @(notify) MSquadAPI.rejectInvite(notify.inviterUid)
})

let function requestJoinSquad(userId) {
  MSquadAPI.requestJoin(userId, {
    onSuccess = function(...) {
      squadId.update(userId)
      fetchSquadInfo()
    },
    onFailure = @(resp) logSq($"Failed to join squad {userId}", resp)
  })
}

let function onAcceptMembership(newContact) {
  let { realnick, uid } = newContact.value
  logSq($"Squad application notification from {uid}/{realnick}")
  if ((consoleCompare.xbox.isFromPlatform(realnick)
      || consoleCompare.psn.isFromPlatform(realnick)) && isSquadLeader.value) {
    logSq($"Accepting squad membership from {uid}")
    MSquadAPI.acceptMembership(uid)
  } else {
    logSq($"Not squad leader or request was performed from {realnick} non-(xbox or psn) platform. Skipping.")
  }
}

let function onApplicationNotify(params) {
  let applicant = params?.applicant
  let uid = applicant?.id
  let contactUid = uid?.tostring()
  if (uid) {
    let newContact = Contact(contactUid)
    validateNickNames([newContact], @() onAcceptMembership(newContact))
  }
  else
    println($"incorrect uid on contact creation, {uid}")
}


let function onApplicationAccept(params) {
  let sid = params?.squad?.id
  logSq($"Squad membership application accepted for squad {sid}")
  squadId.update(sid)
  fetchSquadInfo()
}

let function onSquadCreated(params) {
  let sid = params?.requestBy?.userId
  logSq($"Squad created, requested by {sid}")
  squadId.update(sid)
  fetchSquadInfo()
}

let msubscribes = {
  ["msquad.notify_invite"] = onInviteNotify,
  ["msquad.notify_invite_revoked"] = function(params) {
    if (params?.squad?.id != null && params?.invite?.id != null)
      onInviteRevoked(params.squad.id, params.invite.id)
  },
  ["msquad.notify_invite_rejected"] = function(params) {
    if (isSquadLeader.value) {
      let contact = Contact(params.invite.id.tostring())
      removeInvitedSquadmate(contact.value.uid)
      pushNotification({ text = loc("squad/mail/reject", {playername = getContactNick(contact) })})
    }
  },
  ["msquad.notify_invite_expired"] = @(params) removeInvitedSquadmate(params.invite.id),
  ["msquad.notify_disbanded"] = function(_params) {
    sessionManager.leave()
    if (!isSquadLeader.value) {
      msgbox.show({text = loc("squad/msgbox_disbanded")})
    }
    reset()
  },
  ["msquad.notify_member_joined"] = addMember,
  ["msquad.notify_member_leaved"] = removeMember,
  ["msquad.notify_leader_changed"] = function(params) {
    squadId.update(params.userId)
    if (isSquadLeader.value) {
      sessionManager.updateData(params.userId)
    }
  },
  ["msquad.notify_data_changed"] = function(_params){
    if (isInSquad.value)
      fetchSquadInfo()
  },
  ["msquad.notify_member_data_changed"] = function(params) {
    MSquadAPI.getMemberData(params.userId,
        { onSuccess = @(response) onMemberDataChanged(params.userId, response) })
  },
  ["msquad.notify_member_logout"] = function(params) {
    let {userId} = params
    if (userId not in squadMembers.value)
      return
    setOnlineBySquad(userId, false)
    squadMembers.mutate(function(s){
      s[userId].state.ready <- false
    })
  },
  ["msquad.notify_member_login"] = function(params) {
    let member = squadMembers.value?[params.userId]
    if (member){
      logSq("member", params.userId, "going to online")
      setOnlineBySquad(member.userId, true)
    }
  },
  ["msquad.notify_squad_created"] = onSquadCreated,
  ["msquad.notify_application"] = onApplicationNotify,
  ["msquad.notify_application_accepted"] = onApplicationAccept,
  ["msquad.notify_application_revoked"] = function(...) {},
  ["msquad.notify_application_denied"] = function(...) {}
}

foreach (k, v in msubscribes) {
  matching_api.listen_notify(k)
  eventbus.subscribe(k, v)
}

eventbus.subscribe("matching.logged_out", @(...) reset())
eventbus.subscribe("matching.logged_in", function(...) {
  reset()
  fetchSquadInfo(@(val) logSq(val))
})

squadSharedData.squadChat.subscribe(function(value) {
  if (value != null) {
    if (!squadChatJoined.value) {
      joinChat(value?.chatId, value?.chatKey,
      function (resp) {
        if (resp.error == 0)
          squadChatJoined(false)
      })
    }
    if (value?.chatId)
      join_voice_chat(voiceChatId(value.chatId))
  }
})

let squadOnlineMembers = Computed(@() squadMembers.value.filter(@(m) isContactOnline(m.userId.tostring(), onlineStatus.value)))

let unsuitableCrossplayConditionMembers = Computed(function() {
  let myCPState = crossnetworkPlay.value
  let res = []
  foreach (m in squadOnlineMembers.value) {
    let curPlayerCPState = m.state?.crossnetworkPlay
    if (curPlayerCPState in CrossPlayStateWeight
        && userInfo.value?.name != m.state?.realnick
        && CrossPlayStateWeight[curPlayerCPState] != CrossPlayStateWeight[myCPState])
      res.append(m)
  }

  return res
})

let getUnsuitableVersionConditionMembers = @(gameMode) squadOnlineMembers.value.filter(function(m) {
  let curPlayerVersion = m.state?.version
  let { reqVersion = null } = gameMode
  return curPlayerVersion != null
    && reqVersion != null
    && !check_version(reqVersion, curPlayerVersion)
})

return squadState.__merge({
  // state
  squadOnlineMembers
  unsuitableCrossplayConditionMembers
  getUnsuitableVersionConditionMembers

  // functions
  bindSquadROVar
  bindSquadRWVar
  inviteToSquad
  dismissAllOfflineSquadmates
  revokeAllSquadInvites
  leaveSquad
  leaveSquadSilent
  transferSquad
  dismissSquadMember

  removeInvitedSquadmate
  revokeSquadInvite
  acceptSquadInvite
  requestJoinSquad

  // events
  subsMemberAddedEvent = @(func) notifyMemberAdded.append(func)
  subsMemberRemovedEvent = @(func) notifyMemberRemoved.append(func)
})