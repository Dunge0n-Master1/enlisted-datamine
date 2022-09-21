from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gap, bigGap, blurBgColor, blurBgFillColor, researchListTabPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let {statusIconLocked, statusIconChosen} =  require("%enlSqGlob/ui/style/statusIcon.nut")
let {TextDefault} = require("%ui/style/colors.nut")
let textButton = require("%ui/components/textButton.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(72) })
let { LOCKED, CAN_RESEARCH, DEPENDENT, RESEARCHED, NOT_ENOUGH_EXP, BALANCE_ATTRACT_TRIGGER,
  GROUP_RESEARCHED, selectedResearch, researchStatuses, curSquadProgress, buySquadLevel,
  research, isResearchInProgress, isBuyLevelInProgress, tableStructure, CHANGE_RESEARCH_TPL
} = require("researchesState.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { sound_play } = require("sound")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let multiresearchWarningMsgbox = require("multiresearchWarningMsgbox.nut")
let changeResearchMsgbox = require("changeResearchMsgbox.nut")
let { mkGlyphsStyle } = require("%enlSqGlob/ui/soldierClasses.nut")
let { disableSquadExp } = require("%enlist/campaigns/campaignConfig.nut")
let { promoWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")


let priceIconSize = hdpx(30)

let mrInfo = @(research) (research?.multiresearchGroup ?? 0) <= 0 ? null
  : loc("research/groupCanResearch")
let mkActiveText = @(text) { rendObj = ROBJ_TEXT, text }.__update(body_txt)

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
    info = mrInfo(researchDef)
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
              research(researchDef.research_id)
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
    info = mrInfo(researchDef)
    onResearch = @() multiresearchWarningMsgbox(researchDef, tableStructure.value.researches,
      function() {
        sound_play("ui/upgrade_unlock")
        research(researchDef.research_id)
      })
  }
}

let mkResearchDescription = @(researchDef) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_LEFT
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = TextDefault
  text = loc(researchDef?.description, researchDef?.params)
  tagsTable = mkGlyphsStyle(hdpx(24))
}.__update(body_txt)

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
    ? spinner
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
      }.__update(body_txt)
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
      }.__update(body_txt)
      !cfg?.warning ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = cfg?.warning
        halign = ALIGN_CENTER
        color = statusIconLocked
      }.__update(body_txt)
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
      }.__update(h2_txt)
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
