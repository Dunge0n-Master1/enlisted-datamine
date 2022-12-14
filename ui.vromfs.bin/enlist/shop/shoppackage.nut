from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontSmall, fontMedium, fontXXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, panelBgColor, hoverBgColor,
  activeBgColor, discountBgColor, darkTxtColor, colFull, colPart, columnGap
} = require("%enlSqGlob/ui/designConst.nut")
let { mkShopItemPrice } = require("shopPricePackage.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")


let lineHeight = (columnGap / 3).tointeger()
let itemIconSize = colPart(0.5)
let groupSlotSize = [colFull(5), colPart(1)]
let baseSlotSize = [colFull(6), colFull(3.4)]

let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let darkTxtStyle = { color = darkTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let offerTxtStyle = { color = titleTxtColor }.__update(fontSmall)
let discountTxtStyle = { color = darkTxtColor }.__update(fontXXLarge)

let shopGroupLineWidth = (columnGap * 0.7).tointeger()


let lockIcon = faComp("lock", { fontSize = hdpx(20), color = titleTxtColor })


let mkShopGroupPrefix = @(isSelected) {
  size = [shopGroupLineWidth * 2, flex()]
  children = !isSelected ? null
    : {
        size = [shopGroupLineWidth, flex()]
        rendObj = ROBJ_SOLID
        color = titleTxtColor
      }
}

let mkShopGroup = @(groupId, isSelected, onClick)
  watchElemState(@(sf) {
    size = groupSlotSize
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    children = [
      mkShopGroupPrefix(isSelected)
      {
        size = [pw(60), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc($"shopGroup/{groupId}"))
      }.__update(isSelected || (sf & S_HOVER) != 0 ? titleTxtStyle : defTxtStyle)
    ]
  })


let mkShopItemImg = @(img, sf, override = {}) (img ?? "") == "" ? null
  : {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture(img)
      imageHalign = ALIGN_CENTER
      imageValign = ALIGN_TOP
      keepAspect = KEEP_ASPECT_FILL
      transform = { scale = sf & S_HOVER ? [1.1, 1.1] : [1, 1] }
      transitions = [{ prop = AnimProp.scale, duration = 0.7, easing = InOutCubic }]
    }.__update(override)

let mkHoverBlock = @(hasInfoBtn) {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(hasInfoBtn ? "btn/view" : "btn/buy"))
    }.__update(titleTxtStyle)
    faComp("angle-right", {
      fontSize = hdpx(32)
      hplace = ALIGN_RIGHT
      transform = {}
      animations = [
        { prop = AnimProp.translate, from = [-columnGap,0], to = [0,0],
          duration = 0.5, play = true, easing = OutQuart }
        { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.5,
          playFadeOut = true }
      ]
    })
  ]
}

let mkDiscount = @(discount) discount <= 0 ? null
  : {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = $"-{discount}%"
    }.__update(discountTxtStyle)

let mkSpecOfferInfo = @(endTime) {
  size = [SIZE_TO_CONTENT, colPart(1)]
  flow = FLOW_VERTICAL
  pos = [0, -colPart(1)]
  padding = [0, columnGap]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = activeBgColor
  children = [
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("specialOfferShort"))
    }.__update(offerTxtStyle)
    mkCountdownTimer({ timestamp = endTime, color = titleTxtColor })
  ]
}

let mkSpecOfferDiscount = @(offer) {
  size = [SIZE_TO_CONTENT, flex()]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_BOX
  borderWidth = 1
  borderColor = 0xFF000000
  children = [
    mkDiscount(offer.discountInPercent).__update({ hplace = ALIGN_CENTER })
    mkSpecOfferInfo(offer.endTime)
  ]
}

let function mkShopItemName(nameLocId, discount, offer, sf, icon, hasInfoBtn) {
  let titleList = loc(nameLocId).split("\r\n")
  let hasDiscount = discount > 0
  return {
    size = [flex(), colPart(1)]
    flow = FLOW_VERTICAL
    rendObj = ROBJ_SOLID
    color = sf & S_HOVER ? hoverBgColor
      : hasDiscount ? discountBgColor
      : panelBgColor
    children = [
      {
        size = flex()
        padding = [0, columnGap]
        valign = ALIGN_CENTER
        children = sf & S_HOVER
          ? mkHoverBlock(hasInfoBtn)
          : {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = columnGap
              valign = ALIGN_CENTER
              children = [
                icon
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  maxWidth = pw(75)
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  text = utf8ToUpper(titleList[0])
                }.__update(hasDiscount ? darkTxtStyle : defTxtStyle)
                offer != null ? mkSpecOfferDiscount(offer) : mkDiscount(discount)
              ]
            }
      }
      {
        size = [flex(), lineHeight]
        rendObj = ROBJ_SOLID
        color = activeBgColor
        transform = { scale = sf & S_HOVER ? [1, 1] : [1, 0], pivot = [0, 1] }
        transitions = [{ prop = AnimProp.scale, duration = 0.5, easing = OutQuintic }]
      }
    ]
  }
}

let function mkShopItemInfo(sItem, offer, sf, icon, hasInfoBtn, lockObject) {
  let { nameLocId = "", discountInPercent = 0 } = sItem
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = columnGap
    vplace = ALIGN_BOTTOM
    children = [
      mkShopItemPrice(sItem, lockObject)
      mkShopItemName(nameLocId, discountInPercent, offer, sf, icon, hasInfoBtn)
    ]
  }
}

let mkLockInfo = @(lockTxt) lockTxt == "" ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = columnGap
      valign = ALIGN_CENTER
      children = [
        lockIcon
        {
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(lockTxt)
        }.__update(titleTxtStyle)
      ]
    }.__update(titleTxtStyle)

let function hasShopItemInfo(sItem, armyId, content) {
  let { squads = [] } = sItem
  let { items = {} } = content
  let squad = squads.filter(@(s) s.armyId == armyId)?[0]
  return squad != null || items.len() > 0
}

let function extractItems(content) {
  let res = {}
  foreach (tmpl, _ in content?.items ?? {})
    res[trimUpgradeSuffix(tmpl)] <- true
  return res.keys()
}

let function extractClasses(content) {
  let res = {}
  foreach (sClass in content?.soldierClasses ?? {})
    res[getClassCfg(sClass).kind] <- true
  return res.keys()
}

let function mkShopItem(armyId, sItem, offer, content, templates, lockTxt, onClick, onHover) {
  let hasInfoBtn = hasShopItemInfo(sItem, armyId, content)
  let picSaturate = lockTxt == "" ? 1 : 0.1

  local icon
  let itemsList = extractItems(content) ?? []
  if (itemsList.len() == 1) {
    let { itemtype = null, itemsubtype = null } = templates?[armyId][itemsList[0]]
    icon = itemTypeIcon(itemtype, itemsubtype, {
      size = array(2, itemIconSize)
      color = titleTxtColor
    })
  }
  let sClasses = extractClasses(content) ?? []
  if (sClasses.len() == 1)
    icon = kindIcon(sClasses[0], itemIconSize, null, titleTxtColor)

  return watchElemState(@(sf) {
    size = baseSlotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior = onClick == null ? null : Behaviors.Button
    onClick
    onHover
    children = {
      size = flex()
      children = [
        mkShopItemImg(sItem?.image, sf, { picSaturate })
        mkShopItemInfo(sItem, offer, sf, icon, hasInfoBtn, mkLockInfo(lockTxt))
      ]
    }
  })
}

return {
  mkShopGroup
  mkShopItem
}
