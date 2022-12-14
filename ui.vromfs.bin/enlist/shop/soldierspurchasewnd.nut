from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { shopItemContentCtor, curUnseenAvailShopGuids, purchaseInProgress
} = require("%enlist/shop/armyShopState.nut")
let { soldierShopItems, unseenSoldierShopItems, getSoldiersList, curSpecialization,
  isSoldiersPurchasing
} = require("%enlist/shop/soldiersPurchaseState.nut")
let { bigPadding, smallPadding, titleTxtColor, darkBgColor, activeBgColor,
  hoverBgColor, selectedTxtColor, insideBorderColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { makeCrateToolTip } = require("%enlist/items/crateInfo.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { borderColor } = require("%ui/style/colors.nut")
let buySquadWindow = require("buySquadWindow.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let clickShopItem = require("clickShopItem.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { mkNotifierNoBlink } = require("%enlist/components/mkNotifier.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkShopItemView, mkShopItemPriceLine, mkProductView, mkLevelLockLine
} = require("%enlist/shop/shopPkg.nut")
let { markShopItemSeen } = require("%enlist/shop/unseenShopItems.nut")
let { getCratesListComp } = require("%enlist/soldiers/model/cratesContent.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")

let { soldiersSquad, soldiersSquadParams, squadSoldiers, soldiersStatuses
} = require("%enlist/soldiers/model/chooseSoldiersState.nut")
let mkSClassLimitsComp = require("%enlist/soldiers/model/squadClassLimits.nut")

const WND_UID = "SOLDIERS_PURCHASE_WND"

let inactiveTxtColor = 0xFF777777
let CARD_MAX_WIDTH = fsh(80)

let defTxtStyle = { color = titleTxtColor }.__update(sub_txt)

let isOpened = Watched(false)


let mkShopNotifier = @(locId) mkNotifierNoBlink(locId, { margin = hdpx(3) })
let shopItemNotifier = mkShopNotifier(loc("hint/newShopItemAvailable"))

let function switchClass(classesToShow, delta){
  let amountClasses = classesToShow.len()
  local idx = classesToShow.findindex(@(val)
    val?.soldierClass == curSpecialization.value)
  if (idx == null)
    return

  idx = (idx + delta + amountClasses) % amountClasses
  curSpecialization(classesToShow[idx].soldierClass)
}

let allSoldiersCrates = Computed(@() soldierShopItems.value
  .reduce(@(res, s) res.extend(s?.crates ?? []), [])) //warning disable: -unwanted-modification

let function getCrateContent(shopItems) {
  let listComp = getCratesListComp(allSoldiersCrates)
  return Computed(function() {
    let res = []
    shopItems.value.each(function(shopItem) {
      let { armyId, id } = shopItem.crates[0]
      let { inLineProirity, requirements, offerLine = 0} = shopItem
      res.append({
        shopItemId = shopItem.id
        inLineProirity
        offerLine
        reqLevel = requirements.armyLevel
        content = listComp.value?[id][armyId]
      })
    })
    return res.sort(@(a, b) a.offerLine <=> b.offerLine || b.inLineProirity <=> a.inLineProirity)
  })
}


let specializationIconColor = @(sf, isSelected, isAvailable)
  isSelected || (sf & S_HOVER) ? selectedTxtColor
    : isAvailable ? titleTxtColor
    : inactiveTxtColor

let soldiersList = Computed(@() squadSoldiers.value.filter(@(s) s != null))
let currentLimits = mkSClassLimitsComp(soldiersSquad, soldiersSquadParams,
  soldiersList, soldiersStatuses)

let mkSpecializationBtn = @(soldier, soldierSpec, armyData, unseenSpecs)
  watchElemState(function(sf) {
    let { soldierClass, reqLvl } = soldier
    let curArmyLvl = armyData?.level ?? 0
    let isSelected = soldierSpec == soldierClass

    let classInfo = currentLimits.value.findvalue(@(x) x.total > 0 && x.sKind == soldierClass)
    let isAvailable = reqLvl <= curArmyLvl && classInfo != null

    return {
      size = [hdpx(48), SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      watch = currentLimits
      onClick = @() curSpecialization(soldierClass)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        {
          rendObj = ROBJ_SOLID
          color = isSelected ? activeBgColor
            : sf & S_HOVER ? hoverBgColor
            : darkBgColor
          size = [hdpx(48), hdpx(48)]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = [
            kindIcon(soldierClass, hdpx(26), null, specializationIconColor(sf, isSelected, isAvailable))
            soldierClass in unseenSpecs
              ? smallUnseenNoBlink.__update({ hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })
              : null
          ]
        }
        classInfo == null ? null : {
          rendObj = ROBJ_TEXT
          text = $"{classInfo.used}/{classInfo.total}"
          color = isSelected || isAvailable || (sf & S_HOVER) ? titleTxtColor
            : inactiveTxtColor
        }
      ]
    }
  })


let specializationsBlock = @(classesToShow, unseenSpecs) @() {
  watch = [curArmyData, curSpecialization, isGamepad]
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("soldiers/specializationChoice")
    }.__update(defTxtStyle)
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      children = classesToShow
        .map(@(v) mkSpecializationBtn(v, curSpecialization.value, curArmyData.value, unseenSpecs))
        .insert(0, isGamepad.value ? mkHotkey("^J:LB", @() switchClass(classesToShow, -1)) : null)
        .append(isGamepad.value ? mkHotkey("^J:RB", @() switchClass(classesToShow, 1)) : null)
    }
  ]
}


let hoverBox = @(sf, maxWidth) {
  size = flex()
  maxWidth
  rendObj = ROBJ_BOX
  borderWidth = sf & S_HOVER ? hdpx(4) : hdpx(1)
  borderColor = borderColor(sf, false)
}

let function mkShopItemCard(shopItem, armyData) {
  let { guid = null, curItemCost = {}, discountInPercent = 0 } = shopItem
  let squad = shopItem?.squads[0]
  let armyId = armyData?.guid ?? ""
  let currentLevel = armyData?.level ?? 0
  let { armyLevel = 0, isFreemium = false } = shopItem?.requirements

  let crateContent = shopItemContentCtor(shopItem)
  return watchElemState(function(sf) {
    let isLocked = armyLevel > currentLevel || (isFreemium && needFreemiumStatus.value)
    let hasUnseenSignal = curUnseenAvailShopGuids.value?[shopItem.guid] ?? false
    let unseenSignalObj = !hasUnseenSignal ? null
      : shopItemNotifier
    return {
      watch = [curUnseenAvailShopGuids, crateContent, needFreemiumStatus]
      rendObj = ROBJ_SOLID
      guid
      size = [hdpx(295), hdpx(370)]
      maxWidth = CARD_MAX_WIDTH
      halign = ALIGN_CENTER
      color = darkBgColor
      behavior = Behaviors.Button
      onHover = function(on) {
        setTooltip(on ? makeCrateToolTip(crateContent) : null)
        if (hasUnseenSignal)
          hoverHoldAction("markSeenShopItem", { armyId, guid },
            @(v) markShopItemSeen(v.armyId, v.guid))(on)
      }
      onClick = function() {
        clickShopItem(shopItem, armyData?.level ?? 0)
        if (hasUnseenSignal)
          markShopItemSeen(armyId, guid)
      }
      clipChildren = true
      children = [
        {
          size = flex()
          maxWidth = CARD_MAX_WIDTH
          flow = FLOW_VERTICAL
          children = [
            mkShopItemView({
              shopItem
              isLocked
              purchasingItem = purchaseInProgress
              onCrateViewCb = @() viewShopItemsScene(shopItem)
              onInfoCb = squad == null || armyLevel > currentLevel ? null
                : @() buySquadWindow({
                    shopItem
                    productView = mkProductView(shopItem, allItemTemplates)
                    armyId = squad.armyId
                    squadId = squad.id
                  })
              unseenSignalObj
              crateContent
              itemTemplates = allItemTemplates
              showVideo = shopItem?.video && sf
              showDiscount = (curItemCost.len() > 0) && discountInPercent > 0
            })
            armyLevel > currentLevel ? mkLevelLockLine(armyLevel)
              : mkShopItemPriceLine(shopItem)
          ]
        }
        hoverBox(sf, CARD_MAX_WIDTH)
      ]
  }})
}

let mkSoldiersList = @(soldiersToShow) function() {
  let soldiers = soldiersToShow.filter(@(s) s?.soldierKind == curSpecialization.value)
  return {
    watch = [curArmyData, curSpecialization]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = soldiers.map(@(shopItem) mkShopItemCard(shopItem, curArmyData.value))
  }
}


let function wndContent(onCloseCb) {
  let crateContent = getCrateContent(soldierShopItems)
  return function() {
    let unseenSpecializations = {}
    crateContent.value.each(function(val) {
      if (val.shopItemId in unseenSoldierShopItems.value && val?.content.soldierClasses[0] != null)
        unseenSpecializations[val.content.soldierClasses[0]] <- true
    })
    let contentToShow = getSoldiersList(crateContent.value, soldierShopItems.value)
    let { classesToShow, soldiersToShow } = contentToShow
    return {
      watch = [crateContent, unseenSoldierShopItems, soldierShopItems]
      rendObj = ROBJ_BOX
      borderWidth = [hdpx(2), 0, hdpx(2), 0]
      borderColor = insideBorderColor
      fillColor = darkBgColor
      padding = [hdpx(60), hdpx(40)]
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = [
        closeBtnBase({ onClick = onCloseCb })
        {
          flow = FLOW_VERTICAL
          gap = hdpx(40)
          children = [
            specializationsBlock(classesToShow, unseenSpecializations)
            mkSoldiersList(soldiersToShow)
          ]
        }

      ]
    }
  }
}


let soldiersPurchaseWnd = @(onCloseCb) {
  key = WND_UID
  size = flex()
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = darkBgColor
  fillColor = darkBgColor
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  onDetach = @() isSoldiersPurchasing(false)
  onAttach = function() {
    isOpened(true)
    isSoldiersPurchasing(true)
  }
  onClick = @() null
  children = wndContent(onCloseCb)
}


return soldiersPurchaseWnd
