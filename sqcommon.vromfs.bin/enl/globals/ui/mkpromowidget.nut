from "%enlSqGlob/ui_library.nut" import *

let { freemiumColor, accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let faComp = require("%ui/components/faComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { unlockCampaignPromo } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")

let freemiumBlockStyle = {
  borderColor = freemiumColor
  iconSize = hdpx(42)
  iconPath = "!ui/uiskin/currency/enlisted_freemium.svg:{0}:{0}:K"
}

let freemiumBlockText = {
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("freemium/trialVersion"))
    }.__update(sub_txt)
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("freemium/widget/fullVersion")
    }.__update(sub_txt)
  ]
}

let premiumBlockStyle = {
  borderColor = accentTitleTxtColor
  iconSize = hdpx(36)
  iconPath = "!ui/uiskin/currency/enlisted_prem.svg:{0}:{0}:K"
}

let premiumBlockText = {
  rendObj = ROBJ_TEXTAREA
  parSpacing = hdpx(6)
  behavior = Behaviors.TextArea
  text = loc("premium/widget")
}.__update(sub_txt)


let mkPromoWidget = @(blockStyle, blockText, openWnd) @(srcWindow, srcComponent = null, override = {}) {
  children = [
    watchElemState(@(sf){
      rendObj = ROBJ_BOX
      margin = [0, 0, 0, blockStyle.iconSize / 2]
      padding = [hdpx(5), hdpx(10), hdpx(5), hdpx(25)]
      size = [SIZE_TO_CONTENT, hdpx(70)]
      valign = ALIGN_CENTER
      borderWidth = [hdpx(1), 0]
      borderColor = blockStyle.borderColor
      flow = FLOW_HORIZONTAL
      behavior = Behaviors.Button
      onClick = @() openWnd(srcWindow, srcComponent)
      fillColor = sf & S_HOVER ? Color(0, 0, 0, 210) : null
      children = [
        blockText
        faComp("chevron-right", {
          fontSize = hdpx(30)
          vplace = ALIGN_CENTER
          margin = [0, 0, 0, hdpx(20)]
        })
      ]
    })
    {
      rendObj = ROBJ_IMAGE
      image = Picture(blockStyle.iconPath.subst(blockStyle.iconSize.tointeger()))
      vplace = ALIGN_CENTER
    }
  ]
}.__update(override)

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