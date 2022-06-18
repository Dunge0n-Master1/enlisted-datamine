from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigGap, defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { premiumImage } = require("premiumComp.nut")
let { FAButton } = require("%ui/components/textButton.nut")
let premiumWnd = require("premiumWnd.nut")
let { hasPremium } = require("premium.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let freemiumPromo = require("%enlist/currency/pkgFreemiumWidgets.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")
let { unlockCampaignPromo } = require("%enlist/soldiers/lockCampaignPkg.nut")

let sendOpenPremium = @(srcWindow, srcComponent)
  sendBigQueryUIEvent("open_premium_window", srcWindow, srcComponent)

let mkPromoSmall = @(locId, srcWindow = null, srcComponent = null, override = null, txtStyle = tiny_txt)
function() {
  let res = { watch = hasPremium }
  if (hasPremium.value)
    return res
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    gap = bigGap
    flow = FLOW_HORIZONTAL
    children = [
      premiumImage(hdpx(35))
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(locId)
        color = defTxtColor
      }.__update(txtStyle)
      FAButton("shopping-cart", function() {
        premiumWnd()
        sendOpenPremium(srcWindow, srcComponent)
      }, { borderWidth = 0, borderRadius = 0, fontSize = hdpx(35) })
    ]
  }).__update(override ?? {})
}

let promoSmall = @(srcWindow = null, srcComponent = null, override = {}, locId = null, txtStyle = tiny_txt)
@(){
  watch = [isCurCampaignProgressUnlocked, needFreemiumStatus]
  size = [flex(), SIZE_TO_CONTENT]
  children = !isCurCampaignProgressUnlocked.value ? unlockCampaignPromo(override)
    : needFreemiumStatus.value ? freemiumPromo(srcWindow, srcComponent, override)
    : locId != null ? mkPromoSmall(locId, srcWindow, srcComponent, override, txtStyle)
    : null
}

return promoSmall