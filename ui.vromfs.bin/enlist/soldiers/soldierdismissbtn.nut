from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { ceil } = require("%sqstd/math.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(50) })
let { showMessageWithContent, showMsgbox } = require("%enlist/components/msgbox.nut")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { SmallFlat, Bordered } = require("%ui/components/textButton.nut")
let { reserveSoldiers, applySoldierManage, dismissSoldier, isDismissInProgress
} = require("model/chooseSoldiersState.nut")
let { getLinkedArmyName, getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let { curArmyReserve, curArmyReserveCapacity } = require("model/reserve.nut")
let { RETIRE_ORDER, retireReturn } = require("model/config/soldierRetireConfig.nut")
let { curUpgradeDiscount } = require("%enlist/campaigns/campaignConfig.nut")


let mkDismissWarning = @(armyId, guid, count, cb) showMessageWithContent({
  content = {
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    gap = hdpx(40)
    children = [
      {
        size = [sw(35), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("retireSoldier/title")
      }.__update(h2_txt)
      {
        size = [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("retireSoldier/desc")
      }.__update(body_txt)
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          txt(loc("retireSoldier/currencyWillReturn")).__update(sub_txt)
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

let mkApplyChangesWarning = @(cb) showMsgbox({
  text = loc("msg/applySoldiersChangesRequired")
  buttons = [
    { text = loc("Apply"),
      action = function() {
        applySoldierManage()
        cb()
      }
      isCurrent = true
    }
    { text = loc("Cancel")
      isCancel = true
    }
  ]
})


let function mkDismissBtn(soldier, ctor = SmallFlat, cb = @() null) {
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
      hplace = ALIGN_RIGHT
      children = [
        isDismissInProgress.value
          ? spinner
          : ctor(loc("btn/removeSoldier"),
              @() getLinkedSquadGuid(soldier) != null
                ? mkApplyChangesWarning(cb)
                : mkDismissWarning(armyId, guid, retireCount, cb),
              {
                margin = 0
                padding = [bigPadding, 2 * bigPadding]
              })
      ]
    })
  }
}


let smallDismissBtn = @(soldier) mkDismissBtn(soldier)
let dismissBtn = @(soldier, cb = @() null) mkDismissBtn(soldier, Bordered, cb)

return {
  smallDismissBtn
  dismissBtn
}
