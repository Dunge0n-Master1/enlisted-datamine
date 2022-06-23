from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt, tiny_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%darg/components/fontawesome.map.nut")
let faComp = require("%ui/components/faComp.nut")
let msgbox = require("%ui/components/msgbox.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { mkShopItemPrice } = require("mkShopItemPrice.nut")
let { mkCurrencyCount } = require("%enlist/currency/currenciesComp.nut")
let spinner = require("%ui/components/spinner.nut")({ opacity = 0.7 })
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { getClassCfg, getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { scrollToCampaignLvl, curArmySquadsUnlocks
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { setCurSection } = require("%enlist/mainMenu/sectionsState.nut")
let getEquipClasses = require("%enlist/soldiers/model/equipClassSchemes.nut")
let { defBgColor, bigPadding, smallPadding, defTxtColor, warningColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { TextHover, TextNormal, textMargin
} = require("%ui/components/textButton.style.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { armySquadsById, lockedArmySquadsById } = require("%enlist/soldiers/model/state.nut")
let allowedVehicles = require("%enlist/vehicles/allowedVehicles.nut")
let { hasGoldValue } = require("armyShopState.nut")
let { shopItems } = require("shopItems.nut")
let { BtnBdNormal } = require("%ui/style/colors.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")

const MAX_CLASSES_USAGE = 4
let PRICE_HEIGHT = hdpx(44)

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
      keepAspect = true
      image = Picture(img)
    }.__update(override)

let shopBottomLine = {
  rendObj = ROBJ_SOLID
  size = [flex(), PRICE_HEIGHT]
  padding = [0, fsh(2)]
  color = Color(40,40,40,255)
}

let mkLevelLockLine = @(level) shopBottomLine.__update({
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    faComp("lock", {fontSize = hdpx(20), color = defTxtColor})
    { size = flex() }
    txt({
      text = loc("levelInfo", { level })
    }.__update(sub_txt))
  ]
})

let mkShopItemPriceLine = @(shopItem, personalOffer = null)
  shopItem?.isPriceHidden ?? false ? null
    : shopBottomLine.__update({
        children = mkShopItemPrice(shopItem, personalOffer)
      })

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

let infoBtnSize = hdpx(30).tointeger()
let hoveredInfoBtnSize = hdpx(33).tointeger()

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
  let itemsList = crateContent?.value.content.items ?? {}
  return itemsList.len() == 0 ? null : itemsList
    .reduce(@(res, _, tmpl) res.__update({ [trimUpgradeSuffix(tmpl)] = true }), {})
    .keys()
}

let function extractClasses(crateContent) {
  let classesList = crateContent?.value.content.soldierClasses ?? {}
  return classesList.len() == 0 ? null : classesList
    .map(@(sClass) getClassCfg(sClass).kind)
    .reduce(@(res, sKind) res.__update({ [sKind] = true }), {})
    .keys()
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
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    mkSquadIcon(squad?.icon, { size = [hdpx(40), hdpx(40)], margin = smallPadding })
    {
      rendObj = ROBJ_TEXT
      color = unlockLevel == 0 ? defTxtColor : warningColor
      text = loc(squad?.manageLocId ?? "")
    }.__update(body_txt)
  ]
}

let mkUnlockVehicleLevel = @(level) level == 0 ? null : {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = [
    faComp("lock", {fontSize = hdpx(20), color = warningColor})
    txt({
      text = loc("levelInfo", { level })
      color = warningColor
    }.__update(body_txt))
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
    padding = bigPadding
    color = defBgColor
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      mkForVehicleSquad(squad, unlockLevel)
      mkUnlockVehicleLevel(unlockLevel)
    ]
  }
}

let function mkShopItemUsage(crateContent, itemTemplates) {
  let itemsList = extractItems(crateContent) ?? []
  if (itemsList.len() != 1)
    return null

  let { armyId = null } = crateContent?.value
  let templates = itemTemplates?.value[armyId]
  let itemtmpl = itemsList[0]
  let { itemtype = null } = templates?[itemtmpl]

  if (itemtype == "vehicle"){
    let vehicleSquadIds = (allowedVehicles.value?[armyId] ?? {})
      .filter(@(squad) squad?[itemtmpl]).keys()
    let squadsCount = vehicleSquadIds.len()
    return squadsCount == 0 ? null : {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("shop/squadsCanUse", { squadsCount })
        }.__update(body_txt)
      ].extend(vehicleSquadIds.map(@(squadId) mkSquadUsageKind(squadId, armyId)))
    }
  }

  let kindsList = getEquipClasses(armyId, itemtmpl, itemtype)
    .reduce(@(tbl, sClass) tbl.__update({ [getClassCfg(sClass).kind] = true }), {})
    .keys()
  let count = kindsList.len()
  if (count == 0)
    return null

  return count > MAX_CLASSES_USAGE
    ? {
        rendObj = ROBJ_TEXT
        text = loc("shop/anyCanUse")
      }.__update(body_txt)
    : {
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("shop/someCanUse", { count })
        }.__update(body_txt)
      ].extend(kindsList.map(mkItemUsageKind))
    }
}

let mkDiscountIcon = @(discountInPercent, override = {}) (discountInPercent ?? 0) > 0
  ? {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      size = [SIZE_TO_CONTENT, hdpx(20)]
      children = [
        {
          rendObj = ROBJ_INSCRIPTION
          validateStaticText = false
          text = fa["certificate"]
          color = 0xffff313b
        }.__update(fontawesome, { fontSize = hdpx(70) })
        mkCurrencyCount($"-{discountInPercent}%")
      ]
      pos = [0, -hdpx(10)]
    }.__update(override)
  : null

let function mkTitle(text, itemAmount, idx, isBundle) {
  let { minAmount = -1, maxAmount = -1} = itemAmount
  return {
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
        text = minAmount == maxAmount ? $"×{minAmount}" : $"×{minAmount}-{maxAmount}"
      }.__update(body_txt)
    ]
  }
}

let mkDiscountEndingAnim = @(delay){
  transform = {}
  animations = [{
    prop = AnimProp.opacity
    from = 0.3
    to = 1
    duration = 1
    loop = true
    easing = Blink
    play = true
    delay
  }]
}

let function mkShopItemTitle(shopItem, crateContent, itemTemplates, isLocked, personalOffer) {
  let { armyId = null, content = {} } = crateContent?.value
  local shopIcon

  let itemsList = extractItems(crateContent)
  if (itemsList != null && itemsList.len() == 1) {
    let templates = itemTemplates?.value[armyId]
    let item = templates?[itemsList[0]]
    shopIcon = itemTypeIcon(item?.itemtype, item?.itemsubtype)
  }

  let soldierClasses = extractClasses(crateContent)
  if (soldierClasses != null && soldierClasses.len() == 1)
    shopIcon = kindIcon(soldierClasses[0], hdpx(22))

  local { discountInPercent = 0, shop_discount = null, discountIntervalTs = [] } = shopItem
  local discount = personalOffer == null
    ? discountInPercent
    : personalOffer.discountInPercent

  local hasDiscount = (shop_discount ?? discount) > 0
  if (discount > 0 && !hasGoldValue(shopItem)){
    hasDiscount = false
    discount = 0
  }

  local discountAnimation = {}
  if (hasDiscount && discountIntervalTs.len() == 2){
    let [from, to] = discountIntervalTs
    let ts = serverTime.value
    if (from <= ts && to != 0 && to > ts)
      discountAnimation = mkDiscountEndingAnim(max(to - ts - DISCOUNT_WARN_TIME, 0))
  }

  let rightOffset = !isLocked && hasDiscount ? hdpx(70) : 0
  let titleList = loc(shopItem.nameLocId).split("\r\n")
  let itemMinAmount = content?.itemsAmount.x ?? 0
  let itemMaxAmount = content?.itemsAmount.y ?? 0
  let isBundle = (shopItem?.crates ?? []).len() > 1
  let itemAmount = {
    minAmount = itemMinAmount
    maxAmount = itemMaxAmount
  }
  return  {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    gap = bigPadding
    padding = [0, fsh(2)]
    vplace = ALIGN_BOTTOM
    color = defBgColor
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        minHeight = fsh(6)
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        margin = [0, rightOffset, 0, 0]
        children = [
          shopIcon
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = titleList.map(@(text, idx)
              mkTitle(text, itemAmount, idx, isBundle))
          }
        ]
      }
      isLocked ? null : mkDiscountIcon(shop_discount ?? discount, discountAnimation)
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
      size = [SIZE_TO_CONTENT, hdpx(32)]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(2)
      padding = [0, bigPadding]
      children = [
        faComp("clock-o", {
          fontSize = hdpx(13)
          color = TextNormal
        })
        {
          rendObj = ROBJ_TEXT
          text = secondsToHoursLoc(timeLeft)
          color = TextNormal
        }.__update(sub_txt)
      ]
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
    itemTemplates = null, personalOffer = null
  ) {
    size = flex()
    halign = ALIGN_RIGHT
    children = [
      mkShopItemImg(shopItem.image, {
        keepAspect = KEEP_ASPECT_FILL
        imageHalign = ALIGN_CENTER
        imageValign = ALIGN_TOP
        picSaturate = isLocked ? 0.1 : 1
      })
      mkShopItemTitle(shopItem, crateContent, itemTemplates, isLocked, personalOffer)
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
  color = BtnBdNormal
  clipChildren = true
  children = mkShopItemView({ shopItem, crateContent, itemTemplates })
}

let mkDynamicProductView = @(itemGuid, itemTemplates, crateContent = null) function(){
  let shopItem = shopItems.value?[itemGuid]
  return mkProductView(shopItem, itemTemplates, crateContent).__update({ watch = shopItems })
}

let shopItemLockedMsgBox = @(level, cb = @() null)
  msgbox.show({
    text = loc("obtainAtLevel", { level })
    buttons = [
      { text = loc("Ok"), isCancel = true}
      { text = loc("GoToCampaign"), action = function() {
        scrollToCampaignLvl(level)
        setCurSection("SQUADS")
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
  mkDynamicProductView
  mkShopItemUsage
  shopItemLockedMsgBox
  viewShopInfoBtnStyle
  mkLevelLockLine
  mkShopItemPriceLine
  mkDiscountIcon
}
