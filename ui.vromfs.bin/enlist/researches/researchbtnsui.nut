from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let researchUnlockAction = require("multiresearchWarningMsgbox.nut")
let changeResearchMsgbox = require("changeResearchMsgbox.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")

let { sound_play } = require("sound")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontMedium, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { promoWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { mkPageInfoAnim, priceIconSize, priceIcon } = require("researchesPkg.nut")
let { mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let { disableSquadExp } = require("%enlist/campaigns/campaignConfig.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")
let {
  colPart, columnGap, defTxtColor, titleTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let {
  tableStructure, selectedResearch, researchStatuses, research,
  isBuyLevelInProgress, isResearchInProgress, curSquadProgress,
  buySquadLevel,
  LOCKED, DEPENDENT, NOT_ENOUGH_EXP, GROUP_RESEARCHED, CAN_RESEARCH,
  RESEARCHED, CHANGE_RESEARCH_TPL
} = require("researchesState.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)


let currencyId = "EnlistedGold"

let changeCurrency = getCurrencyPresentation(CHANGE_RESEARCH_TPL)
let changeOrder = mkCurrencyImage(changeCurrency?.icon, [priceIconSize, priceIconSize])

let researchedSign = faComp("check-circle-o", {
  margin = columnGap
  fontSize = hdpx(48)
  color = titleTxtColor
})

let mkMultiresearchInfo = @(r) (r?.multiresearchGroup ?? 0) > 0
  ? loc("research/groupCanResearch")
  : null


let statusCfg = {
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


let mkTextArea = @(text, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(defTxtStyle, override)


let function mkResearchPrice(researchDef) {
  let { price = 0 } = researchDef
  if (price == 0)
    return null

  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = columnGap
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("research/researchPrice", { price })
      }.__update(headerTxtStyle)
      priceIcon
    ]
  }
}


let mkResearchBtn = @(onResearch, researchText) @() {
  watch = [isBuyLevelInProgress, isResearchInProgress]
  children = isBuyLevelInProgress.value || isResearchInProgress.value
    ? mkSpinner()
    : Bordered(researchText, onResearch, {
        hotkeys = [[ "^J:X | Enter", { description = { skip = true }} ]]
        margin = 0
      })
}


let mkResearchUnlockedView = @(research_id) {
  size = [flex(), SIZE_TO_CONTENT]
  children = {
    key = $"research_footer_{research_id}"
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      researchedSign
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("research/unlocked"))
      }.__update(headerTxtStyle)
    ]
  }.__update(mkPageInfoAnim(0.5))
}


let mkUnlockBlock = @(researchDef, specialPrice, researchText, onResearch)
  onResearch == null ? null
    : {
        flow = FLOW_VERTICAL
        gap = columnGap
        children = [
          specialPrice ?? mkResearchPrice(researchDef)
          mkResearchBtn(onResearch, researchText ?? loc("research/researchBtnText"))
        ]
      }


let function researchBtnUi() {
  let res = {
    watch = [selectedResearch, researchStatuses]
  }

  let researchDef = selectedResearch.value
  if (!researchDef)
    return res

  let statuses = researchStatuses.value
  if (statuses == null)
    return res

  let { research_id } = researchDef
  let status = statuses?[research_id]
  let cfg = statusCfg?[status](researchDef)
  if (cfg == null)
    return res.__update(mkResearchUnlockedView(research_id))

  let {
    info = null, warning = null, onResearch = null,
    specialPrice = null, researchText = null
  } = cfg
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    children = {
      key = $"research_footer_{research_id}"
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = columnGap
      children = [
        info == null ? null : mkTextArea(utf8ToUpper(info), headerTxtStyle)
        warning == null ? null : mkTextArea(utf8ToUpper(warning), headerTxtStyle)
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = columnGap
          children = [
            mkUnlockBlock(researchDef, specialPrice, researchText, onResearch)
          ]
        }
      ]
    }.__update(mkPageInfoAnim(0.5))
  })
}

let researchFooterUi = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = colPart(1)
  children = [
    researchBtnUi
    promoWidget("research_section", null, { margin = [columnGap, 0] })
  ]
}

return researchFooterUi
