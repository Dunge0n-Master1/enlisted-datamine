import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED } = require("team")
let { INVALID_GROUP_ID } = require("matching.errors")
let {get_user_id} = require("net")
let logObs = require("%enlSqGlob/library_logs.nut").with_prefix("[OBSERVER]")

const INVALID_USER_ID = 0
const UNDEFINEDNAME = "?????"

let localPlayerUserId = mkWatched(persist, "localPlayerUserId", INVALID_USER_ID)
let localPlayerEid = mkWatched(persist, "localPlayerEid", ecs.INVALID_ENTITY_ID)
let localPlayerSpecTarget = mkWatched(persist, "localPlayerSpecTarget", ecs.INVALID_ENTITY_ID)
let localPlayerName = mkWatched(persist, "localPlayerName", UNDEFINEDNAME)
let localPlayerTeam = mkWatched(persist, "localPlayerTeam", TEAM_UNASSIGNED)
let localPlayerGroupId = mkWatched(persist, "localPlayerGroupId", INVALID_GROUP_ID)
let localPlayerGroupMembers = mkWatched(persist, "localPlayerGroupMembers", {})

let groupmateQuery = ecs.SqQuery("groupmateQuery", {comps_ro = [["groupId", ecs.TYPE_INT64]]})

localPlayerSpecTarget.subscribe(@(eid) logObs($"spectated: {eid}"))

let function addGroupmate(eid, comp) {
  if (localPlayerGroupId.value != INVALID_GROUP_ID && comp["groupId"] == localPlayerGroupId.value) {
    if (eid in localPlayerGroupMembers.value)
      return
    localPlayerGroupMembers.mutate(@(v) v[eid] <- true)
  }
}

let function resetData() {
  localPlayerEid(ecs.INVALID_ENTITY_ID)
  localPlayerTeam(TEAM_UNASSIGNED)
  localPlayerUserId(get_user_id())
  localPlayerSpecTarget(ecs.INVALID_ENTITY_ID)
  localPlayerGroupId(INVALID_GROUP_ID)
  localPlayerGroupMembers({})
}

let function trackComponents(eid, comp) {
  if (comp.is_local) {
    if (localPlayerEid.value != eid)
      logObs($"[local_player_es] localPlayerEid = {eid}")
    localPlayerEid(eid)
    localPlayerTeam(comp.team)
    localPlayerName(comp.name)
    localPlayerUserId(get_user_id())
    localPlayerSpecTarget(comp.specTarget)
    localPlayerGroupId(comp.groupId)
    // first reset group members and then collect them again, for prevent duplicate
    localPlayerGroupMembers({})
    groupmateQuery.perform(addGroupmate)
  } else if (localPlayerEid.value == eid) {
    resetData()
  }
}

let function onDestroy(eid, _comp) {
  if (localPlayerEid.value == eid)
    resetData()
}

ecs.register_es("local_player_es", {
    onChange = trackComponents
    onInit = trackComponents
    onDestroy = onDestroy
  },
  {
    comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["team", ecs.TYPE_INT],
      ["name", ecs.TYPE_STRING],
      ["specTarget", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["groupId", ecs.TYPE_INT64]
    ]
    comps_rq = ["player"]
  }
)

ecs.register_es("local_player_group_es",
  {
    [["onInit"]] = addGroupmate
    onDestroy = function (eid, _comp) {
      if (eid in localPlayerGroupMembers.value)
        localPlayerGroupMembers.mutate(@(v) delete v[eid])
    }
  },
  {comps_ro = [["groupId", ecs.TYPE_INT64]]}
)

return {
  localPlayerName
  localPlayerEid
  localPlayerTeam
  localPlayerUserId
  localPlayerSpecTarget
  localPlayerGroupId
  localPlayerGroupMembers
}