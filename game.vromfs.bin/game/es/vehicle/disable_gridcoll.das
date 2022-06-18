require ecs
require GridCollision

[es(on_appear, track=isInVehicleHidden)]
def gridcoll_set_in_vehicle_es(evt : Event; isInVehicleHidden : bool; var grid_obj__hidden : int&)
  if isInVehicleHidden
    grid_obj__hidden |= int(GridHideFlag EGH_IN_VEHICLE)
  else
    grid_obj__hidden &= ~int(GridHideFlag EGH_IN_VEHICLE)
