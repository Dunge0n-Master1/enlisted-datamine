from "%enlSqGlob/ui_library.nut" import *

let { findSlotUnlockRequirement, focusResearch } = require("%enlist/researches/researchesFocus.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")
let { configs } = require("%enlist/meta/configs.nut")

let { setAutoChapter } = require("%enlist/shop/shopState.nut")
let { setCurSection, jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { doesLocTextExist } = require("dagor.localize")
let {
  curArmySquadsUnlocks, scrollToCampaignLvl
} = require("%enlist/soldiers/model/armyUnlocksState.nut")


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

  let { research = null, squadId = null } = findSlotUnlockRequirement(soldier, researchSlot)
  local unlock = null
  if (research != null)
    buttons.append({ text = loc("GoToResearch"),
      action = @() focusResearch(research), isCurrent = true })
  else if (squadId != null) {
    unlock = curArmySquadsUnlocks.value
      .findvalue(@(u) u.unlockType == "squad" && u.unlockId == squadId)
    if (unlock != null)
      buttons.append({ text = loc("squads/gotoUnlockBtn"),
        action = function() {
          scrollToCampaignLvl(unlock.level)
          jumpToArmyProgress()
        },
        isCurrent = true })
  }
  else
    buttons.append({ text = loc("GoToEquipment"),
      action = function() {
        setAutoChapter("item_group")
        setCurSection("SHOP")
      }
    })

  let needBackpack = research == null && unlock == null && researchSlot != slotType

  local textMsg
  if (needBackpack) {
    let msgLocId = $"slotBlocked/{slotType}"
    textMsg = doesLocTextExist(msgLocId)
      ? loc(msgLocId)
      : loc("slotBlockedDefault")
  } else if (unlock != null)
    textMsg = loc("slotClassSquad", { level = unlock.level })
  else
    textMsg = loc("slotClassResearch", { soldierClass })

  msgbox.show({
    text = textMsg
    buttons
  })
}

return gotoResearchUpgradeMsgBox