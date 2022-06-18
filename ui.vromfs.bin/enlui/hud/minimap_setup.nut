from "%enlSqGlob/ui_library.nut" import *

let minimapCaptureZones = require("huds/minimap_cap_zones.nut")
let artilleryZones = require("%ui/hud/huds/minimap/minimap_artillery_zones.nut")
let battleAreas = require("%ui/hud/huds/minimap_battle_areas.nut")
let resupplyZones = require("%ui/hud/huds/minimap_resupply_zones.nut")
let minimapSquadOrders = require("%ui/hud/huds/minimap_squad_orders.nut")
let {user_points} = require("%ui/hud/state/user_points.nut")
let {mkUserPoints, user_points_ctors} = require("%ui/hud/huds/minimap/user_points_ctors.nut")
let {groupmatesNumbers, teammatesMarkers, groupmatesMarkers} = require("huds/minimap_teammates.nut")
let {tutorialZoneMarkers} = require("%ui/hud/tutorial/huds/tutorial_zone_minimap.nut");
let {mkPointMarkerCtor} = require("%ui/hud/huds/minimap/components/minimap_markers_components.nut")
let mkBuildingIcon = require("%ui/hud/huds/building_icons.nut")
let aircraftMapMarkers = require("%ui/hud/huds/aircraft_map_markers.nut")
let tankMapMarkers = require("%ui/hud/huds/vehicle_map_markers.nut")
let engineerMapMarkers = require("%ui/hud/huds/engineer_map_markers.nut")
let destroyableRiMarkers = require("%ui/hud/huds/minimap_destroyable_ri.nut")
let mortarMarkers = require("%ui/_packages/common_shooter/hud/huds/mortar_map_markers.nut")
let enemyAttackMarkers = require("%ui/hud/huds/enemy_attack_markers.nut")
let { setMmChildrenCtors } = require("%ui/hud/huds/minimap/minimap_state.nut")

let vehicleIconSize = [fsh(1.4), fsh(1.4)].map(@(v) v.tointeger())

let user_points_ctors_ext = user_points_ctors.__merge({
  enemy_vehicle_user_point = mkPointMarkerCtor({
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    size = vehicleIconSize
  })

  building_point = mkBuildingIcon
})

setMmChildrenCtors([
  battleAreas
  artilleryZones
  resupplyZones
  minimapCaptureZones
  minimapSquadOrders
  mortarMarkers
  aircraftMapMarkers
  tankMapMarkers
  engineerMapMarkers
  destroyableRiMarkers
  mkUserPoints(user_points_ctors_ext, user_points)
  groupmatesMarkers
  teammatesMarkers
  groupmatesNumbers
  tutorialZoneMarkers
  enemyAttackMarkers
])
