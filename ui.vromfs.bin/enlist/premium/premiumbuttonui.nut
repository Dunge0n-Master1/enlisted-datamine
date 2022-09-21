from "%enlSqGlob/ui_library.nut" import *

let { fontXXSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, panelBgColor, midPadding } = require("%enlSqGlob/ui/designConst.nut")
let cursors = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { premiumActiveInfo, premiumImage } = require("%enlist/currency/premiumComp.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { premiumProducts } = require("%enlist/shop/armyShopState.nut")
let { mkNotifierBlink } = require("%enlist/components/mkNotifier.nut")

let IMAGE_WIDTH = colFull(1) - midPadding * 2

let hasDiscount = Computed(@() premiumProducts.value.findindex(@(i)
  (i?.discountInPercent ?? 0) > 0) != null)

let premiumWidget = @() {
  watch = hasDiscount
  rendObj = ROBJ_SOLID
  color = panelBgColor
  size = [colFull(1), colFull(1)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick = function() {
    premiumWnd()
    sendBigQueryUIEvent("open_premium_window", null, "menubar_premium")
  }
  onHover = @(on) cursors.setTooltip(on
    ? tooltipBox(premiumActiveInfo())
    : null)
  children = [
    premiumImage(IMAGE_WIDTH)
    !hasDiscount.value ? null
      : mkNotifierBlink(loc("shop/discountNotify"), {
          size = SIZE_TO_CONTENT,
          vplace = ALIGN_BOTTOM
        }, {}, fontXXSmall)
  ]
}

return premiumWidget
