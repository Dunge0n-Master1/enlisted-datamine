from "%enlSqGlob/ui_library.nut" import *

let { fontXXSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, panelBgColor, midPadding } = require("%enlSqGlob/ui/designConst.nut")
let cursors = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { premiumActiveInfo, premiumImage, premiumBg
} = require("%enlist/currency/premiumComp.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { premiumProducts } = require("%enlist/shop/armyShopState.nut")
let { mkNotifierBlink } = require("%enlist/components/mkNotifier.nut")


let IMAGE_WIDTH = colFull(1) - midPadding * 2
let btnWidth = colFull(1)


let hasDiscount = Computed(@() premiumProducts.value.findindex(@(i)
  (i?.discountInPercent ?? 0) > 0) != null)


let premiumWidget = watchElemState(@(sf) {
  watch = hasDiscount
  rendObj = ROBJ_SOLID
  color = panelBgColor
  size = [btnWidth, btnWidth]
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
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
    {
      rendObj = ROBJ_IMAGE
      opacity = sf & S_HOVER ? 1 : 0.6
      size = [btnWidth, btnWidth]
      image = premiumBg(btnWidth)
    }
    premiumImage(IMAGE_WIDTH)
    !hasDiscount.value ? null
      : mkNotifierBlink(loc("shop/discountNotify"), {
          size = SIZE_TO_CONTENT,
          vplace = ALIGN_BOTTOM
        }, {}, fontXXSmall)
  ]
})

return premiumWidget
