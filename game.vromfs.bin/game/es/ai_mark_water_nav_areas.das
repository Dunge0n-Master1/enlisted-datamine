require ecs
require app

require pathfinder
require enlisted.game.es.ai_poly_areas_common

[es(on_event=EventLevelLoaded)]
def mark_water_nav(evt : Event)
  var waterLevel = 0.
  query() <| $ [es] (water__level : float)
    waterLevel = water__level
  mark_polygons_lower(waterLevel, uint8(int(EnlPolyArea POLYAREA_WATER)))