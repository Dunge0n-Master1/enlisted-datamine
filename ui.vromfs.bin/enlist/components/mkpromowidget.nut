from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let {
  needFreemiumStatus, campPresentation, curCampaignAccessItem
} = require("%enlist/campaigns/campaignConfig.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { unlockCampaignPromo } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let {
  colPart, smallPadding, midPadding, titleTxtColor, attentionTxtColor, bigPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { slotBaseSize } = require("%enlSqGlob/ui/viewConst.nut")


let freemiumBlockStyle = @(config) {
  borderColor = config?.color
  iconSize = hdpxi(42)
  iconPath = config?.widgetIcon ?? ""
}

let freemiumBlockText = @(config) {
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc($"{config?.locBase}/trialVersion"))
    }.__update(sub_txt)
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc($"{config?.locBase}/widget/fullVersion", "")
    }.__update(sub_txt)
  ]
}

let premiumBlockStyle = @(_config) {
  borderColor = attentionTxtColor
  iconSize = hdpxi(36)
  iconPath = "!ui/uiskin/currency/enlisted_prem.svg:{0}:{0}:K"
}

let premiumBlockText = @(_config) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  parSpacing = smallPadding
  behavior = Behaviors.TextArea
  text = loc("premium/widget")
}.__update(sub_txt)

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
    return watchElemState(@(sf) {
      watch = [campPresentation, discountData]
      size = [SIZE_TO_CONTENT, colPart(1)]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onClick = @() openWnd(srcWindow, srcComponent)
      children = [
        {
          rendObj = ROBJ_BOX
          padding = [midPadding, bigPadding]
          valign = ALIGN_CENTER
          size = [slotBaseSize[0], SIZE_TO_CONTENT]
          borderWidth = [0, 0, hdpx(1), 0]
          borderColor
          flow = FLOW_HORIZONTAL
          gap = colPart(0.1)
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = bigPadding
              children = [
                {
                  rendObj = ROBJ_IMAGE
                  size = [iconSize, iconSize]
                  hplace = ALIGN_LEFT
                  image = Picture(iconPath.subst(iconSize))
                  vplace = ALIGN_CENTER
                }
                fnText(campPresentation.value)
              ]
            }
            faComp("chevron-right", {
              fontSize = colPart(0.5)
              vplace = ALIGN_CENTER
              hplace = ALIGN_RIGHT
            })
          ]
        }
        !discountData.value.isDiscountActive ? null : {
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            {
              rendObj = ROBJ_IMAGE
              size = [flex(), hdpx(36)]
              image = sf & S_HOVER ? hoverGradient : greenGradient
              fillColor = sf & S_HOVER ? Color(0, 0, 0, 210) : null
            }
            {
              flow = FLOW_HORIZONTAL
              valign = ALIGN_CENTER
              size = [flex(), hdpx(36)]
              margin = [0, 0, 0, hdpx(10)]
              gap = hdpx(10)
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

let openFreemiumWnd = function(srcWindow, srcComponent) {
  freemiumWnd()
  sendBigQueryUIEvent("open_freemium_window", srcWindow, srcComponent)
}

let premiumWidget = mkPromoWidget(premiumBlockStyle, premiumBlockText, openPremiumWnd)

let freemiumWidget = mkPromoWidget(freemiumBlockStyle, freemiumBlockText, openFreemiumWnd)

let promoWidget = @(srcWindow, srcComponent = null, override = {}) @(){
  watch = [isCurCampaignProgressUnlocked, needFreemiumStatus, hasPremium]
  children = !isCurCampaignProgressUnlocked.value ? unlockCampaignPromo(override)
    : needFreemiumStatus.value ? freemiumWidget(srcWindow, srcComponent, override)
    : hasPremium.value ? null
    : premiumWidget(srcWindow, srcComponent, override)
}

return {
  promoWidget
  premiumWidget
  freemiumWidget
}