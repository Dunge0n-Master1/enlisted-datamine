from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, bigPadding, blurBgColor, blurBgFillColor, bigGap
} = require("%enlSqGlob/ui/viewConst.nut")
let { textarea } = require("%enlist/components/text.nut")
let { PrimaryFlat, FAButton } = require("%ui/components/textButton.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")

let { lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")


let mkUnlockBtn = @(unlockList) function() {
  let res = { watch = shopItems }
  let sItem = shopItems.value?[unlockList.findvalue(@(id) id in shopItems.value)]
  if (sItem == null)
    return res
  return res.__update({
    children = PrimaryFlat(loc("btn/participate"),
      @() buyShopItem({ shopItem = sItem }),
      { hotkeys = [["^J:X"]] })
  })
}

let mkCampaignLockInfo = @(unlockList) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = bigPadding

  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    textarea(loc("campaign/locked")).__update({ halign = ALIGN_CENTER }, fontBody)
    textarea(loc("campaign/lockedProgress/desc")).__update({ halign = ALIGN_CENTER, color = defTxtColor }, fontBody)
    mkUnlockBtn(unlockList)
  ]
}

let mkLockByCampaignProgress = @(content, rootOverride = {}) function() {
  let unlockList = lockedProgressCampaigns.value?[curCampaign.value]
  return {
    watch = [curCampaign, lockedProgressCampaigns]
    size = flex()
    children = unlockList == null ? content : mkCampaignLockInfo(unlockList)
  }.__update(rootOverride)
}

let function unlockCampaignPromo(override = {}) {
  let sItem = Computed(function() {
    let unlockList = lockedProgressCampaigns.value?[curCampaign.value]
    return shopItems.value?[unlockList?.findvalue(@(id) id in shopItems.value)]
  })
  return function() {
    let res = { watch = sItem }
    if (sItem.value == null)
      return res
    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      gap = bigGap
      flow = FLOW_HORIZONTAL
      children = [
        premiumImage(hdpx(35))
        textarea(loc("campaign/lockedProgress/desc/short")).__update({
          size = [flex(), SIZE_TO_CONTENT]
          color = defTxtColor
        }, fontSub)
        FAButton("shopping-cart",
          @() buyShopItem({ shopItem = sItem.value }),
          { borderWidth = 0, borderRadius = 0 })
      ]
    }).__update(override)
  }
}

let mkUnlockCampaignBlock = @(unlockList) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    {
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      padding = bigPadding
      size = [flex(), SIZE_TO_CONTENT]
      gap = hdpx(10)
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text = loc("campaign/locked")
        }.__update(fontBody)
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          color = defTxtColor
          size = [flex(), SIZE_TO_CONTENT]
          text = loc("campaign/lockedProgress/descSmall")
        }.__update(fontSub)
      ]
    }
    mkUnlockBtn(unlockList)
  ]
}

return {
  mkLockByCampaignProgress
  unlockCampaignPromo
  mkUnlockCampaignBlock
}