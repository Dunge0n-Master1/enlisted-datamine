from "%enlSqGlob/ui_library.nut" import *

let hoverImage = require("%enlist/components/hoverImage.nut")
let changeResearchMsgbox = require("changeResearchMsgbox.nut")
let multiresearchWarningMsgbox = require("multiresearchWarningMsgbox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { titleTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { disableSquadExp } = require("%enlist/campaigns/campaignConfig.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let {
  tableStructure, researchStatuses, researchAction,
  curSquadProgress, buySquadLevel,
  LOCKED, DEPENDENT, NOT_ENOUGH_EXP, GROUP_RESEARCHED, CAN_RESEARCH,
  RESEARCHED, CHANGE_RESEARCH_TPL, BALANCE_ATTRACT_TRIGGER
} = require("researchesState.nut")


let activeTxtStyle = { color = titleTxtColor }.__update(fontBody)

let mkInfo = @(researchInfo) (researchInfo?.multiresearchGroup ?? 0) <= 0 ? null
  : loc("research/groupCanResearch")
let mkActiveText = @(text) { rendObj = ROBJ_TEXT, text }.__update(activeTxtStyle)


let statusCfg = {
  [LOCKED] = @(_researchDef) {
    warning = loc("research/warnResearchLocked")
  },
  [DEPENDENT] = @(researchDef) {
    warning = loc("Need to research previous")
    onResearch = function() {
      foreach (researchId in researchDef.requirements)
        if (researchStatuses.value?[researchId] != RESEARCHED)
          hoverImage.attractToImage(researchId)
    }
  },
  [NOT_ENOUGH_EXP] = @(researchDef) {
    warning = loc("Not enough army exp")
    info = mkInfo(researchDef)
    onResearch = function() {
      anim_start(BALANCE_ATTRACT_TRIGGER)
      let cost = curSquadProgress.value?.levelCost ?? 0
      if (cost <= 0 || disableSquadExp.value)
        return
      purchaseMsgBox({
        price = cost
        currencyId = "EnlistedGold"
        title = loc("Not enough army exp")
        description = loc("buy/squadLevelConfirmForResearch")
        purchase = @() multiresearchWarningMsgbox(researchDef, tableStructure.value.researches,
            @() buySquadLevel(function(isSuccess) {
              if (!isSuccess)
                return
              sound_play("ui/purchase_level_squad")
              researchAction(researchDef.research_id)
            }))
        alwaysShowCancel = true
        srcComponent = "buy_researches_level_on_research"
      })
    }
  },
  [GROUP_RESEARCHED] = @(researchDef) {
    info = loc("research/groupResearched")
    researchText = loc("research/changeResearch")
    onResearch = @() changeResearchMsgbox(researchDef)
    researchPrice = {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = mkTextRow(loc("research/researchPrice"), mkActiveText,
        { ["{price}"] = mkItemCurrency({ currencyTpl = CHANGE_RESEARCH_TPL, count = 1 }) }) //warning disable: -forgot-subst
    }
  },
  [CAN_RESEARCH] = @(researchDef) {
    info = mkInfo(researchDef)
    onResearch = @() multiresearchWarningMsgbox(researchDef, tableStructure.value.researches,
      function() {
        sound_play("ui/upgrade_unlock")
        researchAction(researchDef.research_id)
      })
  }
}

return statusCfg
