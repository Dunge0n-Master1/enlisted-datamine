from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { logerr } = require("dagor.debug")
let { defTxtColor, titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { MsgMarkedText } = require("%ui/style/colors.nut")
let { showMessageWithContent } = require("%enlist/components/msgbox.nut")
let { RESEARCHED, researchStatuses, tableStructure, CHANGE_RESEARCH_TPL, changeResearchBalance,
  changeResearchGoldCost, changeResearch, buyChangeResearch
} = require("researchesState.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let colorize = require("%ui/components/colorize.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { primaryButtonStyle } = require("%ui/components/textButton.nut")
let { disableChangeResearch } = require("%enlist/campaigns/campaignConfig.nut")

let textarea = @(text, color) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color
  text
}.__update(body_txt)

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(body_txt)

let balanceText = @() {
    watch = [changeResearchBalance, changeResearchGoldCost, disableChangeResearch]
    margin = [fsh(5), 0, 0, 0]
  }.__update(changeResearchBalance.value == 0
    ? {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkText(loc("research/change_research_no_orders"))
          disableChangeResearch.value ? null : {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            children = mkTextRow(loc("research/can_change_research_by_gold"),
              mkText,
              { ["{price}"] = mkCurrency({  //warning disable: -forgot-subst
                currency = enlistedGold
                price = changeResearchGoldCost.value
              }) })
          }
        ]
      }
    : {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = mkTextRow(loc("research/change_research_order_balance", { count = changeResearchBalance.value }),
          mkText,
          { ["{balance}"] = mkItemCurrency({  //warning disable: -forgot-subst
              currencyTpl = CHANGE_RESEARCH_TPL,
              count = changeResearchBalance.value
            })
          })
      })

let function doChangeResearch(researchFrom, researchTo) {
  if (changeResearchBalance.value > 0) {
    changeResearch(researchFrom, researchTo)
    return
  }
  purchaseMsgBox({
    price = changeResearchGoldCost.value
    currencyId = "EnlistedGold"
    title = loc("research/applyChangeResearch")
    purchase = @() buyChangeResearch(researchFrom, researchTo)
    alwaysShowCancel = true
    showOnlyWhenNotEnoughMoney = true
    srcComponent = "change_research_msgbox"
  })
}

let function changeResearchMsgbox(newResearch) {
  let { multiresearchGroup = 0, research_id, name = "", params = {} } = newResearch
  let curResearch = tableStructure.value.researches.findvalue(
    @(r) r?.multiresearchGroup == multiresearchGroup
      && r.research_id != research_id
      && researchStatuses.value?[r.research_id] == RESEARCHED)
  if (curResearch == null) {
    logerr("Try to change research when not researched any in the group")
    return
  }

  let buttons = Computed(function() {
    let res = []
    let isCurrencyAvailable = !disableChangeResearch.value && changeResearchBalance.value <= 0
    if (changeResearchBalance.value > 0 || isCurrencyAvailable)
      res.append({ text = loc("research/applyChangeResearch"), customStyle = primaryButtonStyle,
        action = @() doChangeResearch(curResearch.research_id, research_id) })
    res.append({ text = loc("Cancel"), isCancel = true })
    return res
  })

  showMessageWithContent({
    uid = "change_research_confirm"
    content = {
      flow = FLOW_VERTICAL
      size = [sw(50), SIZE_TO_CONTENT]
      margin = [fsh(5), 0]
      gap = fsh(3)
      halign = ALIGN_CENTER
      children = [
        textarea(loc("research/changeResearch"), titleTxtColor)
        textarea(
          loc("research/changeResearch/desc",
            {
              curResearch = colorize(MsgMarkedText, loc(curResearch.name, curResearch?.params))
              newResearch = colorize(MsgMarkedText, loc(name, params))
            }),
          defTxtColor)
        balanceText
      ]
    }
    buttons
  })
}

return changeResearchMsgbox