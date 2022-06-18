from "%enlSqGlob/ui_library.nut" import *

let { findResearchSlotUnlock, focusResearch } = require("%enlist/researches/researchesFocus.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")

let function gotoResearchUpgradeMsgBox(soldier, slotType, _slotId) {
  let { sClass = "unknown" } = soldier
  let research = findResearchSlotUnlock(soldier, slotType)
  let buttons = [{ text = loc("Ok"), isCancel = true }]
  if (research != null)
    buttons.append({ text = loc("GoToResearch"),
      action = function() {
        focusResearch(research)
      },
      isCurrent = true })
  msgbox.show({
    text = loc("slotClassResearch", {
      soldierClass = loc(soldierClasses?[sClass].locId ?? "unknown")
    })
    buttons
  })
}

return gotoResearchUpgradeMsgBox