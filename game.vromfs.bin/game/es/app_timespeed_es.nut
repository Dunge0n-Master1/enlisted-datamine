import "%dngscripts/ecs.nut" as ecs
let {set_timespeed} = require("app")

ecs.register_es("app_timespeed_es",
  {
    onChange = function (_eid, comp) {
      set_timespeed(comp["app__timeSpeed"])
    }

    onInit = function (_eid, comp) {
      set_timespeed(comp["app__timeSpeed"])
    }

    onDestroy = function () {
      set_timespeed(1.0)
    }
  },
  { comps_track = [["app__timeSpeed", ecs.TYPE_FLOAT]]}
)

