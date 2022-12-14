import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {DC_CONNECTION_LOST, DC_CONNECTION_CLOSED, EventOnNetworkDestroyed, EventOnConnectedToServer, EventOnDisconnectedFromServer} = require("net")
let { DBGLEVEL } = require("dagor.system")
let { logerr } = require("dagor.debug")
let { system = null } = require_optional("system")
let { get_game_name, get_circuit } = require("app")
let { encodeString } = require("base64")
let json = require("%sqstd/json.nut")

let userInfo = require("%enlSqGlob/userInfo.nut")
let { matchingCall, netStateCall } = require("%enlist/matchingClient.nut")
let { oneOfSelectedClusters } = require("%enlist/clusterState.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { startGame } = require("%enlist/gameLauncher.nut")
let matching_api = require("matching.api")
let msgbox = require("%ui/components/msgbox.nut")
let { isInQueue } = require("%enlist/state/queueState.nut")
let loginChain = require("%enlist/login/login_chain.nut")
let {leaveChat, createChat, joinChat} = require("%enlist/chat/chatApi.nut")
let {clearChatState} = require("%enlist/chat/chatState.nut")
let voiceState = require("%enlist/voiceChat/voiceState.nut")
let {checkMultiplayerPermissions} = require("%enlist/permissions/permissions.nut")
let {squadId} = require("%enlist/squad/squadState.nut")
let eventbus = require("eventbus")
let {MatchingRoomExtraParams} = require("dasevents")
let { OK, error_string } = require("matching.errors")
let { pushNotification, removeNotify, subscribeGroup
} = require("%enlist/mainScene/invitationsLogState.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")

const INVITE_ACTION_ID = "room_invite_action"
let LobbyStatus = {
  ReadyToStart = "ready_to_launch"
  NotEnoughPlayers = "not_enough_players"
  CreatingGame = "creating_game"
  WaitingBeforeLauch = "waiting_before_launch"
  GameInProgress = "game_in_progress"
  GameInProgressNoLaunched = "game_in_progress_no_launched"
  WaitForDedicatedStart = "wait_for_dedicated_start"
  TeamsDisbalanced = "teams_disbalanced"
  SceneLoadFailure = "scene_load_failure"
}

let ServerLauncherState = {
  Launching = "launching"
  Launched = "launched"
  WaitingForHost = "waiting_for_host"
  HostNotFound = "host_not_found"
  NoSession = "no_session"
}

let room = mkWatched(persist, "room", null)
let roomPasswordToJoin = mkWatched(persist, "roomPasswordToJoin", {})
let roomInvites = mkWatched(persist, "roomInvites", [])
let roomMembers = mkWatched(persist, "roomMembers", [])
let roomIsLobby = mkWatched(persist, "roomIsLobby", false)
let connectAllowed = mkWatched(persist, "connectAllowed", null)
let hostId  = mkWatched(persist, "hostId", null)
let chatId = mkWatched(persist, "chatId", null)
let squadVoiceChatId = mkWatched(persist, "squadVoiceChatId", null)
let doConnectToHostOnHostNotfy = mkWatched(persist, "doConnectToHostOnHostNotfy", true)
let lobbyLauncherState = Computed(@() room.value?.public.launcherState ?? "no_session")
let myInfoUpdateInProgress = Watched(false)
let playersWaitingResponseFor = Watched({})
let joinedRoomWithInvite = Watched(false)

let canStartWithLocalDedicated = DBGLEVEL > 0 && system != null
  ? Computed(@() roomIsLobby.value && room.value?.public != null)
  : Computed(@() false)

let lastRoomResult = mkWatched(persist, "lastRoomResult", null)
let lastSessionStartData = mkWatched(persist, "lastSessionStartData", null)
let isWaitForDedicatedStart = Watched(false)
let lobbyStatus = Computed(function() {
  if (isWaitForDedicatedStart.value)
    return LobbyStatus.WaitForDedicatedStart
  let launcherState = lobbyLauncherState.value
  if (launcherState == LobbyStatus.NotEnoughPlayers)
    return LobbyStatus.NotEnoughPlayers
  if (launcherState == LobbyStatus.WaitingBeforeLauch)
    return LobbyStatus.WaitingBeforeLauch
  if (launcherState == LobbyStatus.TeamsDisbalanced)
    return LobbyStatus.TeamsDisbalanced
  if (launcherState == LobbyStatus.SceneLoadFailure)
    return LobbyStatus.SceneLoadFailure
  if (launcherState == ServerLauncherState.Launching
      || launcherState == ServerLauncherState.WaitingForHost)
    return LobbyStatus.CreatingGame
  if (launcherState == ServerLauncherState.Launched)
    return isInBattleState.value ? LobbyStatus.GameInProgress
      : !connectAllowed.value ? LobbyStatus.CreatingGame
      : LobbyStatus.GameInProgressNoLaunched
  return LobbyStatus.ReadyToStart
})

roomIsLobby.subscribe(@(val) log($"roomIsLobby {val}"))

let myMemberInfo = Computed(function() {
  let { userId = null } = userInfo.value
  return roomMembers.value.findvalue(@(m) m.userId == userId)
})
let canOperateRoom = Computed(@() myMemberInfo.value?.public.operator ?? false)

let getRoomMember =  @(user_id) roomMembers.value.findvalue(@(member) member.userId == user_id)
let hasSquadMates =  @(squad_id) roomMembers.value.findvalue(@(member) member.public?.squadId == squad_id) != null

let function cleanupRoomState() {
  log("cleanupRoomState")
  room.update(null)
  playersWaitingResponseFor({})
  roomInvites.update([])
  roomMembers.update([])
  roomIsLobby.update(false)
  hostId.update(null)
  connectAllowed.update(null)
  isWaitForDedicatedStart(false)
  if (chatId.value != null) {
    leaveChat(chatId.value, null)
    clearChatState(chatId.value)
    chatId(null)
  }

  if (squadVoiceChatId.value != null) {
    voiceState.leave_voice_chat(squadVoiceChatId.value)
    squadVoiceChatId(null)
  }
}

let function addRoomMember(member) {
  if (member.public?.host) {
    log("found host ", member.name,"(", member.userId,")")
    hostId(member.userId)
  }

  member.nameText <- remap_others(member.name)
  roomMembers.mutate(@(value) value.append(member))
  return member
}

let function removeRoomMember(user_id) {
  roomMembers(roomMembers.value.filter(@(member) member.userId != user_id))

  if (user_id == hostId.value) {
    log("host leaved from room")
    hostId.update(null)
    connectAllowed.update(null)
  }

  if (user_id == userInfo.value?.userId)
    cleanupRoomState()
}

let function makeCreateRoomCb(user_cb) {
  return function(response) {
    if (response.error != 0) {
      log("failed to create room:", error_string(response.error))
    } else {
      roomIsLobby(true)

      if (response?.public.creator && response.public.creator != "")
        response.public.creatorText <- remap_others(response.public.creator)

      room.update(response)
      log("you have created the room", response.roomId)
      foreach (member in response.members)
        addRoomMember(member)
    }

    if (squadId.value != null) {
      matchingCall("mrooms.set_member_attributes", null, {
                        public = {
                          squadId = squadId.value
                        }
                      })
    }

    if (user_cb)
      user_cb(response)
  }
}

let function createRoom(params, user_cb) {
  createChat(function(chat_resp) {
    if (chat_resp.error == 0) {
      params.public.chatId <- chat_resp.chatId
      params.public.chatKey <- chat_resp.chatKey
      chatId(chat_resp.chatId)
    }
    matchingCall("mrooms.create_room", makeCreateRoomCb(user_cb), params)
  })
}
let function changeAttributesRoom(params, user_cb) {
  matchingCall("mrooms.set_attributes", user_cb, params)
}

let delayedMyAttribs = mkWatched(persist, "delayedMyAttribs", null)
let function setMemberAttributes(params) {
  if (myInfoUpdateInProgress.value) {
    delayedMyAttribs(params)
    return
  }
  myInfoUpdateInProgress(true)
  delayedMyAttribs(null)
  let self = callee()
  matchingCall("mrooms.set_member_attributes",
    function(_res) {
      myInfoUpdateInProgress(false)
      if (delayedMyAttribs.value != null)
        self(delayedMyAttribs.value)
    },
    params)
}

let function makeLeaveRoomCb(user_cb) {
  return function(response) {
    if (response.error != 0) {
      log("failed to leave room:", error_string(response.error))
      response.error = 0
      cleanupRoomState()
    }

    if (room.value) {
      log("you left the room", room.value.roomId)
    }

    if (user_cb)
      user_cb(response)
  }
}

let function leaveRoom(user_cb = null) {
  if (isInBattleState.value) {
    if (user_cb != null)
      user_cb({error = "Can't do that while game is running"})
    return
  }

  matchingCall("mrooms.leave_room", makeLeaveRoomCb(user_cb))
}

let function forceLeaveRoom() {
  matchingCall("mrooms.leave_room", makeLeaveRoomCb(null))
}

let function destroyRoom(user_cb) {
  if (isInBattleState.value) {
    if (user_cb != null)
      user_cb({error = "Can't do that while game is running"})
    return
  }

  matchingCall("mrooms.destroy_room", makeLeaveRoomCb(user_cb))
}

let function makeJoinRoomCb(lobby, user_cb) {
  return function(response) {

    if (response.error != 0) {
      log("failed to join room:", error_string(response.error))
    }
    else {
      roomIsLobby(lobby)

      room.update(response)
      let roomId = response.roomId
      log("you joined room", roomId)
      foreach (member in response.members)
        addRoomMember(member)

      let newChatId = room.value?.public.chatId
      if (newChatId) {
        joinChat(newChatId, room.value.public.chatKey,
        function(chat_resp) {
          if (chat_resp.error == 0)
            chatId(newChatId)
        })
      }

      let squadSelfMember = getRoomMember(userInfo.value?.userId)
      let selfSquadId = squadSelfMember?.public?.squadId
      if (selfSquadId != null && hasSquadMates(selfSquadId)) {
        squadVoiceChatId($"__squad_${selfSquadId}_room_${roomId}")
        voiceState.join_voice_chat(squadVoiceChatId.value)
      }
    }

    if (user_cb)
      user_cb(response)
  }
}

let function joinRoom(params, lobby, user_cb) {
  if (!checkMultiplayerPermissions()) {
    log("no permissions to join lobby")
    return
  }
  netStateCall(function() {
    matchingCall("mrooms.join_room", makeJoinRoomCb(lobby, user_cb), params)
  })

}

let function makeStartSessionCb(user_cb) {
  return function(response) {
    if (user_cb)
      user_cb(response)
  }
}

let function startSession(user_cb) {
  let params = {
    cluster = oneOfSelectedClusters.value
  }
  matchingCall("mrooms.start_session", makeStartSessionCb(user_cb), params)
}

let function startSessionWithLocalDedicated(user_cb, loadTimeout = 30.0) {
  if (!canStartWithLocalDedicated.value) {
    logerr("Try to start local dedicated when it not allowed")
    return
  }
  let { scene = null, modHash = "" } = room.value?.public
  if (scene == null && modHash == "") {
    logerr("Trying to start local dedicated server with no scene or mod selected")
    return
  }

  let cmdText = "@start win32/{game}-ded-dev --listen -game:{game} -config:circuit:t={circuit} -config:scene:t={scene} -invite_data={inviteData} -noeac -nonetenc"
    .subst({
      game = get_game_name()
      circuit = get_circuit()
      scene
      inviteData = encodeString(json.to_string({ mode_info = room.value.public }, false))
    })
  log("Start local dedicated: ", cmdText)
  system(cmdText)
  isWaitForDedicatedStart(true)
  gui_scene.setTimeout(loadTimeout, function() {
    if (!isWaitForDedicatedStart.value)
      return
    isWaitForDedicatedStart(false)
    matchingCall("mrooms.start_session", makeStartSessionCb(user_cb), { cluster = "debug" })
  })
}

let function onRoomDestroyed(_notify) {
  cleanupRoomState()
}

let function connectToHost() {
  if (hostId.value == null)
    return

  if (!checkMultiplayerPermissions()) {
    log("no permissions to join network game")
    return
  }

  if (!connectAllowed.value) {
    msgbox.show({text=loc("msgboxtext/connectNotAllowed")})
    return
  }
  if (!room.value) {
    log("ConnectToHost error: room leaved while wait for callback")
    return
  }

  let launchParams = {
    host_urls = getRoomMember(hostId.value)?.public?.host_urls
    sessionId = room.value.public?.sessionId
    game = room.value.public?.gameName
    authKey = getRoomMember(userInfo.value?.userId)?.private?.auth_key
    modManifestUrl = room.value.public?.modManifestUrl ?? ""
    modHash = room.value.public?.modHash ?? ""
    baseModsFilesUrl = room.value.public?.baseModsFilesUrl ?? ""
  }

  launchParams.each(function(val, key) {
    if (val == null){
      log("ConnectToHost error: some room params are null:",key)
    }
  })

  lastSessionStartData({
    sessionId = launchParams.sessionId
    loginTime = loginChain.loginTime.value
  })
  room.mutate(@(v) v.gameStarted <- true)
  lastRoomResult(null)
  startGame(launchParams)
}

let function onDisconnectedFromServer(evt, _eid, _comp) {
  if (!roomIsLobby.value)
    forceLeaveRoom()
  if (lastSessionStartData.value == null)
    return

  local connLost = false
  switch (evt?.last_client_dc ?? evt[0]) {
    case DC_CONNECTION_LOST:
    case DC_CONNECTION_CLOSED:
      connLost = true
  }

  let { sessionId, loginTime } = lastSessionStartData.value
  lastSessionStartData(null)
  let wasRelogin = loginTime != loginChain.loginTime.value
  if (!wasRelogin && !connLost && !roomIsLobby.value) {
    matchingCall("enlmm.remove_from_match", null, { sessionId })
    lastRoomResult({ connLost, sessionId })
  }
}

let function onConnectedToServer() {
  if (room.value?.public?.extraParams == null) {
    return
  }
  let extraParams = room.value?.public?.extraParams
  ecs.g_entity_mgr.broadcastEvent(MatchingRoomExtraParams({
      routeEvaluationChance = extraParams?.routeEvaluationChance ?? 0.0,
      ddosSimulationChance = extraParams?.ddosSimulationChance ?? 0.0,
      ddosSimulationAddRtt = extraParams?.ddosSimulationAddRtt ?? 0,
  }));
}

ecs.register_es("enlist_disconnected_from_server_es", {
  [EventOnDisconnectedFromServer] = onDisconnectedFromServer,
  [EventOnNetworkDestroyed] = onDisconnectedFromServer,
})
ecs.register_es("enlist_connected_to_server_es", {
  [EventOnConnectedToServer] = onConnectedToServer,
})

let function onHostNotify(notify) {
  log("onHostNotify", notify)
  if (notify.hostId != hostId.value) {
    log($"warning: got host notify from host that is not in current room {notify.hostId} != {hostId.value}")
    return
  }

  if (notify.roomId != room.value?.roomId) {
    log("warning: got host notify for wrong room")
    return
  }

  if (notify.message == "connect-allowed")
    connectAllowed(true)

  if (doConnectToHostOnHostNotfy.value || isWaitForDedicatedStart.value) {
    isWaitForDedicatedStart(false)
    connectToHost()
  }
}

let function onRoomMemberJoined(notify) {
  if (notify.roomId != room.value?.roomId)
    return
  log("{0} ({1}) joined room".subst(notify.name, notify.userId))
  if (notify.userId != userInfo.value?.userId) {
    let newmember = addRoomMember(notify)
    if (squadVoiceChatId.value == null) {
      let squadSelfMember = getRoomMember(userInfo.value?.userId)
      let selfSquadId = squadSelfMember?.public?.squadId
      if (selfSquadId != null && selfSquadId == newmember?.squadId) {
        let roomId = room.value.roomId
        squadVoiceChatId($"__squad_${selfSquadId}_room_${roomId}")
        voiceState.join_voice_chat(squadVoiceChatId.value)
      }
    }
  }
}

let function onRoomMemberLeft(notify) {
  if (notify.roomId != room.value?.roomId)
    return
  log("{0} ({1}) left from room".subst(notify.name, notify.userId))
  removeRoomMember(notify.userId)
}

let function onRoomMemberKicked(notify) {
  removeRoomMember(notify.userId)
}

let function merge_attribs(upd_data, attribs) {
  foreach (key, value in upd_data) {
    if (value == null) {
      if (key in attribs)
        delete attribs[key]
    }
    else
      attribs[key] <- value
  }
  return attribs
}

let function onRoomAttrChanged(notify) {
  if (!room.value)
    return

  room.mutate(function(roomVal){
    let pub = notify?.public
    let priv = notify?.private
    if (typeof pub == "table")
      merge_attribs(pub, roomVal.public)
    if (typeof priv == "table")
      merge_attribs(priv, roomVal.private)
    return roomVal
  })
}

let function onRoomMemberAttrChanged(notify) {
  if (!roomMembers.value)
    return

  roomMembers.mutate(function(membs) {
    let idx = membs.findindex(@(m) m.userId == notify?.userId)
    if (idx == null)
      return membs
    let member = clone membs[idx]
    let pub = notify?["public"]
    let priv =notify?["private"]
    if (typeof pub == "table")
      member.public <- merge_attribs(pub, clone member.public)
    if (typeof priv == "table")
      member.private <- merge_attribs(priv, clone member.private)
    membs[idx] = member
    return membs
  })
}

let canInviteToRoom = Computed(@() room.value != null
  && (room.value?.public.slotsCnt ?? 0) < (room.value?.public.maxPlayers ?? 0))

let function isInMyRoom(newMemberId){
  return roomMembers.value.findvalue(@(member) member.userId == newMemberId) != null
}

let function joinCb(response) {
  let err = response.error
  if (err != OK) {
    let errStr = error_string(err)
    showMsgbox({ text = loc("msgbox/failedJoinRoom", {
      error = loc($"error/{errStr}", errStr)
    }) })
  }
}

subscribeGroup(INVITE_ACTION_ID, {
  onShow = @(notify) msgbox.show({
    text = loc("squad/acceptInviteQst")
    buttons = [
      { text = loc("Yes"), isCurrent = true,
        function action() {
          if (room.value != null)
            return
          let roomId = notify.roomId.tointeger()
          let { userId = null } = userInfo.value
          let params = { roomId }
          if (roomId in roomPasswordToJoin.value)
            params.password <- roomPasswordToJoin.value[roomId]
          joinRoom(params, true, joinCb)
          notify.send_resp({ accept = true, user_id = userId })
          joinedRoomWithInvite(true)
          removeNotify(notify)
        }
      }
      { text = loc("No"), isCancel = true,
        function action() {
          let { userId = null } = userInfo.value
          removeNotify(notify)
          notify.send_resp({ accept = false, user_id = userId })
        }
      }
    ]
  })
  onRemove = @(notify) notify.send_resp({ accept = false })
})

room.subscribe(function(v){
  if (v == null)
    joinedRoomWithInvite(false)
})

let function onRoomInvite(reqctx) {
  let request = reqctx.request
  let roomId = request.roomId
  roomInvites.mutate(@(i) i.append({
    roomId
    senderId = request.invite_data.senderId
    senderName = request.invite_data.senderName
    send_resp = @(resp) matching_api.send_response(reqctx, resp)
  }))
  if (request.invite_data?.password != null)
    roomPasswordToJoin.mutate(@(v) v[roomId] <- request.invite_data.password)

  log("got room invite from", request.invite_data.senderName)

  pushNotification({
    roomId
    inviterUid = request.invite_data.senderId
    styleId = "toBattle"
    text = loc("room/invite", {playername = request.invite_data.senderName})
    actionsGroup = INVITE_ACTION_ID
    needPopup = true
    send_resp = @(resp) matching_api.send_response(reqctx, resp)
  })
}


let function inviteToRoom(user_id){
  if (isInMyRoom(user_id) || !canInviteToRoom.value){
    log("Player can not be invited to lobby")
    return
  }
  playersWaitingResponseFor.mutate(@(v) v[user_id] <- true)
  let sendingData = { userId = user_id }
  let roomId = room.value.roomId
  if (roomId in roomPasswordToJoin.value)
    sendingData.password <- roomPasswordToJoin.value[roomId]

  matchingCall("mrooms.invite_player",
    function(player){
      playersWaitingResponseFor.mutate(@(v) player?.user_id in v
        ? delete v[player.user_id]
        : null)
    },
    sendingData)
}

let function onMatchInvite(reqctx) {
  log("got match invite from server")
  matching_api.send_response(reqctx, {})
  joinRoom(reqctx.request, false, function(_cb) {})
}

let function list_invites(){
  foreach (i, invite in roomInvites.value){
    log(
      "{0} from {1} ({2}), roomId {3}".subst(
        i, invite.senderName, invite.senderId, invite.roomId))
  }
}

let gameIsLaunching = Computed(@() !((roomIsLobby.value || !room.value) && !isInQueue.value))

console_register_command(list_invites, "mrooms.list_invites")

foreach (name, cb in {
  ["mrooms.on_room_member_joined"] = onRoomMemberJoined,
  ["mrooms.on_room_member_leaved"] = onRoomMemberLeft,
  ["mrooms.on_room_attributes_changed"] = onRoomAttrChanged,
  ["mrooms.on_room_member_attributes_changed"] = onRoomMemberAttrChanged,
  ["mrooms.on_room_destroyed"] = onRoomDestroyed,
  ["mrooms.on_room_member_kicked"] = onRoomMemberKicked,
  ["mrooms.on_host_notify"] = onHostNotify
}){
  matching_api.listen_notify(name)
  eventbus.subscribe(name, cb)
}

foreach (name, cb in {
  ["mrooms.on_room_invite"] = onRoomInvite,
  ["enlmm.on_room_invite"] = onMatchInvite,
}){
  matching_api.listen_rpc(name)
  eventbus.subscribe(name, cb)
}

eventbus.subscribe("matching.on_disconnect", @(...) cleanupRoomState())

let allowReconnect = mkWatched(persist, "allowReconnect", true)


return {
  room
  isInRoom = Computed(@() room.value != null)
  roomInvites
  roomMembers
  roomIsLobby
  lobbyStatus
  lastRoomResult
  chatId
  roomPasswordToJoin

  setMemberAttributes
  myInfoUpdateInProgress
  createRoom
  changeAttributesRoom
  joinRoom
  leaveRoom
  startSession
  canStartWithLocalDedicated
  startSessionWithLocalDedicated
  destroyRoom
  canOperateRoom
  myMemberInfo
  gameIsLaunching

  connectToHost
  connectAllowed
  allowReconnect
  doConnectToHostOnHostNotfy
  LobbyStatus

  canInviteToRoom
  isInMyRoom
  inviteToRoom
  playersWaitingResponseFor
  joinedRoomWithInvite
}
