from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let {nestWatched} = require("%dngscripts/globalState.nut")
let selfUid = Computed(@() userInfo.value?.userId)
let squadId = nestWatched("squadId", null)

let isInvitedToSquad = nestWatched("isInvitedToSquad", {})
let squadMembers = nestWatched("squadMembers", {})
let squadLen = Computed(@() squadMembers.value.len())
let squadSelfMember = Computed(@() squadMembers.value?[selfUid.value])
let allMembersState = Computed(@() squadMembers.value.map(@(s) s?.state))
let selfMemberState = Computed(@() allMembersState.value?[selfUid.value])
let squadLeaderState = Computed(@() allMembersState.value?[squadId.value])

let isInSquad = Computed(@() squadId.value != null)
let isSquadLeader = Computed(@() squadId.value == selfUid.value)
let isLeavingWillDisbandSquad = Computed(@() squadLen.value == 1 || (squadLen.value + isInvitedToSquad.value.len() <= 2))
let enabledSquad = Watched(true)
let canInviteToSquad = Computed(@() enabledSquad.value && (!isInSquad.value || isSquadLeader.value))

let notifyMemberAdded = []
let notifyMemberRemoved = []

// FIXME it's just quick and dirty fix. autoSquad parameter should be moved otside of general
// squadState and passed to quickMatchQueue as project specific argument
let autoSquad = nestWatched("autoSquad", true)

let myExtSquadData = {}

let function makeSharedData(persistId) {
  let res = {}
  foreach (key in ["clusters", "isAutoCluster", "squadChat"])
    res[key] <- nestWatched($"{persistId}{key}", null)
  return res
}
let squadSharedData = makeSharedData("squadSharedData")
let squadServerSharedData = makeSharedData("squadServerSharedData")

return {
  selfUid
  squadId

  isInvitedToSquad
  squadMembers
  isSquadNotEmpty = Computed(@() squadMembers.value.len()>1)
  squadLen
  squadSelfMember
  allMembersState
  selfMemberState
  squadLeaderState

  isInSquad
  isSquadLeader
  isLeavingWillDisbandSquad
  enabledSquad
  canInviteToSquad

  autoSquad

  myExtSquadData

  squadSharedData
  squadServerSharedData

  // events
  notifyMemberAdded
  notifyMemberRemoved
  subsMemberAddedEvent = @(func) notifyMemberAdded.append(func)
  subsMemberRemovedEvent = @(func) notifyMemberRemoved.append(func)
}