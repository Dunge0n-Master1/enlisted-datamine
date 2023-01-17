from "%enlSqGlob/ui_library.nut" import *

let { fontLarge, fontXXLarge, fontSmall, fontXLarge
} = require("%enlSqGlob/ui/fontsStyle.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { colFull, midPadding, colPart, panelBgColor, columnGap, commonBorderRadius, bigPadding,
  navHeight, footerContentHeight, defTxtColor, titleTxtColor, smallPadding, hoverTxtColor, defBdColor
} = require("%enlSqGlob/ui/designConst.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curArmy, armySquadsById, soldiersBySquad } = require("%enlist/soldiers/model/state.nut")
let { mkBackWithImage } = require("%enlist/soldiers/mkSquadPromo.nut")
let { unseenSquads, markSeenSquads } = require("%enlist/soldiers/model/unseenSquads.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let armyCurrencyUi = require("%enlist/shop/armyCurrencyUi.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let armySelectUi = require("%enlist/army/armySelectionUi.nut")
let { squadsArmy, selectedSquadId, chosenSquads, applyAndClose, squadsArmyLimits, changeList,
  reserveSquads, slotsCount, curArmyLockedSquadsData, closeAndOpenCampaign,
  sendSquadActionToBQ, selectedSquad
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let JB = require("%ui/control/gui_buttons.nut")
let squadInfo = require("%enlist/squad/squadInfo.nut")
let { openChooseSoldiersWnd } = require("%enlist/soldiers/model/chooseSoldiersState.nut")
let { mkDraggableSquadCard, isSquadDragged, squadSlotToPurchase
} = require("%enlist/squadmanagement/mkSquadAdditionalCard.nut")
let { mkLockedSquadCard } = require("%enlSqGlob/ui/mkSquadCard.nut")
let { tutorials } = require("%enlist/tutorial/squadTextTutorialPresentation.nut")
let openSquadTextTutorial = require("%enlist/tutorial/squadTextTutorial.nut")
let { curArmySquadsUnlocks, scrollToCampaignLvl
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { isEventRoom } = require("%enlist/mpRoom/enlRoomState.nut")
let { isEventModesOpened } = require("%enlist/gameModes/eventModesState.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkCurSquadsList.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { openUnlockSquadScene } = require("%enlist/soldiers/unlockSquadScene.nut")
let { mkFreemiumXpImage } = require("%enlist/debriefing/components/mkXpImage.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")
let { needFreemiumStatus, disableBuySquadSlot, maxSquadsInBattle
} = require("%enlist/campaigns/campaignConfig.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let premium = require("%enlist/currency/premium.nut")
let { hasPremium } = premium
let premiumSquadsInBattle = premium.maxSquadsInBattle
let { armySlotItem } = require("%enlist/shop/armySlotDiscount.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")


const RESERVE_SQUADS_PER_PAGE = 32
let isOpened = keepref(Computed(@() squadsArmy.value != null))
let curReservePage = Watched(0)
let squadInfoBtnParams = { btnWidth = flex() }
let squadIconSize = colPart(1.4)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let hoverTxtStyle = { color = hoverTxtColor }.__update(fontSmall)
let headerTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)
let titleTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let mainInfoTxtStyle = { color = defTxtColor }.__update(fontXLarge)
let squadListsWidth = colFull(16)
let smallIconHeight = colPart(0.43)


let showLockedSquadMsgbox = function(squadDesc) {
  let { squadId, nameLocId } = squadDesc
  let unlock = curArmySquadsUnlocks.value
    .findvalue(@(u) u.unlockType == "squad" && u.unlockId == squadId)
  if (unlock == null)
    return


  let okBtn = { text = loc("Ok"), isCancel = true }
  msgbox.show({
    text = loc("squads/cantUseLocked", {
      name = loc(nameLocId)
      level = unlock.level
    })
    buttons = Computed(@() isEventRoom.value || isEventModesOpened.value
      ? [okBtn]
      : [okBtn, {
          text = loc("squads/gotoUnlockBtn")
          action = function() {
            scrollToCampaignLvl(unlock.level)
            closeAndOpenCampaign()
          }
          isCurrent = true
        }]
    )
  })
}


let reserveAndLockedList = Computed(@() reserveSquads.value.map(
  function(squad, index) {
    let idx = index + slotsCount.value
    let { squadType, icon, level, premIcon, squadId } = squad
    return mkDraggableSquadCard({
      idx
      onClick = @() selectedSquadId(squadId)
      isSelected = Computed(@() selectedSquadId.value == squadId)
      squadType
      icon
      level
      premIcon
      isReserve = true
    })
  }).extend(curArmyLockedSquadsData.value.map(function(val, idx) {
    let { level } = val.unlockData
    let { icon, squadType } = val.squad
    return mkLockedSquadCard({
      idx
      level
      onClick = @() showLockedSquadMsgbox(val.squad)
      icon
      squadType
    })
  }))
)


let reservePages = Computed(@() reserveAndLockedList.value.len() / RESERVE_SQUADS_PER_PAGE)


let currencies = {
  flow = FLOW_HORIZONTAL
  gap = columnGap
  hplace = ALIGN_RIGHT
  children = [
    currenciesWidgetUi
    armyCurrencyUi
  ]
}


let squadImage = @(icon) {
  size = [squadIconSize, squadIconSize]
  pos = [0, (squadIconSize / 2).tointeger()]
  margin = bigPadding
  padding = midPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  fillColor = panelBgColor
  borderWidth = 0
  borderRadius = commonBorderRadius
  children = mkSquadIcon(icon)
}


let mkSquadImage = @(img, icon) {
  size = [flex(), colPart(4.5)]
  children = [
    mkBackWithImage(img, false)
    squadImage(icon)
  ]
}


let squadButtonsBlock = @(squadType, squadId) function() {
  let isBattleSquad = chosenSquads.value.findvalue(@(v) v?.squadId == squadId) != null
  let curSquadGuid = selectedSquad.value?.guid
  let curSquadSoldiers = soldiersBySquad.value?[curSquadGuid] ?? []
  return {
    watch = [chosenSquads, selectedSquad, soldiersBySquad]
    size = [flex(), SIZE_TO_CONTENT]
    padding = bigPadding
    flow = FLOW_VERTICAL
    vplace = ALIGN_BOTTOM
    gap = midPadding
    children = [
      Bordered(isBattleSquad ? loc("squads/toReserve") : loc("squads/toBattle"), changeList,
        squadInfoBtnParams.__merge({ hotkeys = [["^J:X"]] }))
      Bordered(loc("squads/soldierManagement"),
        @() openChooseSoldiersWnd(curSquadGuid, curSquadSoldiers?[0].guid),
        squadInfoBtnParams)
      squadType in tutorials
        ? Bordered(loc("tutorial"), @() openSquadTextTutorial(squadType),  squadInfoBtnParams)
        : null
    ]
  }
}


let squadInfoBtn = watchElemState(@(sf) {
  behavior = Behaviors.Button
  onClick = function() {
    let armyId = squadsArmy.value
    openUnlockSquadScene({
      armyId
      squad = armySquadsById.value?[armyId][selectedSquadId.value]
      squadCfg = squadsCfgById.value?[armyId][selectedSquadId.value]
      unlockInfo = null
    })
  }
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  valign = ALIGN_CENTER
  pos = [0, -colPart(0.5)]
  children = [
    {
      rendObj = ROBJ_IMAGE
      image =  Picture("{0}:{1}:{1}:K".subst("ui/skin#info/info_icon.svg", defTxtStyle.fontSize))
      color = sf & S_HOVER ? hoverTxtColor : defTxtColor
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/squadInfo")
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle )
  ]
})

let function selectedSquadInfo() {
  let squadCfg = squadsCfgById.value?[squadsArmy.value][selectedSquadId.value]
  let res = { watch = [selectedSquadId, squadsCfgById, squadsArmy] }
  if (squadCfg == null)
    return res
  let { image, icon, squadType, id} = squadCfg
  return res.__update({
    size = [colFull(5), colPart(10.1)]
    rendObj = ROBJ_SOLID
    color = panelBgColor
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = colPart(0.7)
    children = [
      mkSquadImage(image, icon)
      squadInfo(false)
      squadButtonsBlock(squadType, id)
    ]
  })
}

let selectedSquadInfoUi = {
  hplace = ALIGN_RIGHT
  children = [
    squadInfoBtn
    selectedSquadInfo
  ]
}


let function squadsArmyInfo(){
  local infantryCur = 0
  local bikeCur = 0
  local vehicleCur = 0
  chosenSquads.value.each(function(squad) {
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
    watch = [squadsArmyLimits, chosenSquads]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/maxSquads", { curSquads, maxSquads = chosenSquads.value.len() })
    }.__update(titleTxtStyle)
    {
      rendObj = ROBJ_TEXT
      text = " | ".join([infantryStr, bikeStr, vehicleStr])
    }.__update(defTxtStyle)
  ]
}}


let leftHeaderBlock = {
  flow = FLOW_HORIZONTAL
  gap = colFull(1)
  hplace = ALIGN_LEFT
  children = [
    Bordered(loc("bp/close"), applyAndClose, { hotkeys = [[$"^{JB.B} | Esc"]] })
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


let function changeReservePage(delta) {
  let pagesCount = reservePages.value
  let curIdx = curReservePage.value
  let neededIdx = curIdx + delta
  if (neededIdx >= 0 && neededIdx <= pagesCount - 1)
    curReservePage(neededIdx)
}


let reserveHotkeysBlock = {
  size = [colFull(1), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    mkHotkey("^J:LB | Q", @() changeReservePage(-1))
    mkHotkey("^J:RB | E", @() changeReservePage(1))
  ]
}

let reserveBlockHeader = @() {
  watch = [reserveSquads, reservePages]
  size = [squadListsWidth, SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/reserveHeader", { count = reserveSquads.value.len() })
    }.__update(mainInfoTxtStyle)
    reservePages.value <= 1 ? null : reservePaginator(reservePages.value)
    reservePages.value <= 1 ? null : reserveHotkeysBlock
  ]
}


let wrapParams = {
  width = squadListsWidth
  hGap = columnGap
  vGap = columnGap
}


let function reserveSquadsList() {
  let lastSquadOnPage = (curReservePage.value + 1) * RESERVE_SQUADS_PER_PAGE
  let squadsToShow = reserveAndLockedList.value.slice(lastSquadOnPage - RESERVE_SQUADS_PER_PAGE,
    lastSquadOnPage)
  return {
    watch = [reserveAndLockedList, curReservePage, isSquadDragged]
    rendObj = ROBJ_BOX
    borderColor = defBdColor
    borderWidth = isSquadDragged.value ? [hdpx(1), 0] : 0
    padding = [smallPadding, 0]
    behavior = Behaviors.DragAndDrop
    size = [squadListsWidth, colPart(6.96)]
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


let reserveBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    reserveBlockHeader
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        reserveSquadsList
        selectedSquadInfoUi
      ]
    }
  ]
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
  if (needFreemiumStatus.value && maxSquadsInBattle.value > 0)
    extendedSlots.append(squadSlotToPurchase(freemiumWnd, freemiumIcon))
  else if (!hasPremium.value && premiumSquadsInBattle.value > 0)
    extendedSlots.append(squadSlotToPurchase(premiumWnd, premiumIcon))
  else if (!disableBuySquadSlot.value) {
    let shopItem = armySlotItem.value
    if (shopItem && hasPremium.value)
      extendedSlots.append(squadSlotToPurchase(@() buyShopItem({ shopItem })))
  }
  return {
    watch = [chosenSquads, needFreemiumStatus, maxSquadsInBattle, hasPremium, premiumSquadsInBattle,
      disableBuySquadSlot, armySlotItem]
    size = flex()
    flow = FLOW_VERTICAL
    gap = bigPadding
    valign = ALIGN_BOTTOM
    children = [
      squadsArmyInfo
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = columnGap
        children = mkCurSquadsList({
          curSquadsList = chosenSquads
          curSquadId = selectedSquadId
          setCurSquadId = selectedSquadId
          isDraggable = true
          addedObj = {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = columnGap
            children = extendedSlots
          }
        })
      }
    ]
  }
}


let bodyUi = {
  size = flex()
  flow = FLOW_VERTICAL
  children = [
    reserveBlock
    choosenSquadsBlock
  ]
}


let bottomWndBlock = {
  size = [flex(), footerContentHeight]
}


let curArmyUnseenSquads = Computed(@() unseenSquads.value?[squadsArmy.value] ?? {})


let chooseSquadsScene = @() {
  watch = [squadsArmy, safeAreaBorders]
  size = flex()
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.value
  onDetach = @() markSeenSquads(squadsArmy.value, curArmyUnseenSquads.value.keys())
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = colPart(1.12)
      children = [
        headerUi
        bodyUi
      ]
    }
    bottomWndBlock
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
