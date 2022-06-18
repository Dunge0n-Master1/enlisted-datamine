from "%enlSqGlob/ui_library.nut" import *

let mkCameraFovOption = require("%ui/hud/menus/options/camera_fov_option_common.nut")

return {
  vehicleCameraFovOption = mkCameraFovOption(loc("gameplay/vehicle_camera_fov"), "vehicle_camera_fov")
}