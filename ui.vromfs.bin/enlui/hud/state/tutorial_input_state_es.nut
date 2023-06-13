import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let dainput = require("dainput2")

// enable by default
let tutorialPlaneShootEnable = Watched(true)

ecs.register_es("tutorial_plane_input_state_ui",{
  [["onInit","onChange"]] = @(_eid, comp) tutorialPlaneShootEnable(comp["plane_input__shoot"] != dainput.BAD_ACTION_HANDLE)
  onDestroy = @() tutorialPlaneShootEnable(true)
},
{
  comps_track=[["plane_input__shoot", ecs.TYPE_INT]]
})

return {
  tutorialPlaneShootEnable
}
