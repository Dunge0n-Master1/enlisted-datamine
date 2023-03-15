from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { PrimaryFlat } = require("%ui/components/textButton.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { bigPadding, lockedSquadBgColor, activeTxtColor, defTxtColor, titleTxtColor,
  smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let viewItemScene = require("viewItemScene.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { getItemName, getItemDesc, getItemTypeName
} = require("%enlSqGlob/ui/itemsInfo.nut")
let { campaignName, btnSizeSmall, receivedCommon, receivedFreemium, weapInfoBtn, rewardToScroll
} = require("campaignPromoPkg.nut")
let mkBuyArmyLevel = require("%enlist/soldiers/mkBuyArmyLevel.nut")
let { animChildren, glareAnimation } = require("%enlSqGlob/ui/glareAnimation.nut")
let { CAMPAIGN_NONE, isPurchaseableCampaign, isCampaignBought, campaignConfigGroup,
  campPresentation
} = require("%enlist/campaigns/campaignConfig.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")


let function freemiumPromoLink() {
  let { color = null } = campPresentation.value
  return {
    rendObj = ROBJ_FRAME
    watch = campPresentation
    hplace = ALIGN_CENTER
    color
    borderWidth = [0, 0, smallPadding, 0]
    padding = [bigPadding, 0]
    behavior = Behaviors.Button
    onClick = @() freemiumWnd()
    pos = [0, -hdpx(50)]
    children = {
      rendObj = ROBJ_TEXT
      text = loc("squads/unlockFreemium")
      color = titleTxtColor
    }
  }
}

let horBottomGradient = {
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_BOTTOM
  size = [flex(), ph(40)]
  color = Color(0,0,0)
  image = Picture("!ui/uiskin/R_BG_gradient_hor.svg:{4}:{300}:K?Ac")
}

let mkUnlockInfo = @(t) t == null ? null : {
  rendObj = ROBJ_SOLID
  size = [SIZE_TO_CONTENT, btnSizeSmall[1]]
  minWidth = btnSizeSmall[0]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  color = lockedSquadBgColor
  children = txt({
    text = t
    color = activeTxtColor
  }.__update(body_txt))
}

let function mkUnlockDescription(itemTpl) {
  let desc = getItemDesc(itemTpl)
  if (desc == "")
    return { size = flex() }
  return {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [pw(63), SIZE_TO_CONTENT]
    vplace = ALIGN_TOP
    color = defTxtColor
    valign = ALIGN_CENTER
    padding = [0, bigPadding * 2]
    text = desc
  }
}

let unlockLocTxt = loc("squads/receive")

let function mkUnlockBlock(unlockInfo) {
  if (unlockInfo == null)
    return null

  return function() {
    let children = []
    local { unlockCb = null, isNextToBuyExp = false, unlockText = null,
      campaignGroup = CAMPAIGN_NONE } = unlockInfo
    if (isNextToBuyExp)
      children.append(mkBuyArmyLevel(unlockInfo.lvlToBuy, unlockInfo.cost, unlockInfo.costFull))
    else if (unlockCb != null)
      children.append(PrimaryFlat(unlockLocTxt, unlockCb, {
        minWidth = btnSizeSmall[0]
        size = [SIZE_TO_CONTENT, btnSizeSmall[1]]
        margin = 0
        addChild = animChildren(glareAnimation())
        hotkeys = [["^J:X", { action = unlockCb, description = unlockLocTxt }]]
      }))
    else if (unlockText != null)
      children.append(mkUnlockInfo(unlockText))
    if (campaignGroup != CAMPAIGN_NONE && isPurchaseableCampaign.value
        && !isCampaignBought.value)
      children.insert(0, freemiumPromoLink)

    return {
      watch = [isPurchaseableCampaign, isCampaignBought]
      size = [SIZE_TO_CONTENT, btnSizeSmall[1]]
      minWidth = btnSizeSmall[0]
      padding = bigPadding
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_RIGHT
      pos = [0, btnSizeSmall[1] / 2]
      children
    }
  }
}

let mkBgImg = @(img, saturate) {
  rendObj = ROBJ_IMAGE
  size = flex()
  keepAspect = KEEP_ASPECT_FIT
  imageValign = ALIGN_TOP
  image = Picture(img)
  picSaturate = saturate
  children = horBottomGradient
}

let mkBackWithImage = @(img, isLocked) {
  rendObj = ROBJ_SOLID
  size = [pw(100), ph(100)]
  color = Color(0,0,0)
  valign = ALIGN_TOP
  children = img != null
    ? mkBgImg(img, isLocked ? 0.3 : 1)
    : null
}

let itemCardBottom = @(item, unlockInfo){
  flow = FLOW_VERTICAL
  size = [flex(), ph(66)]
  maxHeight = hdpx(400)
  valign = ALIGN_TOP
  vplace = ALIGN_BOTTOM
  padding = bigPadding
  gap = bigPadding
  children = [
    campaignName({
      nameLocId = getItemTypeName(item)
      titleLocId = getItemName(item)
      hasReceived = unlockInfo == null
      itemType = item.itemtype
      itemSubType = item?.itemsubtype
      campaignGroup = unlockInfo?.campaignGroup ?? CAMPAIGN_NONE
    })
    {
      size = flex()
      children = [
        mkUnlockDescription(item)
        mkUnlockBlock(unlockInfo)
      ]
    }
  ]
}

let mkItemPromo = kwarg(function(armyId, itemTpl, presentation, unlockInfo) {
  let item = findItemTemplate(allItemTemplates, armyId, itemTpl)
  if (item == null)
    return null

  let itemToView = mkShopItem(itemTpl, item, armyId)

  return watchElemState(@(sf) {
    watch = campaignConfigGroup
    size = flex()
    behavior = Behaviors.Button
    onClick = function(){
      rewardToScroll(unlockInfo.unlockUid)
      viewItemScene(itemToView)
    }
    gap = bigPadding
    children = [
      mkBackWithImage(presentation?.image, unlockInfo != null)
      {
        flow = FLOW_VERTICAL
        size = flex()
        children = [
          {
            size = flex()
            halign = ALIGN_RIGHT
            children = [
              unlockInfo != null ? null
                : campaignConfigGroup.value != CAMPAIGN_NONE ? receivedFreemium(campaignConfigGroup.value)
                : receivedCommon
              weapInfoBtn(sf)
            ]
          }
          itemCardBottom(item, unlockInfo)
        ]
      }
    ]
  })
})

return {
  mkItemPromo
  freemiumPromoLink
}
