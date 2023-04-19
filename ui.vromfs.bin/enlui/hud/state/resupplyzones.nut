import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED } = require("team")
let { watchedTeam } = require("%ui/hud/state/watched_hero.nut")
let { isVehicleCanBeRessuplied, inGroundVehicle, inPlane, vehicleResupplyType } = require("%ui/hud/state/vehicle_state.nut")
let { mkWatchedSetAndStorage, MK_COMBINED_STATE } = require("%ui/ec_to_watched.nut")
let { vehicleInfo, showSquadSpawn } = require("%ui/hud/state/respawnState.nut")
let {
  resupply_zones_GetWatched,
  resupply_zones_UpdateEid,
  resupply_zones_DestroyEid,
  resupply_zones_State
} = mkWatchedSetAndStorage("resupply_zones_", MK_COMBINED_STATE)

let DB = ecs.g_entity_mgr.getTemplateDB()

let spawnMenuGroundVehicle = Computed(function() {
  if (!showSquadSpawn.value || vehicleInfo.value?.gametemplate == null)
    return false
  let vehicleTemplate = DB.getTemplateByName(vehicleInfo.value?.gametemplate)
  return vehicleTemplate?.getCompValNullable("airplane") == null
})

let heroActiveResupplyZonesEids = Computed(function(){
  let isInPlane = inPlane.value
  let isInGroundVehicle = inGroundVehicle.value
  let vehicleType = vehicleResupplyType.value
  let isSpawnMenuGroundVehicle = spawnMenuGroundVehicle.value
  if (((!isInGroundVehicle && !isInPlane) || !isVehicleCanBeRessuplied.value) && !isSpawnMenuGroundVehicle)
    return {}
  let heroTeam = watchedTeam.value
  return resupply_zones_State.value.filter(function(z) {
    let {team, active, isForPlanes, isForGroundVehicles, acceptedVehicleType} = z
    return active
      && (team == TEAM_UNASSIGNED || team == heroTeam)
      && (showSquadSpawn.value
        ? isSpawnMenuGroundVehicle && isForGroundVehicles
        : ((acceptedVehicleType == "" || acceptedVehicleType == vehicleType)
          && (
            (isInPlane && isForPlanes) ||
            (isInGroundVehicle && isForGroundVehicles)
          )))
  })
})

ecs.register_es("resupply_zones_ui_state_es",
  {
    [["onChange", "onInit"]] = @(_, eid, comp) resupply_zones_UpdateEid(eid, {
      eid
      active   = comp["active"]
      icon     = comp["zone__icon"]
      ui_order = comp["ui_order"]
      caption  = comp["zone__caption"]
      radius   = comp["sphere_zone__radius"]
      team     = comp["resupply_zone__team"]
      isForPlanes = comp.planeResupply != null
      isForGroundVehicles = comp.groundVehicleResupply != null
      acceptedVehicleType = comp.resupply_zone__type
    })
    onDestroy = @(_, eid, __) resupply_zones_DestroyEid(eid)
  },
  {
    comps_ro = [
      ["zone__icon", ecs.TYPE_STRING, ""],
      ["zone__caption", ecs.TYPE_STRING, ""],
      ["planeResupply", ecs.TYPE_TAG, null],
      ["groundVehicleResupply", ecs.TYPE_TAG, null],
      ["resupply_zone__type", ecs.TYPE_STRING, ""],
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
//  resupply_zones_Set,
  resupply_zones_GetWatched,
  heroActiveResupplyZonesEids
}
