from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")

let selfUid = Computed(@() userInfo.value?.userId)
let squadId = mkWatched(persist, "squadId", null)

let isInvitedToSquad = mkWatched(persist, "isInvitedToSquad", {})
let squadMembers = mkWatched(persist, "squadMembers", {}, FRP_DONT_CHECK_NESTED)
let squadSelfMember = Computed(@() squadMembers.value?[selfUid.value], FRP_DONT_CHECK_NESTED)
let allMembersState = mkWatched(persist, "allMembersState", {}, FRP_DONT_CHECK_NESTED)
let selfMemberState = Computed(@() allMembersState.value?[selfUid.value], FRP_DONT_CHECK_NESTED)
let squadLeaderState = Computed(@() allMembersState.value?[squadId.value], FRP_DONT_CHECK_NESTED)

let isInSquad = Computed(@() squadId.value != null)
let isSquadLeader = Computed(@() squadId.value == selfUid.value)
let isLeavingWillDisbandSquad = Computed(@() squadMembers.value.len() == 1 || (squadMembers.value.len() + isInvitedToSquad.value.len() <= 2))
let enabledSquad = Watched(true)
let canInviteToSquad = Computed(@() enabledSquad.value && (!isInSquad.value || isSquadLeader.value))

let notifyMemberAdded = []
let notifyMemberRemoved = []

// FIXME it's just quick and dirty fix. autoSquad parameter should be moved otside of general
// squadState and passed to quickMatchQueue as project specific argument
let autoSquad = mkWatched(persist, "autoSquad", true)

let myExtSquadData = {}

let function makeSharedData(persistId) {
  let res = {}
  foreach (key in ["clusters", "isAutoCluster", "squadChat"])
    res[key] <- mkWatched(persist, $"{persistId}{key}", null)
  return res
}
let squadSharedData = makeSharedData("squadSharedData")
let squadServerSharedData = makeSharedData("squadServerSharedData")

return {
  selfUid
  squadId

  isInvitedToSquad
  squadMembers
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