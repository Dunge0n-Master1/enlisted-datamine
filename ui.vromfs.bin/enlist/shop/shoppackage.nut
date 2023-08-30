from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let faComp = require("%ui/components/faComp.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let mkGlare = require("%enlist/components/mkGlareAnim.nut")
let getEquipClasses = require("%enlist/soldiers/model/equipClassSchemes.nut")
let allowedVehicles = require("%enlist/vehicles/allowedVehicles.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontTiny, fontSub, fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, panelBgColor, midPadding, darkTxtColor, largePadding,
  leftAppearanceAnim, defItemBlur, defSlotBgColor, hoverSlotBgColor, attentionTxtColor,
  accentColor, smallPadding, highlightLineBottom, brightAccentColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkShopItemPrice } = require("shopPricePackage.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { levelBlock, kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkFireParticles, mkAshes, mkSparks } = require("%enlist/components/mkFireParticles.nut")
let { mkPremiumSquadXpImage } = require("%enlist/debriefing/components/mkXpImage.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { shopItemContentCtor } = require("%enlist/shop/armyShopState.nut")
let { curArmyReserve, curArmyReserveCapacity } = require("%enlist/soldiers/model/reserve.nut")
let { mkCounter } = require("%enlist/shop/mkCounter.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let { getClassCfg, getKindCfg, soldierKindsList } = require("%enlSqGlob/ui/soldierClasses.nut")
let { armySquadsById, lockedArmySquadsById } = require("%enlist/soldiers/model/state.nut")
let { curArmySquadsUnlocks } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { mkSquadCard } = require("%enlSqGlob/ui/squadsUiComps.nut")


let itemIconSize = hdpxi(32)
let lowerSlotSize = [hdpxi(370), hdpxi(308)]
let soldierSlotSize = [hdpx(280), hdpx(370)]
let baseSlotSize = [hdpxi(370), hdpxi(370)]
let promoSlotSize = [hdpxi(756), hdpxi(370)]
let btnSound = freeze({
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
})


let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let defFeaturedTxtStyle = { color = defTxtColor }.__update(fontHeading2)
let activeTxtStyle = { color = darkTxtColor }.__update(fontSub)
let titleTxtStyle = { color = titleTxtColor }.__update(fontSub)
let titleFeaturedTxtStyle = { color = titleTxtColor }.__update(fontHeading2)
let discountInfoStyle = { color = darkTxtColor }.__update(fontHeading2)
let discountDescStyle = { color = darkTxtColor }.__update(fontTiny)
let alertTxtStyle = { color = attentionTxtColor }.__update(fontSub)

let lockIcon = faComp("lock", { fontSize = hdpx(20), color = titleTxtColor })
let warnIcon = faComp("exclamation-triangle", { fontSize = hdpx(16), color = attentionTxtColor })

let infoBtnSize = hdpxi(30)
let hoveredInfoBtnSize = hdpxi(33)


let mkText = @(text, override = defTxtStyle) {
  rendObj = ROBJ_TEXT
  text
}.__update(override)

let bgColor = @(sf, isSelected) isSelected ? accentColor
  : sf & S_HOVER ? hoverSlotBgColor
  : defSlotBgColor


let mkBgParticles = @(effectSize) {
  children = [
    mkFireParticles(8, effectSize, mkAshes)
    mkFireParticles(2, effectSize, mkSparks)
  ]
}


let mkShopItemImg = @(img, sf = 0, override = {}) (img ?? "") == "" ? null
  : {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture(img)
      imageHalign = ALIGN_CENTER
      imageValign = ALIGN_TOP
      keepAspect = KEEP_ASPECT_FILL
      transform = { scale = sf & S_HOVER ? [1.1, 1.1] : [1, 1] }
      transitions = [{ prop = AnimProp.scale, duration = 0.3, easing = InOutCubic }]
    }.__update(override)


let mkDiscountRightTail = @(color) {
  size = [midPadding, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = color
  commands = [
    [VECTOR_COLOR, color],
    [VECTOR_POLY, 0, 0, 100, 100, 0, 100]
  ]
}

let mkDiscountLeftTail = @(color) {
  size = [midPadding, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = color
  commands = [
    [VECTOR_COLOR, color],
    [VECTOR_POLY, 100, 0, 100, 100, 0, 100]
  ]
}


let mkDiscountPolyCmds = @(color) [
  [VECTOR_COLOR, color],
  [VECTOR_POLY, 0,0, 100,0, 100, 100, 0, 100]
]

let mkDiscountBar = @(children, isTailOnLeft = true, color = brightAccentColor) {
  flow = FLOW_HORIZONTAL
  children = [
    isTailOnLeft ? mkDiscountLeftTail(color) : null
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      padding = [0, midPadding]
      valign = ALIGN_CENTER
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = color
      commands = mkDiscountPolyCmds(color)
      children
    }
    isTailOnLeft ? null : mkDiscountRightTail(color)
  ]
}


let function mkDiscount(sItem) {
  let discount = sItem?.discountInPercent ?? 0
  if (discount <= 0)
    return null

  let { hideDiscount = false, showSpecialOfferText = false } = sItem
  return mkDiscountBar([
      hideDiscount ? null : {
        rendObj = ROBJ_TEXT
        text = $"-{discount}%"
      }.__update(discountInfoStyle)
      {
        rendObj = ROBJ_TEXT
        text = loc(showSpecialOfferText ? "specialOfferShort" : "shop/discountTxt")
      }.__update(discountDescStyle)
    ])
}

let mkSpecOfferInfo = @(discount, endTime) mkDiscountBar([
  {
    rendObj = ROBJ_TEXT
    text = $"-{discount}%"
  }.__update(discountInfoStyle)
  {
    rendObj = ROBJ_TEXT
    text = loc("shop/discountTxt")
  }.__update(discountDescStyle)
  mkCountdownTimer({ timestamp = endTime, color = darkTxtColor })
])

let function mkTimeAvailable(showIntervalTs) {
  let endTime = showIntervalTs?[1] ?? 0
  return endTime < serverTime.value ? null
    : mkCountdownTimer({ timestamp = endTime, color = attentionTxtColor })
}


let mkShopItemName = @(nameLocId, sf, icon, showIntervalTs) {
  size = [flex(), hdpx(86)]
  rendObj = ROBJ_WORLD_BLUR
  fillColor = bgColor(sf, false)
  color = defItemBlur
  children = {
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = largePadding
    padding = largePadding
    valign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      icon
      {
        size = [flex(), SIZE_TO_CONTENT]
        maxWidth = pw(75)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc(nameLocId))
      }.__update(sf & S_HOVER ? activeTxtStyle : defTxtStyle)
      mkTimeAvailable(showIntervalTs)
    ]
  }
}


let function mkShopPremIcon(sItem) {
  let { squads = [] } = sItem
  let squad = squads?[0]
  if (squad == null)
    return null

  let { armyId } = squad
  return mkPremiumSquadXpImage(hdpxi(32), armyId)
}

let function mkShopItemInfo(sItem, offer, sf, icon, lockObject, unseenIcon = null) {
  let { nameLocId = "", showIntervalTs = [], isPriceHidden = false, offerContainer = "" } = sItem
  let isContainer = offerContainer != ""
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      offer == null
        ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      isPriceHidden || isContainer ? null : {
        children = [
          mkShopItemPrice(sItem, lockObject)
          mkGlare({
            nestWidth = hdpx(248)
            glareWidth = hdpx(124)
            glareDuration = 0.7
            hasMask = true
          })
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          mkShopItemName(nameLocId, sf, icon, showIntervalTs)
          unseenIcon
          highlightLineBottom
        ]
      }
    ]
  }
}


let mkFeaturedName = @(nameLocId, sf, icon) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = largePadding
  padding = largePadding
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    icon
    {
      size = [flex(), SIZE_TO_CONTENT]
      maxWidth = hdpx(600)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = utf8ToUpper(loc(nameLocId).split("\r\n")[0])
    }.__update(sf & S_HOVER ? titleFeaturedTxtStyle : defFeaturedTxtStyle)
  ]
}


let function mkShopFeaturedInfo(sItem, offer, sf, icon, lockObject) {
  let { nameLocId = "", showIntervalTs = [] } = sItem
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      offer == null
        ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      {
        children = [
          mkShopItemPrice(sItem, lockObject)
          mkGlare({
            nestWidth = hdpx(248)
            glareWidth = hdpx(124)
            glareDuration = 0.7
            hasMask = true
          })
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        margin = [0, 0, largePadding, 0]
        children = [
          mkFeaturedName(nameLocId, sf, icon)
          {
            margin = [0, largePadding]
            hplace = ALIGN_RIGHT
            children = mkTimeAvailable(showIntervalTs)
          }
        ]
      }
    ]
  }
}


let mkLockInfo = @(lockTxt) lockTxt == "" ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = largePadding
      valign = ALIGN_CENTER
      children = [
        lockIcon
        {
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(lockTxt)
        }.__update(titleTxtStyle)
      ]
    }.__update(titleTxtStyle)


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

let function mkShopIcon(armyId, content, templates) {
  let itemsList = extractItems(content) ?? []
  if (itemsList.len() == 1) {
    let { itemtype = null, itemsubtype = null } = templates?[armyId][itemsList[0]]
    return itemTypeIcon(itemtype, itemsubtype, {
      size = array(2, itemIconSize)
      color = titleTxtColor
    })
  }

  let sClasses = extractClasses(content) ?? []
  if (sClasses.len() == 1)
    return kindIcon(sClasses[0], itemIconSize, null, titleTxtColor)

  return null
}


let mkAlertObject = @(alertText) {
  flow = FLOW_HORIZONTAL
  margin = smallPadding
  gap = smallPadding
  children = [
    warnIcon
    {
      rendObj = ROBJ_TEXT
      text = alertText
    }.__update(alertTxtStyle)
  ]
}

let infoIcon = {
  rendObj = ROBJ_IMAGE
  size = array(2, infoBtnSize)
  image = Picture($"ui/skin#info/info_icon.svg:{infoBtnSize}:{infoBtnSize}:K")
}

let infoIconHover = {
  rendObj = ROBJ_IMAGE
  size = array(2, hoveredInfoBtnSize)
  image = Picture($"ui/skin#info/info_icon.svg:{hoveredInfoBtnSize}:{hoveredInfoBtnSize}:K")
}

let mkInfoBtn = @(onClick) onClick == null ? null : watchElemState(function(sf) {
  return {
    size = [hoveredInfoBtnSize, hoveredInfoBtnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    margin = fsh(1)
    behavior = Behaviors.Button
    sound = btnSound
    onClick
    children = sf & S_HOVER ? infoIconHover : infoIcon
  }
})

let mkShopItem = @(slotSize) function(idx, armyId, sItem, offer, content, templates, lockTxt,
  onClick = null, onHover = null, alertText = null, infoCb = null, unseenIcon = null
) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let alertObject = alertText == null ? null : mkAlertObject(alertText)
  let xmbNode = onClick == null ? null : XmbNode()
  let behavior = onClick == null ? null : Behaviors.Button
  let sound = onClick == null ? null : btnSound
  return watchElemState(@(sf) {
    key = sItem.guid
    size = slotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior
    xmbNode
    onClick
    sound
    hotkeys = (sf & S_HOVER) && infoCb != null
      ? [["^J:Y", { description = loc("info"), action = infoCb }]]
      : null
    onHover
    children = {
      size = flex()
      children = [
        {
          size = flex()
          margin = [0,0, hdpx(86),0]
          children = [
            mkShopItemImg(sItem?.image, sf, { picSaturate })
            mkBgParticles([slotSize[0], slotSize[1] - hdpx(86)])
          ]
        }
        mkShopItemInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt), unseenIcon)
        mkShopPremIcon(sItem)
        alertObject
        mkInfoBtn(infoCb)
      ]
    }
  }.__update(leftAppearanceAnim(idx * 0.05 + 0.1)))
}

let mkBaseShopItem = mkShopItem(baseSlotSize)
let mkLowerShopItem = mkShopItem(lowerSlotSize)
let mkSoldierShopItem = mkShopItem(soldierSlotSize)

let function mkShopFeatured(armyId, sItem, offer, content, templates,
    lockTxt, onClick, onHover, infoCb) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let xmbNode = onClick == null ? null : XmbNode()
  let behavior = onClick == null ? null : Behaviors.Button
  let sound = onClick == null ? null : btnSound
  return watchElemState(@(sf) {
    key = $"featured_{sItem.guid}"
    size = promoSlotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior
    xmbNode
    onClick
    sound
    onHover
    hotkeys = (sf & S_HOVER) && infoCb != null
      ? [["^J:Y", { description = loc("info"), action = infoCb }]]
      : null
    children = {
      size = flex()
      children = [
        mkShopItemImg(sItem?.image, sf, { picSaturate })
        mkBgParticles(promoSlotSize)
        mkShopFeaturedInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt))
        infoCb ? mkInfoBtn(infoCb) : null
      ]
    }
  }.__update(leftAppearanceAnim(0)))
}


let function getMaxCount(shopItem) {
  let { limit = 0, premiumDays = 0, squads = [] } = shopItem
  let isSoldier = (shopItemContentCtor(shopItem)?.value.content.soldierClasses.len() ?? 0) > 0
  return limit > 0 ||  premiumDays > 0 || squads.len() > 0 ? 1
    : isSoldier ? min(99, max(curArmyReserveCapacity.value - curArmyReserve.value.len(), 0))
    : 99
}

let function mkShopCounter(shopItem, countWatched) {
  let maxCount = getMaxCount(shopItem)
  return maxCount <= 1 || countWatched == null ? null
    : {
        size = [flex(), hdpx(86)]
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        rendObj = ROBJ_WORLD_BLUR
        fillColor = bgColor(0, false)
        color = defItemBlur
        children = mkCounter(maxCount, countWatched)
      }
}


let function getTierInterval(items, templates) {
  local minTier = -1
  local maxTier = -1
  foreach (tpl, _ in items ?? {}) {
    let { tier = 0 } = templates?[tpl]
    if (minTier < 0 || tier < minTier)
      minTier = tier
    if (maxTier < tier)
      maxTier = tier
  }
  return { minTier, maxTier }
}

let function mkShopItemInfoTier(minTier, maxTier, override = {}) {
  if (maxTier <= 0)
    return null

  let starsObj = maxTier == minTier
    ? levelBlock({ curLevel = maxTier + 1 })
    : {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        valign = ALIGN_CENTER
        children = [
          levelBlock({ curLevel = minTier + 1 })
          mkText("—")
          levelBlock({ curLevel = maxTier + 1 })
        ]
      }
  let starsTxt = maxTier <= minTier ? null
    : {
        size = [hdpxi(220), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("shop/upgradeLevel", { maxUpgrade = maxTier, minUpgrade = minTier })
        color = defTxtColor
      }.__update(fontSub, override)
  return {
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkText(utf8ToUpper(loc("itemLevel")))
      starsObj
      starsTxt
    ]
  }
}


let iconSize = hdpxi(36)
let iconGap = hdpxi(18)
let getKindIcon = memoize(@(img, sz) Picture("ui/skin#{0}:{1}:{1}:K".subst(img, sz.tointeger())))

let function mkCanUseInfo(itemtype, armyId, itemtmpl) {
  if (itemtype == "vehicle") {
    let vehicleSquadIds = (allowedVehicles.value?[armyId] ?? {})
      .filter(@(squad) squad?[itemtmpl]).keys()
    let squadsCount = vehicleSquadIds.len()
    return {
      flow = FLOW_VERTICAL
      gap = iconGap
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      children = [
        mkText(utf8ToUpper(loc("shop/squadsCanUse", { squadsCount })))
        @() {
          watch = [armySquadsById, lockedArmySquadsById, curArmySquadsUnlocks]
          flow = FLOW_HORIZONTAL
          gap = iconGap
          children = vehicleSquadIds.map(function(squadId) {
            local squad = armySquadsById.value?[armyId][squadId]
            local unlockLevel = 0
            if (!squad) {
              squad = lockedArmySquadsById.value?[armyId][squadId]
              unlockLevel = (curArmySquadsUnlocks.value ?? {})
                .findvalue(@(s) s.unlockId == squadId)?.level ?? 0
            }
            return mkSquadCard({
              idx = 0
              isSelected = Watched(false)
              unlockLevel
            }.__update(squad), KWARG_NON_STRICT)
          })
        }
      ]
    }
  }

  let kindsList = getEquipClasses(armyId, itemtmpl, itemtype)
    .reduce(function(tbl, sClass) {
      let { kind, isPremium = false, isEvent = false } = getClassCfg(sClass)
      if (!isPremium && !isEvent)
        tbl[kind] <- true
      return tbl
    }, {}).keys()

  let count = kindsList.len()
  if (count == 0)
    return null

  let isAccessible = count == soldierKindsList.len()
  let headerTxt = loc(isAccessible ? "shop/allCanUse" : "shop/someCanUse", { classes = "" })
  let classesListObj = isAccessible ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = iconGap
        children = kindsList.map(function(sKind) {
          let cfg = getKindCfg(sKind)
          return {
            flow = FLOW_VERTICAL
            gap = smallPadding
            halign = ALIGN_CENTER
            children = [
              {
                rendObj = ROBJ_IMAGE
                size = [iconSize, iconSize]
                image = getKindIcon(cfg.icon, iconSize)
              }
              mkText(loc(cfg.locId))
            ]
          }
        })
      }
  return {
    flow = FLOW_VERTICAL
    gap = iconGap
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    children = [
      mkText(utf8ToUpper(headerTxt))
      classesListObj
    ]
  }
}

let mkCanUseShopItemInfo = @(crateContent) function() {
  let res = { watch = [allItemTemplates, crateContent] }
  let itemsList = extractItems(crateContent.value?.content) ?? []
  if (itemsList.len() != 1)
    return res

  let { armyId = null } = crateContent.value
  let templates = allItemTemplates.value?[armyId]
  let itemtmpl = itemsList[0]
  let { itemtype = null } = templates?[itemtmpl]
  return res.__update(mkCanUseInfo(itemtype, armyId, itemtmpl) ?? {}, {halign = ALIGN_CENTER})
}


let msgBoxViewSize = [hdpxi(500), hdpxi(340)]
let function mkShopMsgBoxView(shopItem, crateContent, countWatched, showDiscount = false) {
  if (crateContent == null)
    return null

  let {
    nameLocId = "", showIntervalTs = [], isPriceHidden = false,
    image = null, discountInPercent = 0
  } = shopItem
  let discountVal = showDiscount ? discountInPercent : 0
  return function() {
    let { armyId = null, content = null } = crateContent.value
    let templates = allItemTemplates.value
    let { minTier, maxTier } = getTierInterval(content?.items, templates?[armyId])
    let icon = mkShopIcon(armyId, content, templates)
    return {
      watch = [crateContent, allItemTemplates]
      valign = ALIGN_CENTER
      halign = ALIGN_RIGHT
      children = [
        {
          flow = FLOW_VERTICAL
          gap = largePadding
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = [
                icon
                mkText(utf8ToUpper(loc(nameLocId)), titleTxtStyle)
              ]
            }
            {
              size = msgBoxViewSize
              children = [
                mkShopItemImg(image)
                mkBgParticles(msgBoxViewSize)
                mkShopPremIcon(shopItem)
                {
                  margin = smallPadding
                  children = mkTimeAvailable(showIntervalTs)
                }
                {
                  size = flex()
                  flow = FLOW_VERTICAL
                  gap = midPadding
                  valign = ALIGN_BOTTOM
                  children = [
                    {
                      size = [flex(), SIZE_TO_CONTENT]
                      children = [
                        mkDiscountWidget(discountVal, { pos = [hdpx(10), 0] })
                        isPriceHidden ? null : {
                          children = [
                            mkShopItemPrice(shopItem)
                            mkGlare({
                              nestWidth = hdpx(248)
                              glareWidth = hdpx(124)
                              glareDuration = 0.7
                              hasMask = true
                            })
                          ]
                        }
                      ]
                    }
                    mkShopCounter(shopItem, countWatched)
                  ]
                }
              ]
            }
          ]
        }
        {
          size = [hdpxi(220), SIZE_TO_CONTENT]
          pos = [hdpxi(250), 0]
          children = mkShopItemInfoTier(minTier, maxTier)
        }
      ]
    }
  }
}


return {
  mkBaseShopItem
  mkLowerShopItem
  mkSoldierShopItem
  mkDiscountBar
  mkShopFeatured
  lowerSlotSize
  mkAlertObject
  mkShopMsgBoxView
  mkCanUseShopItemInfo
  getTierInterval
}
