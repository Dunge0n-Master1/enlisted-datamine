import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {watchedHeroEid} = require("%ui/hud/state/watched_hero.nut")

let overheat = Watched(0)

let function trackComponents(_eid, comp) {
  let hero = watchedHeroEid.value
  if (ecs.obsolete_dbg_get_comp_val(hero, "human_anim__vehicleSelected") == ecs.INVALID_ENTITY_ID) {
    overheat.update(0)
    return
  }
  if (comp["gun__owner"] == hero && comp["gun__overheat"] > 0)
    overheat.update(comp["gun__overheat"])
}

ecs.register_es("turret_overheat_ui_es", {
    onChange = trackComponents,
    onInit = trackComponents,
    onDestroy = trackComponents }, {
    comps_track = [
      ["gun__overheat", ecs.TYPE_FLOAT]
    ]
    comps_ro = [
      ["gun__owner", ecs.TYPE_EID]
    ],
    comps_rq = [
      "isTurret"
    ]
  },
  {tags="gameClient"}
)

let turretQuery = ecs.SqQuery("turretQuery", {
  comps_ro=[["gun__overheat", ecs.TYPE_FLOAT]]
  comps_rq = ["isTurret"]
})

let function trackSelectedVehicleComponents(_eid, comp) {
  overheat.update(0)
  let vehicleEid = comp["human_anim__vehicleSelected"]
  let turretEids = ecs.obsolete_dbg_get_comp_val(vehicleEid, "turret_control__gunEids")?.getAll() ?? []
  foreach (turretEid in turretEids)
    if (turretQuery.perform(turretEid, function(_eid, comp) { overheat.update(comp["gun__overheat"]); return true; }))
      break
}

ecs.register_es("hero_vehicle_turret_overheat_ui_es", {
    onChange = trackSelectedVehicleComponents,
    onInit = trackSelectedVehicleComponents,
  },
  {
    comps_track = [["human_anim__vehicleSelected", ecs.TYPE_EID]]
    comps_rq = ["hero"]
  },
  {tags="gameClient"}
)

return overheat
