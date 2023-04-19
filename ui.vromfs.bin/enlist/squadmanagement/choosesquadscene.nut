from "%enlSqGlob/ui_library.nut" import *

let { fontLarge, fontXXLarge, fontSmall, fontXLarge
} = require("%enlSqGlob/ui/fontsStyle.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { colFull, midPadding, colPart, panelBgColor, columnGap, bigPadding, navHeight, highlightLine,
  footerContentHeight, defTxtColor, titleTxtColor, smallPadding, defBdColor, leftAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curArmy, armySquadsById } = require("%enlist/soldiers/model/state.nut")
let { mkBackWithImage } = require("%enlist/soldiers/mkSquadPromo.nut")
let { unseenSquads, markSeenSquads } = require("%enlist/soldiers/model/unseenSquads.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { mkSquadIcon, isSquadPremium, mkSquadSpecIconFields
} = require("%enlSqGlob/ui/squadsUiComps.nut")
let armyCurrencyUi = require("%enlist/shop/armyCurrencyUi.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let armySelectUi = require("%enlist/army/armySelectionUi.nut")
let { squadsArmy, selectedSquadId, chosenSquads, squadsArmyLimits, changeList, unlockedSquads,
  reserveSquads, slotsCount, curArmyLockedSquadsData, closeAndOpenCampaign, displaySquads,
  sendSquadActionToBQ, selectedSquad, changeSquadOrderByUnlockedIdx, maxSquadsInBattle,
  previewSquads } = require("%enlist/soldiers/model/chooseSquadsState.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { squadInfo, lockedSquadInfo } = require("%enlist/squad/squadInfo.nut")
let { mkDraggableSquadCard, isSquadDragged, squadSlotToPurchase, mkLockedPremiumCard
} = require("%enlist/squadmanagement/mkSquadAdditionalCard.nut")
let { mkLockedSquadCard } = require("%enlSqGlob/ui/mkSquadCard.nut")
let { tutorials } = require("%enlist/tutorial/squadTextTutorialPresentation.nut")
let openSquadTextTutorial = require("%enlist/tutorial/squadTextTutorial.nut")
let { curArmySquadsUnlocks, scrollToCampaignLvl
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { isEventRoom } = require("%enlist/mpRoom/enlRoomState.nut")
let { isEventModesOpened } = require("%enlist/gameModes/eventModesState.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkCurSquadsList.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { openUnlockSquadScene } = require("%enlist/soldiers/unlockSquadScene.nut")
let { mkFreemiumXpImage } = require("%enlist/debriefing/components/mkXpImage.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")
let { needFreemiumStatus, disableBuySquadSlot, curCampaignAccessItem
} = require("%enlist/campaigns/campaignConfig.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let premium = require("%enlist/currency/premium.nut")
let { hasPremium } = premium
let premiumSquadsInBattle = premium.maxSquadsInBattle
let { armySlotItem } = require("%enlist/shop/armySlotDiscount.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let shopItemClick = require("%enlist/shop/shopItemClick.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { shopItemContentCtor } = require("%enlist/shop/armyShopState.nut")
let { mkProductView } = require("%enlist/shop/shopPkg.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let presetsBlock = require("%enlist/squadmanagement/squadPresetsBlock.nut")
let { set_squad_order } = require("%enlist/meta/clientApi.nut")


const RESERVE_SQUADS_PER_PAGE = 40
const SQUADS_PER_ROW = 8
const ANIM_ITEM_TIME = 0.04
let isOpened = keepref(Computed(@() squadsArmy.value != null))
let curReservePage = Watched(0)
let squadInfoBtnParams = { btnWidth = flex() }
let squadIconSize = colPart(0.87)
let premIconSize = colPart(0.75)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let headerTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)
let titleTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let mainInfoTxtStyle = { color = defTxtColor }.__update(fontXLarge)
let squadListsWidth = colFull(16)
let smallIconHeight = colPart(0.43)
let presetsButtonHeight = colPart(1.55)
let presetsButtonMinWidth = colFull(3.5)

curArmy.subscribe(@(_v) curReservePage(0))

let isReserveFocused = Computed(@()
  reserveSquads.value.findvalue(@(v) v?.guid == selectedSquad.value?.guid) != null)


let function lockedSquadBlock(unlock, nameLocId) {
  if (unlock == null)
    return null

  let text = loc("squads/cantUseLocked", {
    name = loc(nameLocId)
    level = unlock.level
  })
  let goToUnlockBtn = Bordered(loc("squads/gotoUnlockBtn"), function() {
      scrollToCampaignLvl(unlock.level)
      closeAndOpenCampaign() },
    squadInfoBtnParams)
  return @() {
    watch = [isEventRoom, isEventModesOpened]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        text
      }.__update(defTxtStyle)
      isEventRoom.value || isEventModesOpened.value ? null : goToUnlockBtn
    ]
  }
}


let currencies = {
  flow = FLOW_HORIZONTAL
  gap = columnGap
  hplace = ALIGN_RIGHT
  children = [
    currenciesWidgetUi
    armyCurrencyUi
  ]
}


let squadImage = @(icon) mkSquadIcon(icon, {
  size = [squadIconSize, squadIconSize]
  hplace = ALIGN_RIGHT
  margin = midPadding
})


let mkSquadImage = @(squadCfg, armyId) function() {
  let { image, icon } = squadCfg
  return {
    size = [flex(), colPart(4.5)]
    children = [
      mkBackWithImage(image, false)
      mkSquadSpecIconFields(armyId, squadCfg, isSquadPremium(squadCfg),
        { size = [premIconSize, premIconSize]})
      squadImage(icon)
    ]
  }
}


let squadInfoBtn = Bordered(loc("squads/squadInfo"), function() {
  let armyId = squadsArmy.value
  openUnlockSquadScene({
    armyId
    squad = armySquadsById.value?[armyId][selectedSquadId.value]
    squadCfg = squadsCfgById.value?[armyId][selectedSquadId.value]
    unlockInfo = null
  })}, squadInfoBtnParams.__merge({ hotkeys = [["^J:Y"]] }))


let function premiumInfoButtons(shopItem) {
  let crateContent = shopItemContentCtor(shopItem)
  let productView = mkProductView(shopItem, allItemTemplates, crateContent)
  let hasUrl = shopItem?.url != null && shopItem.url != ""
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    vplace = ALIGN_BOTTOM
    children =  [
      Bordered(loc("squads/purchase"),
        @() buyShopItem({ shopItem, productView }),
        squadInfoBtnParams.__merge({ hotkeys = [["^J:Y"]] }))
      hasUrl ? null
        : Bordered(loc("squads/squadInfo"), @() shopItemClick(shopItem), squadInfoBtnParams)
    ]
  }
}


let btnFreemiumIcon = {
  padding = [0, smallPadding]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = mkFreemiumXpImage(smallIconHeight)
}


let function freemiumSquadBlock() {
  let goToUnlockBtn = Bordered(loc("squads/squadInfo"), @(_) freemiumWnd(),
    squadInfoBtnParams.__merge({
      bgChild = btnFreemiumIcon
      hotkeys = [["^J:Y"]]
    }))
  return {
    watch = [isEventRoom, isEventModesOpened]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        text = loc("freemium/newDesc")
      }.__update(defTxtStyle)
      isEventRoom.value || isEventModesOpened.value ? null : goToUnlockBtn
    ]
  }
}


let squadButtonsBlock = @(squadCfg, isLocked, isPremium) function() {
  let { squadType, id, nameLocId } = squadCfg
  let isBattleSquad = chosenSquads.value.findvalue(@(v) v?.squadId == id) != null
  let unlock = curArmySquadsUnlocks.value
    .findvalue(@(u) u.unlockType == "squad" && u.unlockId == id)
  local lockedShopItem = null
  if (isPremium && isLocked)
    lockedShopItem = curArmyLockedSquadsData.value.findvalue(@(v) v.squad.squadId == id)?.shopItem
  let campaignSquads = curCampaignAccessItem.value?.squads ?? []
  let isInCampaign = campaignSquads.findvalue(@(sq) sq.id == id) != null
  return {
    watch = [chosenSquads, selectedSquad, curArmySquadsUnlocks,
      curArmyLockedSquadsData, curCampaignAccessItem]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    vplace = ALIGN_BOTTOM
    gap = midPadding
    children = [
      !isLocked
        ? {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = midPadding
            children = [
              Bordered(isBattleSquad ? loc("squads/toReserve") : loc("squads/toBattle"), changeList,
                squadInfoBtnParams.__merge({ hotkeys = [["^J:X"]] }))
              squadInfoBtn
            ]
          }
        : isInCampaign ? freemiumSquadBlock
        : isPremium ? premiumInfoButtons(lockedShopItem)
        : lockedSquadBlock(unlock, nameLocId)
      squadType in tutorials
        ? Bordered(loc("squads/tutorial"), @() openSquadTextTutorial(squadType), squadInfoBtnParams)
        : null
    ]
  }
}


let function selectedSquadInfo() {
  let armyId = squadsArmy.value
  let squadCfg = squadsCfgById.value?[armyId][selectedSquadId.value]
  let res = { watch = [selectedSquadId, squadsCfgById, squadsArmy, curArmyLockedSquadsData,
    reserveSquads] }
  if (squadCfg == null)
    return res
  let isLocked = curArmyLockedSquadsData.value.findvalue(@(v)
    v?.squad.squadId == squadCfg.id) != null
  let isPremium = isSquadPremium(squadCfg)
  return res.__update({
    size = [colFull(5), SIZE_TO_CONTENT]
    rendObj = ROBJ_SOLID
    color = panelBgColor
    halign = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    gap = colPart(0.4)
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          mkSquadImage(squadCfg, armyId)
          highlightLine()
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        padding = [0, columnGap, columnGap, columnGap]
        valign = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        gap = colPart(0.4)
        children = [
          isLocked ? lockedSquadInfo(squadCfg) : squadInfo(false)
          squadButtonsBlock(squadCfg, isLocked, isPremium)
        ]
      }
    ]
  }, leftAppearanceAnim(ANIM_ITEM_TIME))
}



let function squadsArmyInfo(){
  local infantryCur = 0
  local bikeCur = 0
  local vehicleCur = 0
  displaySquads.value.each(function(squad) {
    if (squad == null)
      return
    let { vehicleType = "" } = squad
    if (vehicleType == "bike")
      ++bikeCur
    else if (vehicleType != "")
      ++vehicleCur
    else
      ++infantryCur
  })
  let { maxInfantrySquads, maxBikeSquads, maxVehicleSquads } = squadsArmyLimits.value
  let curSquads = infantryCur + bikeCur + vehicleCur
  let infantryStr = loc("squads/maxInfantry", { infantryCur, infantryMax = maxInfantrySquads })
  let bikeStr = loc("squads/maxBike", { bikeCur, bikeMax = maxBikeSquads })
  let vehicleStr = loc("squads/maxVehicle", { vehicleCur, vehicleMax = maxVehicleSquads })
  return {
    watch = [squadsArmyLimits, displaySquads]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/maxSquads", { curSquads, maxSquads = maxSquadsInBattle.value })
    }.__update(titleTxtStyle)
    {
      rendObj = ROBJ_TEXT
      text = " | ".join([infantryStr, bikeStr, vehicleStr])
    }.__update(defTxtStyle)
  ]
}}


let function saveAndClose() {
  let armyId = squadsArmy.value
  let guids = unlockedSquads.value.filter(@(s) s != null).map(@(s) s.guid)
  let ids = unlockedSquads.value.filter(@(s) s != null).map(@(s) s.squadId)
  markSeenSquads(armyId, ids)
  set_squad_order(armyId, guids)
  squadsArmy(null)
}


let leftHeaderBlock = {
  flow = FLOW_HORIZONTAL
  gap = colFull(1)
  hplace = ALIGN_LEFT
  children = [
    Bordered(loc("bp/close"), saveAndClose, { hotkeys = [[$"^{JB.B} | Esc"]] })
    {
      rendObj = ROBJ_TEXT
      text = loc("squadManagement")
    }.__update(headerTxtStyle)
  ]
}


let headerUi = {
  size = [flex(), navHeight]
  gap = colFull(1)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    leftHeaderBlock
    armySelectUi
    currencies
  ]
}


let reservePaginator = mkDotPaginator({
  id = "squadManagement"
  pageWatch = curReservePage
  dotSize = defTxtStyle.fontSize
})


let function changeReservePage(delta, pagesCount) {
  let curIdx = curReservePage.value
  let neededIdx = curIdx + delta
  if (neededIdx >= 0 && neededIdx <= pagesCount - 1)
    curReservePage(neededIdx)
}


let hotkeysPaginatorBlock = @(pagesCount) pagesCount <= 1 ? null : {
  size = [colFull(3), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = { size = [flex(), SIZE_TO_CONTENT ]}
  children = [
    mkHotkey("^J:L.Thumb.Left | Left", @() changeReservePage(-1, pagesCount))
    reservePaginator(pagesCount)
    mkHotkey("^J:L.Thumb.Right | Right", @() changeReservePage(1, pagesCount))
  ]
}


let reserveBlockHeader = @(pagesCount, reserveSquadsCount) {
  size = [squadListsWidth, SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/reserveHeader", { count = reserveSquadsCount })
    }.__update(mainInfoTxtStyle)
    hotkeysPaginatorBlock(pagesCount)
  ]
}


let wrapParams = {
  width = squadListsWidth
  hGap = columnGap
  vGap = columnGap
}


let function getSquadsToShow(data, curPage) {
  let firstIdxToShow = curPage * RESERVE_SQUADS_PER_PAGE
  return data.slice(firstIdxToShow, firstIdxToShow + RESERVE_SQUADS_PER_PAGE)
}


let function mkSquadAnimDelay(idx) {
  let currentRow = idx / SQUADS_PER_ROW
  let rowAdditionalDelay = currentRow * 0.1
  return (idx % SQUADS_PER_ROW) * 0.05 + rowAdditionalDelay
}

let function mkSquadReserveList(reserve, locked, curPage) {
  local animIdx = -curPage * RESERVE_SQUADS_PER_PAGE
  return reserve.map( function(squad, index) {
    let animationsDelay = mkSquadAnimDelay(animIdx)
    animIdx++
    let idx = index + slotsCount.value
    let { squadType, icon, level, premIcon, squadId } = squad
    return mkDraggableSquadCard({
      idx
      onClick = @() selectedSquadId(squadId)
      squadId
      squadType
      icon
      level
      premIcon
      isReserve = true
      animDelay = animationsDelay
    })
  }).extend(locked.map(function(val, idx) {
    let { isPremium, isInCampaign } = val
    let onClick = @() selectedSquadId(val.squad.squadId)
    let { level = null } = val.shopItem
    let { icon, squadType, squadId } = val.squad
    let animationsDelay = mkSquadAnimDelay(animIdx)
    animIdx++
    return isPremium
      ? mkLockedPremiumCard({
          premIcon = val?.squad.premIcon
          idx
          onClick
          icon
          squadType
          animDelay = animationsDelay
          shopItem = val.shopItem
          squadId
          isInCampaign
        })
      : mkLockedSquadCard({
          idx
          level
          onClick
          icon
          squadType
          squadId
          curSelectedSquad = selectedSquadId
          animDelay = animationsDelay
        })
  }))
}


let reserveSquadsList = @(squadsData) function() {
  let squadsToShow = getSquadsToShow(squadsData, curReservePage.value)
  return {
    watch = [curReservePage, isSquadDragged]
    rendObj = ROBJ_BOX
    borderColor = defBdColor
    borderWidth = isSquadDragged.value ? [hdpx(1), 0] : 0
    padding = [smallPadding, 0]
    behavior = Behaviors.DragAndDrop
    size = [squadListsWidth, SIZE_TO_CONTENT]
    onDrop = function(squadIdx) {
      let dropSquad = chosenSquads.value?[squadIdx]
      if (dropSquad == null)
        return
      let { guid, squadId } = dropSquad
      sendSquadActionToBQ("move_to_reserve", guid, squadId)
      reserveSquads.mutate(@(v) v.insert(0, dropSquad))
      chosenSquads.mutate(@(v) v[squadIdx] = null)
    }
    children = wrap(squadsToShow, wrapParams)
  }
}


let function reserveBlock() {
  let squadsData = mkSquadReserveList(reserveSquads.value, curArmyLockedSquadsData.value,
    curReservePage.value)
  let pagesCount = (squadsData.len() - 1) / RESERVE_SQUADS_PER_PAGE + 1
  let reserveSquadsCount = reserveSquads.value.len()
  return {
    watch = [reserveSquads, curArmyLockedSquadsData, curReservePage]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      reserveBlockHeader(pagesCount, reserveSquadsCount)
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          reserveSquadsList(squadsData)
          selectedSquadInfo
        ]
      }
    ]
  }
}

let freemiumIcon = mkFreemiumXpImage(smallIconHeight).__update({
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
})

let premiumIcon = premiumImage(smallIconHeight, {
  margin = bigPadding
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
})


let function choosenSquadsBlock() {
  let extendedSlots = []
  if (previewSquads.value == null) {
    if (needFreemiumStatus.value && maxSquadsInBattle.value > 0)
      extendedSlots.append(squadSlotToPurchase(freemiumWnd, freemiumIcon))
    else if (!hasPremium.value && premiumSquadsInBattle.value > 0)
      extendedSlots.append(squadSlotToPurchase(premiumWnd, premiumIcon))
    else if (!disableBuySquadSlot.value) {
      let shopItem = armySlotItem.value
      if (shopItem && hasPremium.value)
        extendedSlots.append(squadSlotToPurchase(@() buyShopItem({ shopItem })))
    }
  }
  return {
    watch = [displaySquads, needFreemiumStatus, maxSquadsInBattle, hasPremium, premiumSquadsInBattle,
      disableBuySquadSlot, armySlotItem]
    size = flex()
    flow = FLOW_VERTICAL
    gap = bigPadding
    valign = ALIGN_BOTTOM
    children = [
      squadsArmyInfo
      {
        size = [flex(), SIZE_TO_CONTENT]
        clipChildren = true
        flow = FLOW_HORIZONTAL
        gap = columnGap
        children = [
          mkCurSquadsList({
            curSquadsList = displaySquads
            curSquadId = selectedSquadId
            setCurSquadId = @(id) selectedSquadId(id)
            isDraggable = true
            maxSquadsLen = maxSquadsInBattle.value
            addedObj = {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = columnGap
              children = extendedSlots
            }
          })
          {
            halign = ALIGN_RIGHT
            size = SIZE_TO_CONTENT
            children = Bordered(loc("squads/presets"), presetsBlock.open, {
              minWidth = presetsButtonMinWidth
              btnHeight = presetsButtonHeight
            })
          }
        ]
      }
    ]
  }
}


let function changeChoosenSquadIdx(delta) {
  let curSquadIdx = chosenSquads.value.findindex(@(v) v?.guid == selectedSquad.value?.guid)
  if (curSquadIdx == null)
    return
  let newIdx = curSquadIdx + delta
  if (newIdx >= 0 && newIdx < maxSquadsInBattle.value)
    changeSquadOrderByUnlockedIdx(curSquadIdx, newIdx)
}


let function changeReserveSquadIdx(delta) {
  let curSquadIdx = reserveSquads.value.findindex(@(v) v?.guid == selectedSquad.value?.guid)
  if (curSquadIdx == null)
    return
  let newIdx = curSquadIdx + delta
  if (newIdx >= 0 && newIdx < reserveSquads.value.len())
    changeSquadOrderByUnlockedIdx(curSquadIdx + maxSquadsInBattle.value, newIdx + maxSquadsInBattle.value)
}



let function choosenSquadHotkeys() {
  let action = isReserveFocused.value ? changeReserveSquadIdx : changeChoosenSquadIdx
  return {
    watch = isReserveFocused
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    valign = ALIGN_CENTER
    margin = [0,0, columnGap, 0]
    children = [
      mkHotkey("Q | J:LB", @() action(-1))
      mkHotkey("E | J:RB", @() action(1))
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("squadManagement/hotkeys"))
      }.__update(defTxtStyle)
    ]
  }
}


let bodyUi = {
  size = flex()
  flow = FLOW_VERTICAL
  padding = [0, 0, footerContentHeight, 0]
  children = [
    choosenSquadHotkeys
    reserveBlock
    choosenSquadsBlock
  ]
}


let curArmyUnseenSquads = Computed(@() unseenSquads.value?[squadsArmy.value] ?? {})


let chooseSquadsScene = @() {
  watch = [squadsArmy, safeAreaBorders]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = flex()
  flow = FLOW_VERTICAL
  gap = colPart(0.5)
  padding = safeAreaBorders.value
  onDetach = @() markSeenSquads(squadsArmy.value, curArmyUnseenSquads.value.keys())
  children =  [
    headerUi
    bodyUi
  ]
}


curArmy.subscribe(@(v) isOpened.value ? squadsArmy(v) : null)

let open = @() sceneWithCameraAdd(chooseSquadsScene, "armory")

if (isOpened.value)
  open()


isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSquadsScene)
})
