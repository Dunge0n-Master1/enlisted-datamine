import "%dngscripts/ecs.nut" as ecs

let console = require("console")
ecs.register_es("friendly_fire_gamemode_es", {
    onInit = @(_eid, _comp) console.command("dm.dbg_friendly_fire 1")
    onDestroy = @(_eid, _comp) console.command("dm.dbg_friendly_fire 0")
  },
  { comps_rq = ["gamemodeFriendlyFire"] }
)
