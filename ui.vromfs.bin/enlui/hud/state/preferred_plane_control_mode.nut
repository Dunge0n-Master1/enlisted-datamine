import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let preferredPlaneControlMode = require("%enlSqGlob/planeControlModeState.nut")

let comps = {
  comps_rq=["input__enabled"]
  comps_rw = [
    ["plane_input__mouseAimEnabled", ecs.TYPE_BOOL],
    ["plane_input__simpleJoyEnabled", ecs.TYPE_BOOL]
  ]
}

let findPlaneInputQuery = ecs.SqQuery("findPlaneInputQuery", comps)

let function setControlMode(_, comp) {
  if (preferredPlaneControlMode.value == null)
    return
  comp["plane_input__simpleJoyEnabled"] = false
  comp["plane_input__mouseAimEnabled"] = false
  if (preferredPlaneControlMode.value?.isMouseAimEnabled)
    comp["plane_input__mouseAimEnabled"] = true
  else if (preferredPlaneControlMode.value?.isSimpleJoyEnabled)
    comp["plane_input__simpleJoyEnabled"] = true
}

preferredPlaneControlMode.subscribe(@(_mode) findPlaneInputQuery.perform(setControlMode))

ecs.register_es("set_preferred_plane_control", {
  onInit = setControlMode
}, comps, {tags="input"})
