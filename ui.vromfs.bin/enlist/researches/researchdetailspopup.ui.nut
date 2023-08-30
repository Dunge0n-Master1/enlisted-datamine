from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { gap, bigGap, blurBgColor, blurBgFillColor, researchListTabPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let {statusIconLocked, statusIconChosen} =  require("%enlSqGlob/ui/style/statusIcon.nut")
let {TextDefault} = require("%ui/style/colors.nut")
let textButton = require("%ui/components/textButton.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let spinner = require("%ui/components/spinner.nut")
let {
  selectedResearch, researchStatuses, isResearchInProgress, isBuyLevelInProgress
} = require("researchesState.nut")
let { mkGlyphsStyle } = require("%enlSqGlob/ui/soldierClasses.nut")
let { promoWidget } = require("%enlist/components/mkPromoWidget.nut")
let statusCfg = require("researchStatuses.nut")


let priceIconSize = hdpxi(30)
let waitingSpinner = spinner(hdpx(36))
let mkActiveText = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSub)


let mkResearchDescription = @(researchDef) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_LEFT
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = TextDefault
  text = loc(researchDef?.description, researchDef?.params)
  tagsTable = mkGlyphsStyle(hdpx(24))
}.__update(fontSub)

let function mkResearchPrice(researchDef) {
  let { price = 0 } = researchDef
  if (price == 0)
    return null

  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = bigGap
    children = [
      mkActiveText(loc("research/researchPrice", { price }))
      {
        rendObj = ROBJ_IMAGE
        size = [priceIconSize, priceIconSize]
        image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(priceIconSize))
      }
    ]
  }
}

let mkResearchBtn = @(onResearch, researchText) @() {
  watch = [isBuyLevelInProgress, isResearchInProgress]
  children = isBuyLevelInProgress.value || isResearchInProgress.value
    ? waitingSpinner
    : textButton.PrimaryFlat(researchText, onResearch, {
        hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
        margin = 0
      })
}

let mkResearchFooter = @(researchDef) function() {
  let res = { watch = researchStatuses }
  let status = researchStatuses.value
  if (status == null)
    return res

  let cfg = statusCfg?[status?[researchDef.research_id]](researchDef)
  if (cfg == null)
    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      padding = bigGap
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        text = loc("research/unlocked")
        halign = ALIGN_CENTER
        color = statusIconChosen
      }.__update(fontSub)
    })

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = bigGap
    padding = bigGap
    children = [
      !cfg?.info ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = cfg?.info
        halign = ALIGN_CENTER
      }.__update(fontSub)
      !cfg?.warning ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = cfg?.warning
        halign = ALIGN_CENTER
        color = statusIconLocked
      }.__update(fontSub)
      cfg?.onResearch ? (cfg?.researchPrice ?? mkResearchPrice(researchDef)) : null
      cfg?.onResearch
        ? mkResearchBtn(cfg.onResearch, cfg?.researchText ?? loc("research/researchBtnText"))
        : null
    ]
  })
}

let function researchInfoView() {
  let res = { watch = selectedResearch, size = flex() }
  let researchDef = selectedResearch.value
  if (!researchDef)
    return res

  return res.__update({
    key = researchDef.research_id
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = blurBgFillColor
    padding = researchListTabPadding
    transform = { pivot = [0, 0]}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
      { prop = AnimProp.scale, from =[0, 1], to =[1, 1], play = true, duration = 0.15, easing = OutQuad }
    ]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(researchDef?.name, researchDef?.params)
        tagsTable = mkGlyphsStyle(hdpx(26))
      }.__update(fontHeading2)
      {
        size = flex()
        margin = [researchListTabPadding]
        children = makeVertScroll(mkResearchDescription(researchDef), { styling = thinStyle })
      }
      mkResearchFooter(researchDef)
      promoWidget("research_section", null, {
        margin = [hdpx(40), 0, hdpx(20), 0]
      })
    ]
  })
}

return {
  flow = FLOW_VERTICAL
  size = flex()
  gap = gap
  children = researchInfoView
}
