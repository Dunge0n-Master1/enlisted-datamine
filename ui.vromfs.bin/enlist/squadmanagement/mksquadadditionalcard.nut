from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, accentColor, titleTxtColor, smallPadding, bigPadding, colPart, commonBorderRadius,
  defBdColor, hoverBdColor, defTxtColor, hoverSlotBgColor, defItemBlur, defSlotBgColor,
  rightAppearanceAnim, midPadding, reseveSlotBgColor, defLockedSlotBgColor, hoverLockedSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let faComp = require("%ui/components/faComp.nut")
let { changeSquadOrderByUnlockedIdx, chosenSquads, selectedSquadId, reserveSquads,
  maxSquadsInBattle
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let openSquadTextTutorial = require("%enlist/tutorial/squadTextTutorial.nut")
let { unseenSquadTutorials, markSeenSquadTutorial
} = require("%enlist/tutorial/unseenSquadTextTutorial.nut")
let { mkSquadPremIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { mkItemPurchaseInfo, mkItemBarterInfo } = require("%enlist/shop/shopPricePackage.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { curCampItemsCount } = require("%enlist/soldiers/model/state.nut")
let { mkFreemiumXpImage } = require("%enlist/debriefing/components/mkXpImage.nut")
let { mkLevelBlock, mkSquadInfoBlock, selectionLine } = require("%enlSqGlob/ui/mkSquadCard.nut")


let premIconSize = colPart(0.75)
let selectionLineHeight = colPart(0.08)
let selectionLineOffset = colPart(0.1)
let bottomOffset = selectionLineHeight + selectionLineOffset
let squadCardSize = [colFull(2), colPart(1.55) + bottomOffset]
let squadContentSize = [colFull(2), colPart(1.55)]
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"
let isSquadDragged = Watched(false)
let priceIconSize = colPart(0.32)



let squadBgCommon = @(flags, isSelected, isLocked = false)
  isSelected || (flags & S_HOVER) != 0 ? hoverSlotBgColor
    : isLocked ? defLockedSlotBgColor
    : defSlotBgColor

let squadBgReserve = @(flags, isSelected) isSelected || (flags & S_HOVER) != 0 ? hoverSlotBgColor
  : reseveSlotBgColor


let emptySquadBdColor = @(flags, hasData) hasData && flags > 0 ? accentColor
  : hasData ? accentColor
  : defBdColor


let defTxtStyle = {
  color = titleTxtColor
}.__update(fontMedium)



let function onDrop(squadIdx, curIdx) {
  foreach (cSquad in chosenSquads.value){
    let { squadType = null } = cSquad
    if (squadType in unseenSquadTutorials.value){
      openSquadTextTutorial(squadType)
      markSeenSquadTutorial(squadType)
      break
    }
  }
  changeSquadOrderByUnlockedIdx(squadIdx, curIdx)
}


let mkDraggableSquadCard = kwarg(function(idx, squadId, addChild = null, icon = "",
  squadType = null, level = null, premIcon = null, onClick = null, expireTime = 0,
  isReserve = false, animDelay = 0, isLocked = false
) {
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  let isCardSelected = Computed(@() selectedSquadId.value == squadId)
  return watchElemState(@(sf) {
    watch = isCardSelected
    key = $"squad{idx}"
    size = squadCardSize
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    behavior = Behaviors.DragAndDrop
    transform = {}
    stopHover = true
    stopMouse = true
    onDrop = @(squadIdx) onDrop(squadIdx, idx)
    dropData = idx
    onDragMode = function(on, idx){
      onClick()
      isSquadDragged(on ? idx : null)
    }
    opacity = (sf & S_DRAG) ? 0.5 : 1.0
    xmbNode = XmbNode()
    children = [
      {
        size = flex()
        children = [
          {
            size = squadContentSize
            rendObj = ROBJ_WORLD_BLUR
            fillColor = isReserve
              ? squadBgReserve(sf, isCardSelected.value)
              : squadBgCommon(sf, isCardSelected.value, isLocked)
            color = defItemBlur
            children = [
              {
                size = flex()
                padding = [bigPadding, smallPadding]
                flow = FLOW_HORIZONTAL
                children = [
                  mkSquadIcon(icon)
                  mkSquadInfoBlock(squadType, addChild)
                ]
              }
              mkLevelBlock(sf, isCardSelected.value, level, expireTime)
            ]
          }
          mkSquadPremIcon(premIcon, { size = [premIconSize, premIconSize] })
        ]
      }
      isCardSelected.value ? selectionLine : null
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


let emptySquadArrow = @(hasData, sf) faComp("chevron-down", {
  fontSize = premIconSize / 2
  color = sf > 0 && hasData ? accentColor
    : hasData ? titleTxtColor
    : defTxtColor })


let function emptySlotAtion(curIdx) {
  let curSquadIdx = reserveSquads.value.findindex(@(v) v?.squadId == selectedSquadId.value)
  if (curSquadIdx == null)
    return
  changeSquadOrderByUnlockedIdx(curSquadIdx + maxSquadsInBattle.value, curIdx)
}


let emptySquadSlot = @(curIdx, animDelay = 0) watchElemState(@(sf) {
  watch = isSquadDragged
  rendObj = ROBJ_BOX
  size = squadContentSize
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  borderColor = emptySquadBdColor(sf, isSquadDragged.value || selectedSquadId.value != null)
  behavior = [Behaviors.DragAndDrop, Behaviors.Button]
  onDrop = @(squadIdx) onDrop(squadIdx, curIdx)
  onClick = @() emptySlotAtion(curIdx)
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    emptySquadArrow(isSquadDragged.value, sf)
    emptySquadArrow(isSquadDragged.value, sf)
  ]
}.__update(rightAppearanceAnim(animDelay)))


let squadSlotToPurchase = @(onClick, purchaseIcon = null) watchElemState(@(sf) {
  rendObj = ROBJ_BOX
  size = squadContentSize
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  borderColor = sf & S_HOVER ? hoverBdColor : defBdColor
  behavior = Behaviors.Button
  onClick
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  padding = smallPadding
  xmbNode = XmbNode()
  children = [
    purchaseIcon
    {
      rendObj = ROBJ_IMAGE
      size = [premIconSize, premIconSize]
      image = Picture("!ui/squads/plus.svg:{0}:{0}:K".subst(premIconSize))
    }
  ]
})


let function premiumSquadPrice(shopItem) {
  let { guid, curItemCost, curShopItemPrice, shop_price_curr = "",
    shop_price = 0} = shopItem

  let currencyObj = mkItemPurchaseInfo(
    currenciesList.value,
    curShopItemPrice,
    shop_price_curr,
    shop_price,
    { iconSize = priceIconSize, txtStyle = defTxtStyle }
  )

  let children = currencyObj
    ?? mkItemBarterInfo(guid, curItemCost, curCampItemsCount.value)
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), ph(40)]
    color = 0x77000000
    padding = [0, midPadding]
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    children
  }
}


let freemiumIcon = mkFreemiumXpImage(colPart(0.4)).__update({
  hplace = ALIGN_RIGHT
})

let freemiumBlock = {
  rendObj = ROBJ_SOLID
  size = [flex(), ph(35)]
  color = 0x77000000
  padding = [0, midPadding]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  children = [
    freemiumIcon
  ]
}


let mkLockedPremiumCard = kwarg(function(idx, squadId, shopItem = null, icon = "", squadType = null,
  onClick = null, animDelay = 0, premIcon = null, isInCampaign = false
) {
  let isCardSelected = Computed(@() selectedSquadId.value == squadId)
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  return watchElemState(@(sf) {
    watch = isCardSelected
    key = $"squad{idx}"
    size = squadCardSize
    behavior = Behaviors.Button
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    onClick = onClick
    xmbNode = XmbNode()
    children = [
      {
        rendObj = ROBJ_WORLD_BLUR
        size = squadContentSize
        fillColor = sf & S_HOVER ? hoverLockedSlotBgColor : defLockedSlotBgColor
        color = defItemBlur
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            padding = [bigPadding, smallPadding]
            flow = FLOW_HORIZONTAL
            children = [
              mkSquadIcon(icon)
              mkSquadInfoBlock(squadType)
            ]
          }
          mkLevelBlock(sf, isCardSelected.value)
          mkSquadPremIcon(premIcon, { size = [premIconSize, premIconSize] })
          isInCampaign
            ? freemiumBlock
            : premiumSquadPrice(shopItem)
        ]
      }
      isCardSelected.value ? selectionLine : null
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


return {
  mkDraggableSquadCard
  emptySquadSlot
  squadSlotToPurchase
  isSquadDragged
  mkLockedPremiumCard
}