from "%enlSqGlob/ui_library.nut" import *

let {tutorialZoneMarkers} = require("%ui/hud/tutorial/huds/tutorial_zone_minimap.nut")

let minimapCaptureZones = require("%ui/hud/minimap_markers/minimap_cap_zones.nut")
let artilleryZones = require("%ui/hud/minimap_markers/minimap_artillery_zones.nut")
let battleAreas = require("%ui/hud/minimap_markers/minimap_battle_areas.nut")
let resupplyZones = require("%ui/hud/minimap_markers/minimap_resupply_zones.nut")
let landingZones = require("%ui/hud/minimap_markers/minimap_landing_zones.nut")
let minimapSquadOrders = require("%ui/hud/minimap_markers/minimap_squad_orders.nut")
let {
  enemy_building_user_point_markers,
  enemy_vehicle_user_point_markers,
  main_user_point_markers,
  enemy_user_point_markers,
  item_user_point_markers
} = require("%ui/hud/minimap_markers/user_points_ctors.nut")
let {groupmatesNumbers, teammatesMarkers, groupmatesMarkers} = require("%ui/hud/minimap_markers/minimap_teammates.nut")
let aircraftMapMarkers = require("%ui/hud/minimap_markers/aircraft_map_markers.nut")
let tankMapMarkers = require("%ui/hud/minimap_markers/vehicle_map_markers.nut")
let engineerMapMarkers = require("%ui/hud/minimap_markers/engineer_map_markers.nut")
let destroyableRiMarkers = require("%ui/hud/minimap_markers/minimap_destroyable_ri.nut")
let mortarMarkers = require("%ui/hud/minimap_markers/mortar_map_markers.nut")
let enemyAttackMarkers = require("%ui/hud/minimap_markers/enemy_attack_markers.nut")
let engineer_buildings_map_markers = require("%ui/hud/minimap_markers/engineer_buildings_map_markers.nut")

let mmChildrenCtors = freeze([
  battleAreas //optimize
  artilleryZones //optimize
  resupplyZones
  landingZones
  minimapCaptureZones //optimize
  minimapSquadOrders
  mortarMarkers
  aircraftMapMarkers
  tankMapMarkers
  engineerMapMarkers
  destroyableRiMarkers
  enemy_building_user_point_markers
  enemy_vehicle_user_point_markers
  engineer_buildings_map_markers
  main_user_point_markers
  enemy_user_point_markers
  item_user_point_markers
  groupmatesMarkers
  teammatesMarkers
  groupmatesNumbers
  tutorialZoneMarkers //optimize
  enemyAttackMarkers //optimize
])

return {mmChildrenCtors}