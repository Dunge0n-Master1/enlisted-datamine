import "%dngscripts/ecs.nut" as ecs
let {exit_game} = require("app")
let {EventLevelLoaded} = require("gameevents")

let function onLevelLoaded(_eid, comp) {
  ecs.set_callback_timer_rt(exit_game, comp["quit_after_load_time"], false)
}

ecs.register_es("quit_after_load_es", {
  [EventLevelLoaded] = onLevelLoaded
}, {comps_rw = [ ["quit_after_load_time", ecs.TYPE_FLOAT] ]})
