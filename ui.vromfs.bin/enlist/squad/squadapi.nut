from "%enlSqGlob/ui_library.nut" import *

let { matchingCall } = require("%enlist/matchingClient.nut")

let function reportError(resp, _silent=false) {
  if (resp.error == 0)
    return false
  log(resp)
  return true
}

let STANDARD_CB_PARAMS = {
  onAnyResult = null //function(resp)  if not null, onSuccess, and onFailure will be not used
  onSuccess = null   //function(resp)
  onFailure = null   //function(resp)
  isSilent = false
}

local makePerformCallback = @(cbParams = STANDARD_CB_PARAMS)
  function(resp) {
    cbParams = STANDARD_CB_PARAMS.__merge(cbParams)
    let isSuccess = !reportError(resp, cbParams.isSilent)
    if (cbParams.onAnyResult)
      cbParams.onAnyResult(resp)
    else if (isSuccess && cbParams.onSuccess)
      cbParams.onSuccess(resp)
    else if (!isSuccess && cbParams.onFailure)
      cbParams.onFailure(resp)
  }

let MSquadAPI = {
  performOnSuccess = @(cb) function(resp) { if (resp.error == 0) cb(resp) }

  createSquad = @(cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.create_squad", makePerformCallback(cbParams))

  disbandSquad = @(cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.disband_squad", makePerformCallback(cbParams))

  getSquadInfo = @(cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.get_info", makePerformCallback(cbParams))

  setMemberData = @(data, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.set_member_data", makePerformCallback(cbParams), data)

  getMemberData = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.get_member_data", makePerformCallback(cbParams), { userId = userId })

  invitePlayer = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.invite_player", makePerformCallback(cbParams), { userId = userId })

  revokeInvite = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.revoke_invite", makePerformCallback(cbParams), { userId = userId })

  dismissMember = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.dismiss_member", makePerformCallback(cbParams), { userId = userId })

  transferSquad = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.transfer_squad", makePerformCallback(cbParams), { userId = userId })

  setSquadData = @(data, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.set_squad_data", makePerformCallback(cbParams), data)

  acceptMembership = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.accept_membership", makePerformCallback(cbParams), { userId = userId })

  denyMembership = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.deny_membership", makePerformCallback(cbParams), { userId = userId })

  acceptInvite = @(squadId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.accept_invite", makePerformCallback(cbParams), { squadId = squadId })

  rejectInvite = @(squadId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.reject_invite", makePerformCallback(cbParams), { squadId = squadId })

  requestMembership = @(squadId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.request_membership", makePerformCallback(cbParams), { squadId = squadId })

  requestJoin = @(userId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.join_player", makePerformCallback(cbParams), { userId })

  revokeMembershipRequest = @(squadId, cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.revoke_membership_request", makePerformCallback(cbParams), { squadId = squadId })

  leaveSquad = @(cbParams = STANDARD_CB_PARAMS)
    matchingCall("msquad.leave_squad", makePerformCallback(cbParams))
}

return MSquadAPI
