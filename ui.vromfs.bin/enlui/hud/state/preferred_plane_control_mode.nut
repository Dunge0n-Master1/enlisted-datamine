import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {planeControlModeState} = require("%enlSqGlob/planeControlModeState.nut")

let comps = {
  comps_rq=["input__enabled"]
  comps_rw = [
    ["plane_input__mouseAimEnabled", ecs.TYPE_BOOL],
    ["plane_input__simpleJoyEnabled", ecs.TYPE_BOOL]
  ]
}

let findPlaneInputQuery = ecs.SqQuery("findPlaneInputQuery", comps)

let function setControlMode(_, comp) {
  if (planeControlModeState.value == null)
    return
  comp["plane_input__simpleJoyEnabled"] = false
  comp["plane_input__mouseAimEnabled"] = false
  if (planeControlModeState.value?.isMouseAimEnabled)
    comp["plane_input__mouseAimEnabled"] = true
  else if (planeControlModeState.value?.isSimpleJoyEnabled)
    comp["plane_input__simpleJoyEnabled"] = true
}

planeControlModeState.subscribe(@(_mode) findPlaneInputQuery.perform(setControlMode))

ecs.register_es("set_preferred_plane_control", {
  onInit = setControlMode
}, comps, {tags="input"})
