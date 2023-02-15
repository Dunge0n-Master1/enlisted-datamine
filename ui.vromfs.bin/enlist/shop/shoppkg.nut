from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let msgbox = require("%ui/components/msgbox.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { mkShopItemPrice } = require("mkShopItemPrice.nut")
let spinner = require("%ui/components/spinner.nut")({ opacity = 0.7 })
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { getClassCfg, getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { scrollToCampaignLvl, curArmySquadsUnlocks
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let getEquipClasses = require("%enlist/soldiers/model/equipClassSchemes.nut")
let { defBgColor, bigPadding, smallPadding, defTxtColor, warningColor, idleBgColor,
  soldierLvlColor, disabledTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { TextHover, TextNormal, textMargin
} = require("%ui/components/textButton.style.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { armySquadsById, lockedArmySquadsById } = require("%enlist/soldiers/model/state.nut")
let allowedVehicles = require("%enlist/vehicles/allowedVehicles.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { mkCounter } = require("%enlist/shop/mkCounter.nut")
let { shopItemContentCtor } = require("%enlist/shop/armyShopState.nut")
let { curArmyReserve, curArmyReserveCapacity } = require("%enlist/soldiers/model/reserve.nut")
let { mkIconBar } = require("%enlSqGlob/ui/itemTier.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { mkRightHeaderFlag, primeFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { mkBpIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")

const MAX_CLASSES_USAGE = 4
let PRICE_HEIGHT = hdpx(48)

const DISCOUNT_WARN_TIME = 600

let cardPreviewSize = [fsh(45), fsh(30)]
let cardSquadPreviewSize = [fsh(60), fsh(30)]

let mkPurchaseSpinner = @(shopItem, purchasingItem) @() {
  watch = purchasingItem
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = purchasingItem.value == shopItem ? spinner : null
}

let mkShopItemImg = @(img, override = {}) (img ?? "").len()  == 0 ? null
  : {
      rendObj = ROBJ_IMAGE
      size = flex()
      keepAspect = KEEP_ASPECT_FILL
      image = Picture(img)
    }.__update(override)

let mkShopItemVideo = @(uri) {
  size = flex()
  keepAspect = KEEP_ASPECT_FILL
  rendObj = ROBJ_MOVIE
  movie = uri
  behavior = Behaviors.Movie
}

let shopBottomLine = {
  rendObj = ROBJ_SOLID
  size = [flex(), PRICE_HEIGHT]
  color = Color(40,40,40,255)
  valign = ALIGN_CENTER
}

let lockIcon = faComp("lock", { fontSize = hdpx(20), color = defTxtColor })

let mkLevelLockLine = @(level) shopBottomLine.__merge({
  padding = [0, fsh(2)]
  children = [
    lockIcon
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_RIGHT
      color = defTxtColor
      text = loc("levelInfo", { level })
    }.__update(sub_txt)
  ]
})

let function mkShopItemPriceLine(shopItem, personalOffer = null) {
  let children = mkShopItemPrice(shopItem, personalOffer)
  return !children ? null : shopBottomLine.__merge({ children })
}

let itemHighlight = @(trigger){
  size = flex()
  rendObj = ROBJ_BOX
  borderWidth = hdpx(8)
  borderColor = 0xFFFFFF
  opacity = 0
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 1, trigger, easing = Blink }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 1, delay = 1, trigger, easing = Blink }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 1, delay = 2, trigger, easing = Blink }
  ]
}

let infoBtnSize = hdpxi(30)
let hoveredInfoBtnSize = hdpxi(33)

let mkInfoBtn = @(onClick) watchElemState(function(sf) {
  let size = sf & S_HOVER ? hoveredInfoBtnSize : infoBtnSize
  return {
    hplace = ALIGN_LEFT
    margin = fsh(1)
    behavior = Behaviors.Button
    onClick
    children = {
      rendObj = ROBJ_IMAGE
      size = array(2, size)
      image = Picture($"ui/skin#info/info_icon.svg:{size}:{size}:K")
    }
  }
})

let mkViewCrateBtn = @(crateContentWatch, onCrateViewCb)
  crateContentWatch == null || onCrateViewCb == null ? null
    : @() {
        watch = crateContentWatch
        hplace = ALIGN_LEFT
        children = (crateContentWatch.value?.content.items ?? {}).len() == 0 ? null
          : mkInfoBtn(onCrateViewCb)
      }

let function extractItems(crateContent) {
  let { items = {} } = crateContent?.value.content
  let res = {}
  foreach (tmpl, _ in items)
    res[trimUpgradeSuffix(tmpl)] <- true
  return res.keys()
}

let function extractClasses(crateContent) {
  let { soldierClasses = [] } = crateContent?.value.content
  let res = {}
  foreach (sClass in soldierClasses)
    res[getClassCfg(sClass).kind] <- true
  return res.keys()
}

let mkItemUsageKind = @(sKind) {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    kindIcon(sKind, hdpx(22))
    {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = loc(getKindCfg(sKind).locId)
    }.__update(sub_txt)
  ]
}

let mkForVehicleSquad = @(squad, unlockLevel) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    unlockLevel == 0 ? null : {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      valign = ALIGN_CENTER
      children = [
        faComp("lock", { fontSize = hdpx(20), color = warningColor })
        txt({
          text = loc("level/short", { level = unlockLevel })
          color = warningColor
        }.__update(body_txt))
      ]
    }
    mkSquadIcon(squad?.icon, { size = [hdpx(40), hdpx(40)], margin = smallPadding })
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      maxWidth = SIZE_TO_CONTENT
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = unlockLevel == 0 ? defTxtColor : warningColor
      text = loc(squad?.manageLocId ?? "")
    }.__update(body_txt)
  ]
}

let mkSquadUsageKind = function(squadId, armyId) {
  local squad = armySquadsById.value?[armyId][squadId]
  local unlockLevel = 0
  if (!squad){
    squad = lockedArmySquadsById.value?[armyId][squadId]
    unlockLevel = (curArmySquadsUnlocks.value ?? {})
      .findvalue(@(s) s.unlockId == squadId)?.level ?? 0
  }

  return !squad ? null : {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    padding = bigPadding
    color = defBgColor
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = mkForVehicleSquad(squad, unlockLevel)
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

let function mkClassCanUse(itemtype, armyId, itemtmpl) {
  if (itemtype == "vehicle"){
    let vehicleSquadIds = (allowedVehicles.value?[armyId] ?? {})
      .filter(@(squad) squad?[itemtmpl]).keys()
    let squadsCount = vehicleSquadIds.len()
    return squadsCount == 0 ? null : {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          size = [flex(), SIZE_TO_CONTENT]
          text = loc("shop/squadsCanUse", { squadsCount })
        }.__update(body_txt)
      ].extend(vehicleSquadIds.map(@(squadId) mkSquadUsageKind(squadId, armyId)))
    }
  }

  let kindsList = getEquipClasses(armyId, itemtmpl, itemtype)
    .reduce(function(tbl, sClass) {
      let { kind, isPremium = false, isEvent = false } = getClassCfg(sClass)
      if (!isPremium && !isEvent)
        tbl[kind] <- true
      return tbl
    }, {})
    .keys()
  let count = kindsList.len()
  if (count == 0)
    return null

  return count > MAX_CLASSES_USAGE
    ? {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        text = loc("shop/anyCanUse")
      }.__update(body_txt)
    : {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [flex(), SIZE_TO_CONTENT]
          text = loc("shop/someCanUse", { count })
        }.__update(body_txt)
      ].extend(kindsList.map(mkItemUsageKind))
    }
}


let mkShopItemInfoBlock = @(crateContent) function() {
  let res = { watch = [allItemTemplates, crateContent] }
  let itemsList = extractItems(crateContent) ?? []
  if (itemsList.len() != 1)
    return res

  let { armyId = null } = crateContent?.value
  let templates = allItemTemplates.value?[armyId]
  let itemtmpl = itemsList[0]
  let { itemtype = null } = templates?[itemtmpl]
  let { minTier, maxTier } = getTierInterval(crateContent?.value.content.items, templates)
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    padding = [smallPadding, 0]
    children = [
      maxTier <= 0 ? null
        : maxTier <= minTier ? null
        : {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            size = [flex(), SIZE_TO_CONTENT]
            text = loc("shop/upgradeLevel", { maxUpgrade = maxTier, minUpgrade = minTier })
          }
      mkClassCanUse(itemtype, armyId, itemtmpl)
    ]
  })
}

let mkTitle = @(text, minAmount, maxAmount, idx, isBundle) {
  flow = FLOW_HORIZONTAL
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text
    }.__update(idx == 0 ? body_txt : tiny_txt )
    idx > 0 || minAmount <= 1 || isBundle ? null : {
      rendObj = ROBJ_TEXT
      text = minAmount == maxAmount ? $"×{minAmount}" : $"×{minAmount}-{maxAmount}" // TODO use localization for multipliers
    }.__update(body_txt)
  ]
}

let function getMaxCount(shopItem) {
  let { limit = 0, premiumDays = 0, squads = [] } = shopItem
  let isSoldier = (shopItemContentCtor(shopItem)?.value.content.soldierClasses.len() ?? 0) > 0
  return limit > 0 ||  premiumDays > 0 || squads.len() > 0 ? 1
    : isSoldier ? min(99, max(curArmyReserveCapacity.value - curArmyReserve.value.len(), 0))
    : 99
}

// fast temporary solution
let function mkSeasonBpIcon(shopItem){
  let { offerGroup = null } = shopItem
  return  offerGroup != "weapon_battlepass_group" ? null
    : mkBpIcon()
}

let function mkShopItemTitle(
  shopItem, crateContent, itemTemplates, showDiscount, countWatched = null
) {
  let { armyId = null, content = {} } = crateContent?.value
  local shopIcon
  local seasonBpIcon = mkSeasonBpIcon(shopItem)
  let itemsList = extractItems(crateContent) ?? []
  if (itemsList.len() == 1) {
    let { itemtype = null, itemsubtype = null } = itemTemplates.value?[armyId][itemsList[0]]
    shopIcon = itemTypeIcon(itemtype, itemsubtype)
  }

  let soldierClasses = extractClasses(crateContent) ?? []
  if (soldierClasses.len() == 1)
    shopIcon = kindIcon(soldierClasses[0], hdpx(22))

  let titleList = loc(shopItem?.nameLocId ?? "").split("\r\n")
  let itemMinAmount = content?.itemsAmount.x ?? 0
  let itemMaxAmount = content?.itemsAmount.y ?? 0
  let isBundle = (shopItem?.crates ?? []).len() > 1
  let maxCount = getMaxCount(shopItem)
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    gap = bigPadding
    padding = [0, fsh(2)]
    vplace = ALIGN_BOTTOM
    color = defBgColor
    children = [
      !showDiscount ? null
        : mkDiscountWidget(shopItem.discountInPercent, { pos = [hdpx(20), -hdpx(20)] })
      {
        size = [flex(), SIZE_TO_CONTENT]
        minHeight = fsh(6)
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        children = [
          shopIcon
          seasonBpIcon
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = titleList.map(@(text, idx)
              mkTitle(text, itemMinAmount, itemMaxAmount, idx, isBundle))
          }
          maxCount <= 1 || countWatched == null ? null : mkCounter(maxCount, countWatched)
        ]
      }
    ]
  }
}

let function mkTimeAvailable(shopItem) {
  let { showIntervalTs = [] } = shopItem
  let toTs = showIntervalTs?[1] ?? 0
  if (toTs < serverTime.value)
    return null

  return function() {
    let res = { watch = serverTime }
    let timeLeft = toTs - serverTime.value
    if (timeLeft <= 0)
      return res

    return res.__update({
      children = mkRightHeaderFlag({
        flow = FLOW_HORIZONTAL
        valign = ALIGN_BOTTOM
        gap = hdpx(2)
        padding = bigPadding
        children = [
        faComp("clock-o", {
          fontSize = body_txt.fontSize
          color = TextNormal
        })
        {
          rendObj = ROBJ_TEXT
          text = secondsToHoursLoc(timeLeft)
          color = TextNormal
        }.__update(body_txt)
      ]}, primeFlagStyle.__merge({
        offset = 0
      }))
    })
  }
}

let debugTag = {
  rendObj = ROBJ_SOLID
  color = 0xFFCC0000
  padding = bigPadding
  children = {
    rendObj = ROBJ_TEXT
    text = "DEBUG ONLY"
  }.__update(sub_txt)
}

let mkShopItemView = kwarg(@(
  shopItem, purchasingItem = null, unseenSignalObj = null, onCrateViewCb = null,
  onInfoCb = null, isLocked = false, containerIcon = null, crateContent = null,
  itemTemplates = null, showVideo = null, showDiscount = false) {
    size = flex()
    halign = ALIGN_RIGHT
    children = [
      mkShopItemImg(shopItem?.image ?? "", {
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_CENTER
          imageValign = ALIGN_TOP
          picSaturate = isLocked ? 0.1 : 1
        })
      showVideo ? mkShopItemVideo(shopItem.video) : null
      mkShopItemTitle(shopItem, crateContent, itemTemplates, showDiscount)
      containerIcon
      purchasingItem == null ? null : mkPurchaseSpinner(shopItem, purchasingItem)
      {
        valign = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        children = [
          mkTimeAvailable(shopItem)
          unseenSignalObj
        ]
      }
      onInfoCb != null ? mkInfoBtn(onInfoCb) : mkViewCrateBtn(crateContent, onCrateViewCb)
      shopItem?.isShowDebugOnly ?? false ? debugTag : null
      itemHighlight(shopItem.guid)
    ]
  })

let mkProductView = @(shopItem, itemTemplates, crateContent = null) {
  rendObj = ROBJ_SOLID
  size = shopItem?.squads[0] != null ? cardSquadPreviewSize : cardPreviewSize
  padding = hdpx(1)
  color = idleBgColor
  clipChildren = true
  children = mkShopItemView({ shopItem, crateContent, itemTemplates })
}

let tiersStars = @(minTier, maxTier) maxTier <= 0 ? null : {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  margin = fsh(1)
  children = maxTier <= minTier
    ? mkIconBar(minTier, soldierLvlColor, "star", { fontSize = hdpx(20) })
    : [
        mkIconBar(minTier, soldierLvlColor, "star", { fontSize = hdpx(20) })
        faComp("ellipsis-h", {fontSize = hdpx(20), margin = [0, fsh(1)], color = disabledTxtColor})
        mkIconBar(maxTier, soldierLvlColor, "star", { fontSize = hdpx(20) })
      ]
}

let mkMsgBoxView = @(shopItem, crateContent, countWatched, showDiscount = false)
  function() {
    let { armyId = null } = crateContent?.value
    let templates = allItemTemplates.value?[armyId]
    let { minTier, maxTier } = getTierInterval(crateContent?.value.content.items, templates)
    return {
      watch = [crateContent, allItemTemplates]
      rendObj = ROBJ_SOLID
      size = shopItem?.squads[0] != null ? cardSquadPreviewSize : cardPreviewSize
      padding = hdpx(1)
      color = idleBgColor
      clipChildren = true
      children = {
        size = flex()
        halign = ALIGN_RIGHT
        children = [
          mkShopItemImg(shopItem.image, {
            keepAspect = KEEP_ASPECT_FILL
            imageHalign = ALIGN_CENTER
            imageValign = ALIGN_TOP
          })
          mkShopItemTitle(shopItem, crateContent, allItemTemplates, showDiscount, countWatched)
          shopItem?.isShowDebugOnly ?? false ? debugTag : null
          itemHighlight(shopItem.guid)
          tiersStars(minTier, maxTier)
        ]
      }
    }
  }

let shopItemLockedMsgBox = @(level, cb = @() null)
  msgbox.show({
    text = loc("obtainAtLevel", { level })
    buttons = [
      { text = loc("Ok"), isCancel = true}
      { text = loc("GoToCampaign"), action = function() {
        scrollToCampaignLvl(level)
        jumpToArmyProgress()
        cb()
      }}
    ]
  })

let viewShopInfoBtnStyle = {
  textCtor = @(textField, params, handler, group, sf) textButtonTextCtor({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = textMargin
    children = [
      faComp("question-circle", {color = sf & S_HOVER ? TextHover : TextNormal})
      textField.__merge({ margin = [0,0,0,bigPadding] })
    ]
  }, params, handler, group, sf)
}

return {
  PRICE_HEIGHT
  DISCOUNT_WARN_TIME
  mkShopItemImg
  mkShopItemView
  mkProductView
  mkMsgBoxView
  mkShopItemInfoBlock
  shopItemLockedMsgBox
  viewShopInfoBtnStyle
  mkLevelLockLine
  mkShopItemPriceLine
  mkClassCanUse
}
