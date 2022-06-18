import "%dngscripts/ecs.nut" as ecs

let {EventEntityActivate} = require("dasevents")

let function onEntityActivate(evt, _eid, comp) {
  comp.active = evt.activate
}

let comps = {
  comps_rw = [
    ["active", ecs.TYPE_BOOL]
  ]
}
ecs.register_es("enity_activate_es", {
  [EventEntityActivate] = onEntityActivate,
}, comps)

