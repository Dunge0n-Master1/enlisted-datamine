from "%enlSqGlob/ui_library.nut" import *

let minimapCtor = require("%ui/hud/huds/minimap/minimap.nut")
let mouseButtons = require("%enlSqGlob/mouse_buttons.nut")

return {
  minimap = @() minimapCtor({panButton = mouseButtons.MMB})
}
