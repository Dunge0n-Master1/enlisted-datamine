require ecs
require app

require pathfinder
require enlisted.game.es.ai_poly_areas_common

[es(on_event=EventLevelLoaded)]
def mark_deep_water_nav(evt : Event)
  var waterLevel = 0.
  var walkHeight = 0.
  query() <| $ [es] (water__level : float;
                     water__smallWaterAIWalkHeight : float = 0.3)
    waterLevel = water__level
    walkHeight = water__smallWaterAIWalkHeight
  mark_polygons_lower(waterLevel - walkHeight, uint8(int(EnlPolyArea POLYAREA_WATER)))

[es(on_appear)]
def set_ai_nav_deep_water_area_cost(evt : Event; var navigation__areasCost : Point2List&)
  query() <| $ [es(REQUIRE=water__level)] (water__deepWaterAIAreaCost : float)
    if water__deepWaterAIAreaCost > 0.0
      for areaCost in navigation__areasCost
        if int(areaCost.x) == int(EnlPolyArea POLYAREA_WATER)
          areaCost.y = water__deepWaterAIAreaCost
