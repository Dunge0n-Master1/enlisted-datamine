from "%enlSqGlob/ui_library.nut" import *

let { send, fetch, profile, getPreferredVersion } = require("%sonyLib/webApi.nut")
let { pluck } = require("%sqstd/underscore.nut")
let statsd = require("statsd")
let logPSN = require("%enlSqGlob/library_logs.nut").with_prefix("[PSN FRIENDS] ")

let fields = getPreferredVersion() == 2
  ? { BLOCKLIST = "blocks", FRIENDLIST = "friends" }
  : { BLOCKLIST = "blockingUsers", FRIENDLIST = "friendList" }

let parsers = {
  friendList = @(e) { accountId = e.user.accountId, nick = e.user.onlineId, online = (e.presence.onlineStatus == "online") }
  blockingUsers = @(e) { accountId = e.user.accountId }
  friends = @(e) { accountId = e, nick = null, online = false }
  blocks = @(e) { accountId = e }
}

let MAX_ACCOUNTS_IN_GET_PARAM = 100 // Limited by max URL length, account Id is const length
let CHUNK_SIZE = 100 // This is max for profile web api, players have several hundreds of friends
local pending = {}
let complete = []


let function onProfilesReceived(response, _err, accounts, callback) {
  let recvd = response?.profiles ?? []
  recvd.each(function(u, i) {
    let uid = accounts[i]
    if (uid in pending)
      pending[uid].nick <- u?.onlineId
  })
  let finished = pending.filter(@(v) accounts.contains(v.accountId) && v.nick != null)
  finished.each(@(u) logPSN($"done {u.accountId} - {u.nick} - {u.online}"))
  finished.each(@(u) complete.append(u))
  pending = pending.filter(@(v) !accounts.contains(v.accountId) && v.nick == null)
  if (pending.len() == 0)
    callback(complete)
}

let function onPresencesReceived(response, _err, callback) {
  let recvd = response?.basicPresences ?? []
  recvd.each(function(e) {
    let uid = e.accountId
    if (uid in pending)
      pending[uid].online <- e.onlineStatus == "online"
  })
  let accounts = pluck(recvd, "accountId")
  accounts.each(@(a, i) logPSN($"try profiles: {i} - {a}"))
  send(profile.getPublicProfiles(accounts), @(r, e) onProfilesReceived(r, e, accounts, callback))
}

let function gatherPresences(entries, callback) {
  pending.clear()
  complete.clear()
  entries.each(@(e) pending[e.accountId] <- e)
  local accounts = pending.keys()
  while (accounts.len() > 0) {
    let chunk = accounts.slice(0, MAX_ACCOUNTS_IN_GET_PARAM)
    chunk.each(@(a, i) logPSN($"try presences: {i} - {a}"))
    send(profile.getBasicPresences(chunk), @(r, e) onPresencesReceived(r, e, callback))
    accounts = accounts.slice(MAX_ACCOUNTS_IN_GET_PARAM)
  }
}

let function handleResponse(fieldName, response, err, callback) {
  let contactsList = response?[fieldName] ?? []
  logPSN($"start processing {fieldName} - {contactsList.len()}")
  let proceed = (getPreferredVersion() == 2 && fieldName != fields.BLOCKLIST && contactsList.len() != 0)
    ? @(res) gatherPresences(res, callback)
    : callback

  if (err != null) {
    statsd.send_counter("psn_service_request_error", 1, {error_code = err.code, endpoint = fieldName})
    logPSN($"Failed to get {fieldName} ({err.code}): {err?.message}")
  }
  else
    proceed(contactsList.map(parsers[fieldName]))
}

let pendingResponse = { [fields.BLOCKLIST] = [], [fields.FRIENDLIST] = [] }
let function handleChunk(fieldName, response, err, callback) {
  let received = (getPreferredVersion() == 2)
                 ? (response?.nextOffset || response?.totalItemCount)
                 : (response?.start||0) + (response?.size||0)
  let total = (getPreferredVersion() == 2 ? response?.totalItemCount : response?.totalResults) || received
  if (err == null)
    response[fieldName].each(@(e) pendingResponse[fieldName].append(e))

  logPSN($"received {fieldName} chunk: {received} items out of {total}")
  if (err != null || received >= total) {
    handleResponse(fieldName, pendingResponse, err, callback)
    pendingResponse[fieldName].clear()
  }
}

let request_psn_friends = @(cb)
  fetch(profile.listFriends(), @(r, e) handleChunk(fields.FRIENDLIST, r, e, cb), CHUNK_SIZE)

let request_blocked_users = @(cb)
  fetch(profile.listBlockedUsers(), @(r, e) handleChunk(fields.BLOCKLIST, r, e, cb), CHUNK_SIZE)

return {
  request_psn_friends
  request_blocked_users
}

