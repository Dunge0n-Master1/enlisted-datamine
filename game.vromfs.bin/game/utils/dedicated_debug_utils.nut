import "%dngscripts/ecs.nut" as ecs
let {INVALID_USER_ID} = require("matching.errors")
let {mkEventSqChatMessage} = require("%enlSqGlob/sqevents.nut")
let {has_network, INVALID_CONNECTION_ID} = require("net")
let {hasDedicatedPermission} = require("%scripts/game/es/dedicated_permission_es.nut")

let peersThatWantToReceiveQuery = ecs.SqQuery(
  "peersThatWantToReceiveQuery",
  {
    comps_ro = [["connid",ecs.TYPE_INT], ["userid",ecs.TYPE_UINT64, INVALID_USER_ID], ["receive_logerr", ecs.TYPE_BOOL]],
    comps_rq=["player"]
  },
  "and(ne(connid, {0}), receive_logerr)".subst(INVALID_CONNECTION_ID)
)

let function getConnidForLogReceiver(_eid, comp){
  if (hasDedicatedPermission(comp["userid"], "receive_server_messages"))
    return comp.connid
  return INVALID_CONNECTION_ID
}

local function sendLogToClients(log, connids=null){
  let event = mkEventSqChatMessage(({team=-1, name="dedicated", text=log}))
  if (!has_network())
    ecs.server_msg_sink(event, null)
  else {
    connids = connids==null ? (ecs.query_map(peersThatWantToReceiveQuery, getConnidForLogReceiver) ?? []) : connids
    if (connids.len()>0)
      ecs.server_msg_sink(event, connids)
  }
}

return {
  sendLogToClients = sendLogToClients
  getConnidForLogReceiver = getConnidForLogReceiver
}
