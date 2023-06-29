import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isAimAssistEnabled, isAimAssistExists, isAimAssistChangeManual,
  setAimAssist, setAimAssistSetByAB, isAimAssistSetByAB } = require("controls_online_storage.nut")

let comps = {
  comps_rq = ["human_input"],
  comps_rw = [["aim_assist__enabled", ecs.TYPE_BOOL]]
}
let findHumanToAimAssist = ecs.SqQuery("findHumanToAimAssist", comps)

let function setAssistValToEntity(val, comp){
  comp["aim_assist__enabled"] = val
}

isAimAssistEnabled.subscribe(function(val) {
  findHumanToAimAssist.perform(function(_eid, comp) {setAssistValToEntity(val, comp)})
})

ecs.register_es("assists_ui_es", {
  onInit = @(_eid,comp) setAssistValToEntity(isAimAssistEnabled.value, comp),
}, comps)

ecs.register_es("ab_test_aim_assist_es", {
    [[ "onInit", "onChange" ]] = function(_eid, comp) {
      if (isAimAssistChangeManual.value || !isAimAssistExists)
        return

      if (comp.ab_test__isAimAssistTestEnabled) {
        setAimAssist(false)
        setAimAssistSetByAB(true)
      } else if (isAimAssistSetByAB.value)
        setAimAssist(true)
    },
  },
  {
    comps_track =[["ab_test__isAimAssistTestEnabled", ecs.TYPE_BOOL]],
    comps_rq = ["localPlayer"],
  },
  {tags="netClient"}
)
