import "%dngscripts/ecs.nut" as ecs
let {server_send_net_sqevent} = require("ecs.netevent")

let function updateAFK(_dt, eid, comp) {
  let afkTime = comp["afk__time"].tointeger()
  if (afkTime == comp["afk__showWarningTimeout"])
    server_send_net_sqevent(eid, ecs.event.AFKShowWarning(), [comp.connid])
  if (afkTime == comp["afk__showDisconnectWarningTimeout"])
    server_send_net_sqevent(eid, ecs.event.AFKShowDisconnectWarning(), [comp.connid])
}

ecs.register_es("afk_server_es",
  { onUpdate = updateAFK },
  { comps_ro=[["connid", ecs.TYPE_INT], ["afk__time", ecs.TYPE_FLOAT], ["afk__showWarningTimeout", ecs.TYPE_INT], ["afk__showDisconnectWarningTimeout", ecs.TYPE_INT]] },
  { tags="server", updateInterval = 1.0, after="*", before="*" })