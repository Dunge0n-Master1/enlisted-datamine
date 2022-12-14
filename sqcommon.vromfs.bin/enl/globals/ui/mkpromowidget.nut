from "%enlSqGlob/ui_library.nut" import *

let { accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let faComp = require("%ui/components/faComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let { needFreemiumStatus, campPresentation } = require("%enlist/campaigns/campaignConfig.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { unlockCampaignPromo } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")


let freemiumBlockStyle = @(config) {
  borderColor = config?.color
  iconSize = hdpx(42)
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
  borderColor = accentTitleTxtColor
  iconSize = hdpx(36)
  iconPath = "!ui/uiskin/currency/enlisted_prem.svg:{0}:{0}:K"
}

let premiumBlockText = @(_config) {
  rendObj = ROBJ_TEXTAREA
  parSpacing = hdpx(6)
  behavior = Behaviors.TextArea
  text = loc("premium/widget")
}.__update(sub_txt)


let mkPromoWidget = @(fnStyle, fnText, openWnd) @(srcWindow, srcComponent = null, override = {})
  function() {
    let { iconSize = 0, borderColor = null, iconPath = "" } = fnStyle(campPresentation.value)
    return {
      children = [
        watchElemState(@(sf) {
          watch = campPresentation
          rendObj = ROBJ_BOX
          margin = [0, 0, 0, iconSize / 2]
          padding = [hdpx(5), hdpx(10), hdpx(5), hdpx(25)]
          size = [SIZE_TO_CONTENT, hdpx(70)]
          valign = ALIGN_CENTER
          borderWidth = [hdpx(1), 0]
          borderColor
          flow = FLOW_HORIZONTAL
          behavior = Behaviors.Button
          onClick = @() openWnd(srcWindow, srcComponent)
          fillColor = sf & S_HOVER ? Color(0, 0, 0, 210) : null
          children = [
            fnText(campPresentation.value)
            faComp("chevron-right", {
              fontSize = hdpx(30)
              vplace = ALIGN_CENTER
              margin = [0, 0, 0, hdpx(20)]
            })
          ]
        })
        {
          rendObj = ROBJ_IMAGE
          image = Picture(iconPath.subst(iconSize.tointeger()))
          vplace = ALIGN_CENTER
        }
      ]
    }.__update(override)
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