require ecs
require vehicle

[es(tag=gameClient, track=vehicleCameraType)]
def switch_crosshair_penetration_indicator(evt : Event; vehicleCameraType : int; var isSimpleTurretCrosshair : bool&)
  isSimpleTurretCrosshair = vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_GUNNER)