from "%enlSqGlob/ui_library.nut" import *

let { send, sessionManager } = require("%sonyLib/webApi.nut")
let { createPushContext } = require("%sonyLib/notifications.nut")
let { encodeString, decodeString } = require("base64")
let supportedPlatforms = require("%enlist/ps4/supportedPlatforms.nut")
let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let logP = require("%enlSqGlob/library_logs.nut").with_prefix("[PSNSESSION] ")

let createSessionData = @(pushContextId, name, customData1) {
  playerSessions = [{
    supportedPlatforms = supportedPlatforms.value
    maxPlayers = 4
    maxSpectators = 0
    joinDisabled = false
    member = {
      players = [{
        accountId = "me"
        platform = "me"
        pushContexts = [{ pushContextId }]
      }]
    }
    localizedSessionName = {
      defaultLanguage = "en-US"
      localizedText = {["en-US"] = name }
    }
    joinableUserType = "NO_ONE"
    invitableUserType = "LEADER"
    exclusiveLeaderPrivileges = [
      "KICK"
      "UPDATE_JOINABLE_USER_TYPE"
      "UPDATE_INVITABLE_USER_TYPE"
    ]
    swapSupported = false
    customData1
  }]
}

let createPlayerData = @(pushContextId) {
  players = [ { accountId = "me", platform = "me", pushContexts = [{pushContextId}] } ]
}

local currentContextId = null
local currentSessionId = null


let function createSession(squadId, on_success) {
  // TODO: fix session name
  currentContextId = createPushContext()
  logP($"create with {currentContextId}")
  let desc = createSessionData(currentContextId, loc("title/name"), encodeString(squadId.tostring()))
  send(sessionManager.create(desc),
       function(r, e) {
         currentSessionId = r?.playerSessions?[0]?.sessionId
         if (e == null)
           on_success()
       })
}

let function changeLeader(leaderUid) {
  let accountId = uid2console.value?[leaderUid.tostring()]
  logP($"change leader of {currentSessionId} to {accountId}/{leaderUid}")
  if (currentSessionId && accountId)
    send(sessionManager.changeLeader(currentSessionId, accountId, "PS5"))
}

let function invite(uid, on_success) {
  let accountId = uid2console.value?[uid.tostring()]
  logP($"invite {accountId}/{uid} to {currentSessionId}")
  if (currentSessionId && accountId)
    send(sessionManager.invite(currentSessionId, [accountId]),
         function(_r, e) { if (e == null) on_success() })
}

let function join(session_id, _invitation_id, on_success) {
  currentContextId = createPushContext()
  currentSessionId = session_id
  logP($"join {currentSessionId} with {currentContextId}")
  let fetchSquadId = function(_r, _e) {
    // Intentionally ignoring error handling, try join our squad anyway
    send(sessionManager.list([session_id]), function(r, __e) {
          let encodedSquadId = r?.playerSessions?[0]?.customData1
          if (encodedSquadId)
            on_success(decodeString(encodedSquadId).tointeger())
        })
  }
  send(sessionManager.joinAsPlayer(session_id, createPlayerData(currentContextId)), fetchSquadId)
}

let function leave() {
  logP($"leave {currentSessionId}")
  if (currentSessionId != null)
    send(sessionManager.leave(currentSessionId))
  currentSessionId = null
  currentContextId = null
}

return {
  create = createSession
  update_data = changeLeader
  invite = invite
  join = join
  leave = leave
}
