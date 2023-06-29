from "%enlSqGlob/ui_library.nut" import *

let { findResearchSlotUnlock, focusResearch } = require("%enlist/researches/researchesFocus.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")
let { configs } = require("%enlist/meta/configs.nut")

let { setAutoChapter } = require("%enlist/shop/shopState.nut")
let { setCurSection } = require("%enlist/mainMenu/sectionsState.nut")
let { doesLocTextExist } = require("dagor.localize")


let function gotoResearchUpgradeMsgBox(soldier, slotType, _slotId) {
  let { sClass = "unknown", equipScheme = {} } = soldier
  let soldierClass = loc(soldierClasses?[sClass].locId ?? "unknown")
  let buttons = [{ text = loc("Ok"), isCancel = true }]
  let researchSlot = slotType in (configs.value?.equip_slot_increase ?? {}) ? "backpack" : slotType

  if (researchSlot not in equipScheme) {
    msgbox.show({
      text = loc("Not available for class", { soldierClass } )
      buttons
    })
    return
  }

  let research = findResearchSlotUnlock(soldier, researchSlot)
  if (research != null) {
    buttons.append({ text = loc("GoToResearch"),
      action = function() {
        focusResearch(research)
      },
      isCurrent = true })
  } else {
    buttons.append({ text = loc("GoToEquipment"),
      action = function() {
        setAutoChapter("wpack_group")
        setCurSection("SHOP")
      }
    })
  }

  let needBackpack = research == null && researchSlot != slotType

  local textMsg
  if (needBackpack) {
    let msgLocId = $"slotBlocked/{slotType}"
    textMsg = doesLocTextExist(msgLocId)
      ? loc(msgLocId)
      : loc("slotBlockedDefault")
  } else {
    textMsg = loc("slotClassResearch", { soldierClass })
  }

  msgbox.show({
    text = textMsg
    buttons
  })
}

return gotoResearchUpgradeMsgBox