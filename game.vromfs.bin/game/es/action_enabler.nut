import "%dngscripts/ecs.nut" as ecs
let {EventEntityDied, EventEntityResurrected, EventEntityDowned, EventEntityRevived} = require("dasevents")
// do not really create fake entity for it. it's okay to enable/disable actions as is in current design
let onActionsEnable = @(val) function(_eid, comp) {
  comp["actions__enabled"] = val
}

let comps = {
  comps_rw = [
    ["actions__enabled", ecs.TYPE_BOOL]
  ]
}
ecs.register_es("action_enabler_es", {
  [EventEntityDowned] = onActionsEnable(false),
  [EventEntityDied] = onActionsEnable(false),
  [EventEntityRevived] = onActionsEnable(true),
  [EventEntityResurrected] = onActionsEnable(true),
}, comps)
