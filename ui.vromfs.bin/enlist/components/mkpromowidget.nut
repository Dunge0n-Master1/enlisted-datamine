from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let { campPresentation, curCampaignAccessItem } = require("%enlist/campaigns/campaignConfig.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { unlockCampaignPromo } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let { colPart, smallPadding, midPadding, titleTxtColor, attentionTxtColor, bigPadding,
  brightAccentColor, defTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { slotBaseSize } = require("%enlSqGlob/ui/viewConst.nut")

let premiumBlockStyle = @(_config) {
  borderColor = attentionTxtColor
  iconSize = hdpxi(36)
  iconPath = "!ui/uiskin/currency/enlisted_prem.svg:{0}:{0}:K"
}

let premiumBlockText = @(_config, txtColor) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  minWidth = SIZE_TO_CONTENT
  parSpacing = smallPadding
  behavior = Behaviors.TextArea
  text = loc("premium/widget")
}.__update(tiny_txt, txtColor)

let greenGradient = mkColoredGradientX({colorLeft=0xFF007800, colorRight=0xFF145014})
let hoverGradient = mkColoredGradientX({colorLeft=0xFF009000, colorRight=0xFF007800})

let mkPromoWidget = function(fnStyle, fnText, openWnd) {
  let discountData = Computed(function(prev){
    if (prev == FRP_INITIAL)
      prev = { isDiscountActive = false, endTime = 0, discountInPercent = 0 }

    let { discountIntervalTs = [], discountInPercent = 0 } = curCampaignAccessItem.value
    let [ beginTime = 0, endTime = 0 ] = discountIntervalTs
    let isDiscountActive = beginTime > 0
      && beginTime <= serverTime.value
      && (serverTime.value <= endTime || endTime == 0)
    let res = {isDiscountActive, endTime, discountInPercent}
    return isEqual(res, prev) ? prev : res
  })
  return function(srcWindow, srcComponent = null, override = {}){
    let { iconSize = 0, borderColor = null, iconPath = "" } = fnStyle(campPresentation.value)
    let icon = {
      rendObj = ROBJ_IMAGE
      size = [iconSize, iconSize]
      image = Picture(iconPath.subst(iconSize))
    }
    return watchElemState(@(sf) {
      watch = [campPresentation, discountData]
      size = [slotBaseSize[0], SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onClick = @() openWnd(srcWindow, srcComponent)
      children = [
        !discountData.value.isDiscountActive ? null : {
          rendObj = ROBJ_IMAGE
          size = [flex(), SIZE_TO_CONTENT]
          image = sf & S_HOVER ? hoverGradient : greenGradient
          fillColor = sf & S_HOVER ? Color(0, 0, 0, 210) : null
          padding = smallPadding
          children = {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            size = [flex(), SIZE_TO_CONTENT]
            gap = smallPadding
            children = [
              mkCountdownTimer({ timestamp = discountData.value.endTime })
              txt({
                text = utf8ToUpper(loc("shop/discountNotify"))
                color = titleTxtColor
              }).__update(sub_txt)
              { size = flex() }
              mkDiscountWidget(discountData.value.discountInPercent)
            ]
          }
        }
        {
          rendObj = ROBJ_BOX
          size = [flex(), SIZE_TO_CONTENT]
          padding = [midPadding, bigPadding]
          valign = ALIGN_CENTER
          borderWidth = [0, 0, hdpx(1), 0]
          borderColor
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = [
            icon
            fnText(campPresentation.value,
              { color = sf & S_HOVER ? brightAccentColor : defTxtColor })
            faComp("chevron-right", {
              fontSize = colPart(0.5)
              vplace = ALIGN_CENTER
              hplace = ALIGN_RIGHT
              color = sf & S_HOVER ? brightAccentColor : defTxtColor
            })
          ]
        }
      ]
    }.__update(override))
  }
}

let openPremiumWnd = function(srcWindow, srcComponent) {
  premiumWnd()
  sendBigQueryUIEvent("open_premium_window", srcWindow, srcComponent)
}

let premiumWidget = mkPromoWidget(premiumBlockStyle, premiumBlockText, openPremiumWnd)

let promoWidget = @(srcWindow, srcComponent = null, override = {}) @() {
  watch = [isCurCampaignProgressUnlocked, hasPremium]
  children = !isCurCampaignProgressUnlocked.value ? unlockCampaignPromo(override)
    : hasPremium.value ? null
    : premiumWidget(srcWindow, srcComponent, override)
}

return {
  promoWidget
  premiumWidget
}