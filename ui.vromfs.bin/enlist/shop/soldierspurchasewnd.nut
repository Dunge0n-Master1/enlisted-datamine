from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { curArmyData, curSquadParams } = require("%enlist/soldiers/model/state.nut")
let { shopItemContentCtor, curUnseenAvailShopGuids
} = require("%enlist/shop/armyShopState.nut")
let { soldierShopItems, unseenSoldierShopItems, getSoldiersList, isSoldiersPurchasing
} = require("%enlist/shop/soldiersPurchaseState.nut")
let { bigPadding, smallPadding, titleTxtColor, defTxtColor,
  selectedTxtColor, smallOffset, tinyOffset
} = require("%enlSqGlob/ui/viewConst.nut")
let { makeCrateToolTip } = require("%enlist/items/crateInfo.nut")
let { needFreemiumStatus, CAMPAIGN_NONE } = require("%enlist/campaigns/campaignConfig.nut")
let buySquadWindow = require("buySquadWindow.nut")
let clickShopItem = require("clickShopItem.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkProductView } = require("%enlist/shop/shopPkg.nut")
let { markShopItemSeen } = require("%enlist/shop/unseenShopItems.nut")
let { requestCratesContent, requestedCratesContent, getShopItemsIds
} = require("%enlist/soldiers/model/cratesContent.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { soldiersSquad, soldiersSquadParams, squadSoldiers, soldiersStatuses
} = require("%enlist/soldiers/model/chooseSoldiersState.nut")
let mkSClassLimitsComp = require("%enlist/soldiers/model/squadClassLimits.nut")
let { unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")

let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let { perksStatsCfg } = require("%enlist/meta/perks/perksStats.nut")
let { pPointsBaseParams } = require("%enlist/meta/perks/perksPoints.nut")
let { perkPointIcon, getStatDescList, flexTextArea, mkStatList
} = require("%enlist/soldiers/components/perksPackage.nut")
let { configs } = require("%enlist/meta/configs.nut")
let {
  curSoldierKind, DEF_KIND
} = require("%enlist/soldiers/model/soldiersState.nut")
let { mkAlertObject, mkSoldierShopItem } = require("%enlist/shop/shopPackage.nut")
let { mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { panelBgColor, hoverSlotBgColor } = require("%enlSqGlob/ui/designConst.nut")


let bgColor = 0XEE1F242A
let rootColor = 0XFF1F242A
let selectedColor = mul_color(panelBgColor, 2)

let decorImg = mkTwoSidesGradientX({
  centerColor = 0x77FFFFFF
  sideColor = 0x11FFFFFF
  isAlphaPremultiplied = false
})

let decorObj = {
  size = [flex(), smallPadding]
  rendObj = ROBJ_IMAGE
  image = decorImg
}


let curShopSoldierKind = Watched(DEF_KIND)
let perkSchemes = Computed(@() configs.value?.perkSchemes ?? {})
let soldierSchemes = Computed(@() configs.value?.soldierSchemes ?? {})

const WND_UID = "SOLDIERS_PURCHASE_WND"

let inactiveTxtColor = 0xFF777777

let headerTxtStyle = { color = defTxtColor }.__update(fontBody)

let isOpened = Watched(false)


let function switchKind(kindsToShow, delta){
  let amountKinds = kindsToShow.len()
  local idx = kindsToShow.findindex(@(val)
    val?.soldierKind == curShopSoldierKind.value)
  if (idx == null)
    return

  idx = (idx + delta + amountKinds) % amountKinds
  curSoldierKind(kindsToShow[idx].soldierKind)
}

isOpened.subscribe(function(v) {
  if (v) {
    let soldiers = getShopItemsIds(soldierShopItems.value)
    soldiers.each(@(item, army) requestCratesContent(army, item))
  }
})

let getCrateContent = @(shopItems) Computed(function() {
  let res = []
  shopItems.value.each(function(shopItem) {
    let { armyId, id } = shopItem.crates[0]
    res.append({
      shopItemId = shopItem.id
      reqLevel = shopItem?.requirements.armyLevel ?? 0
      content = requestedCratesContent.value?[armyId][id]
    })
  })
  return res
})


let specializationIconColor = @(sf, isSelected, isAvailable)
  isSelected ? titleTxtColor
    : sf & S_HOVER ? selectedTxtColor
    : isAvailable ? titleTxtColor
    : inactiveTxtColor

let soldiersList = Computed(@() squadSoldiers.value.filter(@(s) s != null))
let currentLimits = mkSClassLimitsComp(soldiersSquad, soldiersSquadParams,
  soldiersList, soldiersStatuses)

let btnWidth = hdpxi(48)
let function mkSpecializationBtn(soldier, isSelected, armyData, unseenKinds) {
  let { soldierKind, reqLvl } = soldier
  let curArmyLvl = armyData?.level ?? 0
  return watchElemState(function(sf) {
    let isSelectedVal = isSelected.value
    let classInfo = currentLimits.value.findvalue(@(x) x.total > 0 && x.sKind == soldierKind)
    let isAvailable = reqLvl <= curArmyLvl && classInfo != null

    return {
      size = [btnWidth, SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      watch = [isSelected, currentLimits]
      onClick = @() curSoldierKind(soldierKind)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          padding = [tinyOffset, 0]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          rendObj = ROBJ_SOLID
          color = sf & S_HOVER ? hoverSlotBgColor
            : isSelectedVal ? selectedColor
            : panelBgColor
          children = [
            kindIcon(soldierKind, hdpxi(30), null, specializationIconColor(sf, isSelectedVal, isAvailable))
            soldierKind in unseenKinds
              ? smallUnseenNoBlink.__update({ hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })
              : null
          ]
        }
        classInfo == null ? null : {
          rendObj = ROBJ_TEXT
          text = $"{classInfo.used}/{classInfo.total}"
          color = isSelectedVal || isAvailable || (sf & S_HOVER) ? defTxtColor : inactiveTxtColor
        }
      ]
    }
  })
}

let specializationsBlock = @(kindsToShow, unseenKinds) @() {
  watch = isGamepad
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = smallOffset
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("soldiers/specializationChoice")
    }.__update(headerTxtStyle)
    {
      flow = FLOW_HORIZONTAL
      gap = tinyOffset
      valign = ALIGN_CENTER
      children = [
        isGamepad.value ? mkHotkey("^J:LB", @() switchKind(kindsToShow, -1)) : null
        @() {
          watch = curArmyData
          flow = FLOW_HORIZONTAL
          children = kindsToShow.map(function(v) {
            let isSelected = Computed(@() curShopSoldierKind.value == v.soldierKind)
            return mkSpecializationBtn(v, isSelected, curArmyData.value, unseenKinds)
          })
        }
        isGamepad.value ? mkHotkey("^J:RB", @() switchKind(kindsToShow, 1)) : null
      ]
    }
    @() {
      watch = [curSoldierKind, curSquadParams]
      hplace = ALIGN_CENTER
      children = curSoldierKind.value in (curSquadParams.value?.maxClasses ?? {}) ? null
        : mkAlertObject(loc("shop/unsuitableForSquad"))
    }
  ]
}


let function mkStartPerk(perksListVal, perksStatsCfgVal, perkScheme, isLocked) {
  if (perkScheme == null)
    return null

  let defaultPerk = perkScheme.findvalue(@(s) s.numChosen == 1)
  if (defaultPerk == null || defaultPerk.perks.len() < 1)
    return null

  let perk = perksListVal?[defaultPerk.perks.top()]
  if (perk == null)
    return null

  let perkStat = perk.cost.keys().top()

  let textarea = flexTextArea({
    text = "\n".join(getStatDescList(perksStatsCfgVal, perk, true))
    size = [hdpx(225), SIZE_TO_CONTENT]
    halign = ALIGN_LEFT
  }.__update(fontSub))

  let { icon, color } = pPointsBaseParams[perkStat]
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    halign = ALIGN_LEFT
    gap = smallPadding
    children = [
      perkPointIcon(icon, isLocked ? defTxtColor : color)
      textarea
    ]
  }
}

let function mkShopItemCard(idx, shopItem, armyData, offers) {
  let { guid = null, requirements = null } = shopItem
  let { armyLevel = 0, isFreemium = false, campaignGroup = CAMPAIGN_NONE } = requirements
  let squad = shopItem?.squads[0]
  let armyId = armyData?.guid ?? ""
  let currentLevel = armyData?.level ?? 0
  let crateContent = shopItemContentCtor(shopItem)
  let offer = offers?[guid]

  return function() {
    let isLocked = armyLevel > currentLevel || (isFreemium && needFreemiumStatus.value)
    let { perkSchemeId = "" } = soldierSchemes.value?[armyId][shopItem.soldierSpec]
    let perkScheme = perkSchemes.value?[perkSchemeId]
    let perkElement = mkStartPerk(perksList.value, perksStatsCfg.value, perkScheme, isLocked)
    let content = crateContent.value?.content
    let statsList = mkStatList(content, sClassesCfg.value, isLocked)
    let hasUnseenSignal = curUnseenAvailShopGuids.value?[shopItem.guid] ?? false
    let unseenSignalObj = hasUnseenSignal ? unblinkUnseen : null
    let templates = allItemTemplates.value
    let reqFreemium = campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value
    let lockTxt = isLocked ? loc("levelInfo", { level = armyLevel })
      : reqFreemium ? loc("shopItemReqFreemium")
      : ""

    let onClick = function() {
      clickShopItem(shopItem, armyData?.level ?? 0)
      if (hasUnseenSignal)
        markShopItemSeen(armyId, guid)
    }
    let onHover = function(on) {
      setTooltip(on ? makeCrateToolTip(crateContent) : null)
      if (hasUnseenSignal)
        hoverHoldAction("markSeenShopItem", { armyId, guid },
          @(v) markShopItemSeen(v.armyId, v.guid))(on)
    }
    let onInfoCb = squad == null || armyLevel > currentLevel ? null
      : @() buySquadWindow({
          shopItem
          productView = mkProductView(shopItem, allItemTemplates)
          armyId = squad.armyId
          squadId = squad.id
        })

    return {
      watch = [curUnseenAvailShopGuids, crateContent, needFreemiumStatus, sClassesCfg,
        perkSchemes, soldierSchemes, perksList, perksStatsCfg, allItemTemplates]
      size = [SIZE_TO_CONTENT, hdpx(500)]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      behavior = Behaviors.Button
      gap = smallPadding
      children = [
        mkSoldierShopItem(idx, armyId, shopItem, offer, content, templates,
          lockTxt, onClick, onHover, null, onInfoCb, unseenSignalObj)
        {
          flow = FLOW_VERTICAL
          valign = ALIGN_TOP
          halign = ALIGN_LEFT
          gap = bigPadding
          padding = bigPadding
          children = [ statsList, perkElement ]
        }
      ]
    }
  }
}

let mkSoldiersList = @(soldiersToShow) function() {
  let soldiers = soldiersToShow.filter(@(s) s?.soldierKind == curShopSoldierKind.value)
  let offers = offersByShopItem.value
  return {
    watch = [curArmyData, curShopSoldierKind, offersByShopItem]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = soldiers.map(@(shopItem, idx) mkShopItemCard(idx, shopItem, curArmyData.value, offers))
  }
}


let function wndContent(onCloseCb) {
  let crateContent = getCrateContent(soldierShopItems)
  return function() {
    let contentToShow = getSoldiersList(crateContent.value, soldierShopItems.value)
    let { kindsToShow, soldiersToShow } = contentToShow
    let unseenKinds = {}
    crateContent.value.each(function(val) {
      let soldierSpec = val?.content.soldierClasses[0]
      if (val.shopItemId in unseenSoldierShopItems.value && soldierSpec != null) {
        let soldier = soldiersToShow.findvalue(@(v) v?.soldierSpec == soldierSpec)
        if (soldier != null)
          unseenKinds[soldier.soldierKind] <- true
      }
    })
    return {
      watch = [crateContent, unseenSoldierShopItems, soldierShopItems]
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = rootColor
      children = [
        decorObj
        {
          size = [flex(), SIZE_TO_CONTENT]
          padding = hdpx(40)
          children = [
            closeBtnBase({ onClick = onCloseCb })
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = hdpx(40)
              children = [
                specializationsBlock(kindsToShow, unseenKinds)
                mkSoldiersList(soldiersToShow)
              ]
            }
          ]
        }
        decorObj
      ]
    }
  }
}


let function updateSoldierKind(_) {
  let sKind = curSoldierKind.value
  let crateContent = getCrateContent(soldierShopItems)
  let contentToShow = getSoldiersList(crateContent.value, soldierShopItems.value)
  let { kindsToShow } = contentToShow
  if (kindsToShow.findvalue(@(v) v.soldierKind == sKind) != null)
    curShopSoldierKind(sKind)
}

foreach (v in [curSoldierKind, requestedCratesContent])
  v.subscribe(updateSoldierKind)


let soldiersPurchaseWnd = @(onCloseCb) {
  key = WND_UID
  size = flex()
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = bgColor
  stopMouse = true
  stopHover = true
  onDetach = function() {
    isSoldiersPurchasing(false)
    isOpened(false)
  }
  onAttach = function() {
    isOpened(true)
    isSoldiersPurchasing(true)
  }
  onClick = @() null
  children = wndContent(onCloseCb)
}


return soldiersPurchaseWnd
