from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontLarge, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { ceil } = require("%sqstd/math.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let { showMessageWithContent, showMsgbox } = require("%enlist/components/msgbox.nut")
let { bigPadding, defTxtColor, titleTxtColor, colPart,
  colFull } = require("%enlSqGlob/ui/designConst.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { reserveSoldiers, applySoldierManage, dismissSoldier, isDismissInProgress
} = require("model/chooseSoldiersState.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { curArmyReserve, curArmyReserveCapacity } = require("model/reserve.nut")
let { RETIRE_ORDER, retireReturn } = require("model/config/soldierRetireConfig.nut")
let { curUpgradeDiscount } = require("%enlist/campaigns/campaignConfig.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let descTxtStyle = { color = defTxtColor }.__update(fontMedium)
let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)


let mkDismissWarning = @(armyId, guid, count, cb) showMessageWithContent({
  content = {
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    gap = colPart(0.64)
    children = [
      {
        size = [sw(35), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("retireSoldier/title")
      }.__update(headerTxtStyle)
      {
        size = [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("retireSoldier/desc")
      }.__update(descTxtStyle)
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("retireSoldier/currencyWillReturn")
          }.__update(defTxtStyle)
          mkItemCurrency({ currencyTpl = RETIRE_ORDER, count })
        ]
      }
    ]
  }
  buttons = [
    {
      text = loc("Yes")
      action = function() {
        dismissSoldier(armyId, guid)
        cb()
      }
      isCurrent = true
    }
    {
      text = loc("Cancel"), isCancel = true
    }
  ]
})

let mkApplyChangesWarning = @() showMsgbox({
  text = loc("msg/applySoldiersChangesRequired")
  buttons = [
    { text = loc("Apply"),
      action = function() {
        applySoldierManage()
      }
      isCurrent = true
    }
    { text = loc("Cancel")
      isCancel = true
    }
  ]
})


let function mkDismissBtn(soldier, cb) {
  if (soldier == null)
    return null

  let { guid, sClass, tier, heroTpl } = soldier
  let armyId = getLinkedArmyName(soldier)
  return function() {
    let res = { watch = [
      curArmyReserve, curArmyReserveCapacity, isDismissInProgress,
      retireReturn, reserveSoldiers
    ]}

    if (reserveSoldiers.value.findindex(@(s) s.guid == guid ) == null)
      return res

    local retireCount = retireReturn.value?[sClass][tier] ?? 0
    if (retireCount == 0
        || curArmyReserveCapacity.value == 0
        || curArmyReserve.value.len() == 0
        || heroTpl != "")
      return res

    let retireCountMult = 1.0 - curUpgradeDiscount.value
    retireCount = ceil(retireCount * retireCountMult).tointeger()
    return res.__update({
      hplace = ALIGN_CENTER
      pos = [colFull(4), 0]
      children = [
        isDismissInProgress.value
          ? mkSpinner
          : Bordered(loc("btn/removeSoldier"),
              @() getLinkedSquadGuid(soldier) != null
                ? mkApplyChangesWarning()
                : mkDismissWarning(armyId, guid, retireCount, cb))
      ]
    })
  }
}


return mkDismissBtn
