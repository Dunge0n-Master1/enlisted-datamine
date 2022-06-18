import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED } = require("team")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {inGroundVehicle, inPlane, controlledVehicleEid} = require("%ui/hud/state/vehicle_state.nut")

let resupplyZones = mkWatched(persist, "resupplyZones", {})
let heroActiveResupplyZonesEids = Watched([])


let function updateEids(...) {
  let watchedHeroTeam = ecs.obsolete_dbg_get_comp_val(watchedHeroEid.value, "team") ?? TEAM_UNASSIGNED
  let disableVehicleResupply = ecs.obsolete_dbg_get_comp_val(controlledVehicleEid.value ?? INVALID_ENTITY_ID, "disableVehicleResupply")
  if ((!inGroundVehicle.value && !inPlane.value) || disableVehicleResupply != null) {
    heroActiveResupplyZonesEids([])
    return
  }
  let applicableForVehicle = @(z) (inPlane.value && ecs.obsolete_dbg_get_comp_val(z.eid, "planeResupply") != null) ||
                                    (inGroundVehicle.value && ecs.obsolete_dbg_get_comp_val(z.eid, "groundVehicleResupply") != null)
  let applicableForTeam = @(z) z.team == TEAM_UNASSIGNED || z.team == watchedHeroTeam
  let heroZoneEids = resupplyZones.value.filter(@(z) z.active && applicableForTeam(z) && applicableForVehicle(z)).keys()
  if (!isEqual(heroZoneEids, heroActiveResupplyZonesEids.value))
    heroActiveResupplyZonesEids(heroZoneEids)
}
[resupplyZones, inGroundVehicle, inPlane].map(@(v) v.subscribe(updateEids))
updateEids()


let function onResupplyZoneInitialized(eid, comp) {
  let zone = {
    eid = eid
    active   = comp["active"]
    icon     = comp["zone__icon"]
    ui_order = comp["ui_order"]
    caption  = comp["zone__caption"]
    radius   = comp["sphere_zone__radius"]
    team     = comp["resupply_zone__team"]
  }
  resupplyZones.mutate(@(v) v[eid] <- zone)
}

let function onResupplyZoneChanged(eid, comp) {
  let zone = resupplyZones.value?[eid]

  if (zone==null)
    return

  let updatedZone = clone zone

  updatedZone.active = comp["active"]
  updatedZone.radius = comp["sphere_zone__radius"]
  updatedZone.ui_order = comp["ui_order"]
  updatedZone.team = comp["resupply_zone__team"]

  resupplyZones.mutate(@(v) v[eid] = updatedZone)
}

let function onResupplyZoneDestroy(eid, _comp) {
  if (eid in resupplyZones.value)
    resupplyZones.mutate(@(v) delete v[eid])
}


ecs.register_es("resupply_zones_ui_state_es",
  {
    onChange = onResupplyZoneChanged,
    onInit = onResupplyZoneInitialized,
    onDestroy = onResupplyZoneDestroy,
  },
  {
    comps_ro = [
      ["zone__icon", ecs.TYPE_STRING, ""],
      ["zone__caption", ecs.TYPE_STRING, ""],
    ]
    comps_track = [
      ["active", ecs.TYPE_BOOL],
      ["resupply_zone__team", ecs.TYPE_INT],
      ["ui_order", ecs.TYPE_INT, 0],
      ["sphere_zone__radius", ecs.TYPE_FLOAT, 0],
    ],
    comps_rq = ["resupplyZone"]
  },
  { tags="gameClient" }
)


return {
  resupplyZones = resupplyZones
  heroActiveResupplyZonesEids = heroActiveResupplyZonesEids
}
