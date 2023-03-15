from "%enlSqGlob/ui_library.nut" import *

let researchUnlockAction = require("multiresearchWarningMsgbox.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")
let changeResearchMsgbox = require("changeResearchMsgbox.nut")

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { disableSquadExp } = require("%enlist/campaigns/campaignConfig.nut")
let { sound_play } = require("sound")
let { mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let { priceIconSize } = require("researchesPkg.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")
let { columnGap, titleTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let {
  tableStructure, researchStatuses, research,
  curSquadProgress, buySquadLevel,
  LOCKED, DEPENDENT, NOT_ENOUGH_EXP, GROUP_RESEARCHED, CAN_RESEARCH,
  RESEARCHED, CHANGE_RESEARCH_TPL
} = require("researchesState.nut")


let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)

let currencyId = "EnlistedGold"

let mkMultiresearchInfo = @(r) (r?.multiresearchGroup ?? 0) > 0
  ? loc("research/groupCanResearch")
  : null

let changeCurrency = getCurrencyPresentation(CHANGE_RESEARCH_TPL)
let changeOrder = mkCurrencyImage(changeCurrency?.icon, [priceIconSize, priceIconSize])


let researchStatusesCfg = {
  [LOCKED] = @(_researchDef) {
    warning = loc("research/warnResearchLocked")
  },
  [DEPENDENT] = @(researchDef) {
    warning = loc("Need to research previous")
    onResearch = function() {
      foreach (reqId in researchDef.requirements)
        if (researchStatuses.value?[reqId] != RESEARCHED)
          hoverImage.attractToImage(reqId)
    }
  },
  [NOT_ENOUGH_EXP] = @(researchDef) {
    warning = loc("Not enough army exp")
    info = mkMultiresearchInfo(researchDef)
    onResearch = function() {
      let price = curSquadProgress.value?.levelCost ?? 0
      if (price <= 0 || disableSquadExp.value)
        return

      purchaseMsgBox({
        price
        currencyId
        title = loc("Not enough army exp")
        description = loc("buy/squadLevelConfirmForResearch")
        purchase = @() researchUnlockAction(researchDef,
          tableStructure.value.researches,
          @() buySquadLevel(function(isSuccess) {
            if (!isSuccess)
              return
            sound_play("ui/purchase_level_squad")
            research(researchDef.research_id)
          })
        )
        alwaysShowCancel = true
        srcComponent = "buy_researches_level_on_research"
      })
    }
  },
  [GROUP_RESEARCHED] = @(researchDef) {
    info = loc("research/groupResearched")
    researchText = loc("research/changeResearch")
    specialPrice = {
      flow = FLOW_HORIZONTAL
      gap = columnGap
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("research/researchPrice", { price = 1 })
        }.__update(headerTxtStyle)
        changeOrder
      ]
    }
    onResearch = @() changeResearchMsgbox(researchDef)
  },
  [CAN_RESEARCH] = @(researchDef) {
    info = mkMultiresearchInfo(researchDef)
    onResearch = @() researchUnlockAction(researchDef,
      tableStructure.value.researches,
      function() {
        sound_play("ui/upgrade_unlock")
        research(researchDef.research_id)
      })
  }
}

return researchStatusesCfg
