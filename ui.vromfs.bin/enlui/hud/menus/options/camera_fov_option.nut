from "%enlSqGlob/ui_library.nut" import *

let mkCameraFovOption = require("%ui/hud/menus/options/camera_fov_option_common.nut")

return {
  cameraFovOption = mkCameraFovOption(loc("gameplay/camera_fov"), "camera_fov")
}