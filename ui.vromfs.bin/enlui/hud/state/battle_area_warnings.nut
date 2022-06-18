import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {warningUpdate, WARNING_PRIORITIES, addWarnings} = require("%ui/hud/state/warnings.nut")
const leftBattleArea = "leftBattleArea"
const taskPoint = "taskPoint"

let displayOutsideBattleAreaWarning = Watched(false)

let WARNING_VISIBLE_TIME = 5.0
let warningTimer = @() displayOutsideBattleAreaWarning(false)

addWarnings({
  [leftBattleArea]         = { priority = WARNING_PRIORITIES.HIGH, getSound = @() "leftBattleArea" },
  [taskPoint]              = { priority = WARNING_PRIORITIES.HIGH, getSound = @() "taskPoint" }
})

let function trackComponents(_eid, comp) {
  let outside = comp["isOutsideBattleArea"]
  let isInOldArea = comp["isInDeactivatingBattleArea"]
  warningUpdate(leftBattleArea, comp.isAlive && outside)
  warningUpdate(taskPoint, comp.isAlive && isInOldArea)
  gui_scene.clearTimer(warningTimer)
  if (outside)
    gui_scene.resetTimeout(WARNING_VISIBLE_TIME, warningTimer)
  displayOutsideBattleAreaWarning(outside)
}

ecs.register_es("leaving_battle_area_ui_es",
  {
    [["onInit", "onChange"]] = trackComponents,
  },
  {
    comps_rq = ["hero"],
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL],
      ["isOutsideBattleArea", ecs.TYPE_BOOL],
      ["isInDeactivatingBattleArea", ecs.TYPE_BOOL, false]
    ]
  }
)

return displayOutsideBattleAreaWarning