from "%enlSqGlob/ui_library.nut" import *

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let JB = require("%ui/control/gui_buttons.nut")
let lbCategory = require("lbCategory.nut")
let { h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigGap } = require("%enlSqGlob/ui/viewConst.nut")
let { bestBattlesByMode, ratingBattlesCountByMode, getCategoriesByGroup } = require("lbState.nut")
let { TextActive, WindowHeader, TextDefault, UserNameColor
} = require("%ui/style/colors.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")


const WND_UID = "lb_best_battles_wnd"

let headerHeight = hdpx(45)
let rowHeight = hdpx(24)

let close = @() modalPopupWnd.remove(WND_UID)

let header = {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("lb/bestBattles")
    }.__update(h2_txt)
    { size = flex() }
    fontIconButton("times", { onClick = close })
  ]
}

let mkBattlesComputed = @(baseData, mode) Computed(@() (baseData.value?[mode] ?? [])
  .map(function(battle) {
    let modeBattle = battle?[mode] ?? {}
    let res = { timestamp = battle?["$timestamp"] ?? 0 }
    foreach (category in lbCategory) {
      let value = modeBattle?[category.field] ?? -1
      if (value > 0 || (category.field not in res))
        res[category.field] <- value
    }
    return res
  })
  .reverse())


let mkRows = @(lbCols, battles, lastBattleTimestamp, color) @() {
  watch = [battles, lastBattleTimestamp]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = battles.value.map(@(battle) {
    size = [flex(), rowHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = lbCols.map(@(cat, idx) {
      size = [flex(cat.relWidth), flex()]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = battle.timestamp == lastBattleTimestamp.value ? UserNameColor : color
      halign = idx == 0 ? ALIGN_LEFT : ALIGN_CENTER
      indent = idx == 0 ? bigGap : 0
      valign = ALIGN_CENTER
      text = cat.getText(battle)
    }.__update(sub_txt))
  })
}

let mkOtherRowsHeader = @(isVisible) @() {
  watch = isVisible
  children = isVisible.value
    ? {
        margin = [bigGap, 0, 0, 0]
        rendObj = ROBJ_TEXT
        text = loc("lb/battlesOutOfCount")
      }.__update(sub_txt)
    : null
}

let mkColumnsHeader = @(lbCols) {
  size = [flex(), headerHeight]
  margin = [0, 0, hdpx(10), 0]
  children = [
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = WindowHeader
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      children = lbCols.map(@(cat, idx) {
        size = [flex(cat.relWidth), flex()]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = TextDefault
        halign = idx == 0 ? ALIGN_LEFT : ALIGN_CENTER
        indent = idx == 0 ? bigGap : 0
        valign = ALIGN_CENTER
        text = loc(cat.locId)
      }.__update(sub_txt))
    }
  ]
}

let findMinTime = @(list, prevVal = 0)
  list.reduce(@(res, b) res == 0 ? b.timestamp : max(res, b.timestamp), prevVal)

let function mkLbTable(mode) {
  let lbCols = getCategoriesByGroup(mode).best
  let bestBattles = mkBattlesComputed(bestBattlesByMode, mode)
  let ratedCount = Computed(@() ratingBattlesCountByMode.value?[mode] ?? 0)
  let ratedBattles = Computed(@() bestBattles.value.slice(0, ratedCount.value))
  let otherBattles = Computed(@() bestBattles.value.slice(ratedCount.value))
  let lastBattleTimestamp = Computed(@() findMinTime(bestBattles.value))
  let hasOtherBattles = Computed(@() otherBattles.value.len() > 0)

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      mkColumnsHeader(lbCols)
      mkRows(lbCols, ratedBattles, lastBattleTimestamp, Color(255, 245, 180))
      mkOtherRowsHeader(hasOtherBattles)
      mkRows(lbCols, otherBattles, lastBattleTimestamp, TextActive)
    ]
  }
}

let mkBestBattlesWnd = @(mode) {
  size = [fsh(110), sh(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR_PANEL
  padding = bigGap
  flow = FLOW_VERTICAL
  gap = bigGap
  stopMouse = true
  children = [
    header
    makeVertScroll(mkLbTable(mode), { styling = thinStyle })
  ]
}

return @(mode) modalPopupWnd.add([sw(50), sh(20)], {
  uid = WND_UID
  valign = ALIGN_CENTER
  children = mkBestBattlesWnd(mode)
  popupBg = { rendObj = ROBJ_SOLID, color = Color(0, 0, 0, 140) }
  hotkeys = [[$"^{JB.B} | Esc", { action = close, description = loc("Close") }]]
})
