from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { PrimaryFlat } = require("%ui/components/textButton.nut")

let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")

let textarea = @(override) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
}.__update(body_txt, override)

let function mkUnlockBtn(armyId) {
  let sItem = Computed(function() {
    let campaign = gameProfile.value?.campaignByArmyId[armyId]
    let unlockList = lockedProgressCampaigns.value?[campaign]
    return shopItems.value?[unlockList?.findvalue(@(id) id in shopItems.value)]
  })
  return function() {
    let res = { watch = sItem }
    if (sItem.value == null)
      return res
    return res.__update({
      children = PrimaryFlat(loc("btn/participate"),
        @() buyShopItem({ shopItem = sItem.value }),
        { hotkeys = [["^J:X"]] })
    })
  }
}

let mkCampaignProgressLock = @(armyId, onFinish) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    textarea({ text = loc("campaign/locked") })
    textarea({ text = loc("campaign/lockedProgress/desc"), color = defTxtColor }.__update(sub_txt))
    mkUnlockBtn(armyId)
  ]

  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.8, play = true,
      easing = InOutCubic, onFinish }
  ]
}

return mkCampaignProgressLock