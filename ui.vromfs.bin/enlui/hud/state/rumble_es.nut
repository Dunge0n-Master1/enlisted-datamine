import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isInBattleRumbleEnabled } = require("controls_online_storage.nut")

let comps = {comps_rq = ["human_input"]}
let findHumanInput = ecs.SqQuery("findHumanInput", comps)

let function setRumbleEnabled(eid, enabled){
  if (enabled)
    ecs.recreateEntityWithTemplates({eid, addTemplates = [{template="human_input_rumble_enabled", comps = ["human_input__rumbleEnabled"]}]})
  else
    ecs.recreateEntityWithTemplates({eid, removeTemplates = [{template="human_input_rumble_enabled", comps = ["human_input__rumbleEnabled"]}]})
}

isInBattleRumbleEnabled.subscribe(function(enabled) {
  findHumanInput(function(eid, _comp) { setRumbleEnabled(eid, enabled) })
})

ecs.register_es("rumble_ui_es", {
  onInit = @(eid, _comp) setRumbleEnabled(eid, isInBattleRumbleEnabled.value),
  onDestroy = @(eid, _comp) setRumbleEnabled(eid, false)
}, comps)