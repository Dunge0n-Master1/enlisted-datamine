from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let cursors = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let premiumWnd = require("premiumWnd.nut")
let { premiumActiveInfo, premiumImage } = require("premiumComp.nut")
let { smallPadding, bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { premiumProducts } = require("%enlist/shop/armyShopState.nut")
let mkNotifier = require("%enlist/components/mkNotifier.nut")

let IMAGE_WIDTH = hdpx(35)

let hasDiscount = Computed(@()
  premiumProducts.value.findindex(@(i) (i?.discountInPercent ?? 0) > 0) != null
)

let premiumWidget = @(){
  watch = hasDiscount
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = bigPadding
  size = [IMAGE_WIDTH, SIZE_TO_CONTENT]
  vplace = ALIGN_TOP
  gap = smallPadding
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
      : mkNotifier(loc("shop/discountNotify"), { size = SIZE_TO_CONTENT }, {}, tiny_txt)
  ]
}

return premiumWidget
