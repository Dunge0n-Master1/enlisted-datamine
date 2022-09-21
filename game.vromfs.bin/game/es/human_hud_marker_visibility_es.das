require ecs
require game.es.events

[es(tag=gameClient, on_appear, track=isAlive, track=isInVehicle)]
def human_hud_marker_visibility_es(evt : Event; isAlive : bool; isInVehicle : bool; var isMarkerMapUnitVisible : bool&)
  isMarkerMapUnitVisible = isAlive && !isInVehicle
