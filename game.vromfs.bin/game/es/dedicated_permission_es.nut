import "%dngscripts/ecs.nut" as ecs
let isDedicated = require_optional("dedicated") != null
let {isInternalCircuit} = require("%dngscripts/appInfo.nut")
let {readPermissions} = require("%enlSqGlob/permission_utils.nut")
let {has_network, INVALID_CONNECTION_ID} = require("net")
let {find_human_player_by_connid, find_local_player} = require("%dngscripts/common_queries.nut")

const LOCAL_PERM = "local."

let permissions = {}


let function hasDedicatedPermission(userid, permission){
  if (isInternalCircuit.value)
    return true

  let userPermissions = permissions?[userid]
  return (userPermissions?.value.contains(permission) ?? false) ||
         (!isDedicated && (userPermissions?.value.contains($"{LOCAL_PERM}{permission}") ?? false))
}


ecs.register_es("read_dedicated_permissions",
  {
    [ecs.sqEvents.EventSqDedicatedPermissions] = function(evt,eid,comp){
      let senderEid = has_network()
          ? find_human_player_by_connid(evt?.fromconnid ?? INVALID_CONNECTION_ID)
          : find_local_player()

      if (senderEid!=eid)
        return

      if (comp.userid > 0)
        permissions[comp.userid] <- readPermissions(evt.data.jwt, comp.userid)
      }
  },
  {comps_rq=["player"], comps_ro = [["userid", ecs.TYPE_UINT64]]}
)


if (!isDedicated) { //we need code only on client in both offline and network mode
  let userInfo = require("%enlSqGlob/userInfo.nut")
  let {EventLevelLoaded} = require("gameevents")
  ecs.register_es("send_dedicated_permissions",
    {
      [EventLevelLoaded] = function(eid, comp) {
        if (!comp.is_local)
          return

        let dedicatedPermJwt = userInfo.value?.dedicatedPermJwt
        if (dedicatedPermJwt==null)
          return

        ecs.client_send_event(eid, ecs.event.EventSqDedicatedPermissions({jwt = dedicatedPermJwt}))
      }
    },
    {comps_rq=["player"], comps_ro=[["is_local", ecs.TYPE_BOOL]]}
  )
}


return {hasDedicatedPermission}
