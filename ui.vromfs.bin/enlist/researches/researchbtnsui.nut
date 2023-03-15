from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let researchStatusesCfg = require("researchStatuses.nut")

let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontMedium, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { promoWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { mkPageInfoAnim, priceIcon } = require("researchesPkg.nut")
let {
  colPart, columnGap, defTxtColor, titleTxtColor, completedTxtColor,
  attentionTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let {
  selectedResearch, researchStatuses, isBuyLevelInProgress, isResearchInProgress
} = require("researchesState.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let attentionTxtStyle = { color = attentionTxtColor }.__update(fontLarge)


let researchedSign = faComp("check-circle-o", {
  margin = columnGap
  fontSize = hdpx(48)
  color = completedTxtColor
})


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
  let cfg = researchStatusesCfg?[status](researchDef)
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
        warning == null ? null : mkTextArea(utf8ToUpper(warning), attentionTxtStyle)
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
