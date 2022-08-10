import "%dngscripts/ecs.nut" as ecs

let isDedicated = require_optional("dedicated") != null
if (isDedicated)
  return

let userInfo = require("%enlSqGlob/userInfo.nut")
let { has_network } = require("net")

let function updateName(_eid, comp) {
  if (!comp.is_local || has_network())
    return null

  let { name = "" } = userInfo.value
  if (name != "")
    comp.name = name
  return comp
}

ecs.register_es("update_local_player_name", {
    [["onInit", "onChange"]] = updateName
  },
  {
    comps_track = [["is_local", ecs.TYPE_BOOL]]
    comps_rw = [["name", ecs.TYPE_STRING]]
    comps_rq = ["player"]
    comps_no = ["playerIsBot"]
  }
)