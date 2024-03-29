from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { bigPadding, smallPadding, textBgBlurColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let defcomps = require("%enlSqGlob/ui/defcomps.nut")
let { Flat, PrimaryFlat } = require("%ui/components/textButton.nut")
let { statusIconLocked, statusIconBlocked, hintText
} = require("%enlSqGlob/ui/itemPkg.nut")
let { viewVehicle, selectVehicle, selectedVehicle, selectVehParams,
  CAN_USE, LOCKED, CANT_USE, AVAILABLE_AT_CAMPAIGN, CAN_PURCHASE,
  CAN_RECEIVE_BY_ARMY_LEVEL, vehicleClear
} = require("vehiclesListState.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { focusResearch, findResearchUpgradeUnlock
} = require("%enlist/researches/researchesFocus.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { mkViewItemDetails } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { scrollToCampaignLvl } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let spinner = require("%ui/components/spinner.nut")
let { isItemActionInProgress } = require("%enlist/soldiers/model/itemActions.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { canModifyItems, mkItemUpgradeData, mkItemDisposeData
} = require("%enlist/soldiers/model/mkItemModifyData.nut")
let { markSeenUpgrades, curUnseenAvailableUpgrades, isUpgradeUsed
} = require("%enlist/soldiers/model/unseenUpgrades.nut")
let { curUpgradeDiscount, campPresentation } = require("%enlist/campaigns/campaignConfig.nut")
let { setTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let { openUpgradeItemMsg, openDisposeItemMsg
} = require("%enlist/soldiers/components/modifyItemComp.nut")
let { getShopItemsCmp, curArmyShopItems, openAndHighlightItems
} = require("%enlist/shop/armyShopState.nut")
let { isDmViewerEnabled } = require("%enlist/vehicles/dmViewer.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { inventoryItemDetailsWidth } = require("%enlSqGlob/ui/designConst.nut")

let unseenIcon = blinkUnseenIcon(0.8).__update({ hplace = ALIGN_RIGHT })
let waitingSpinner = spinner(hdpx(25))

let function txt(text) {
  return type(text) == "string"
    ? defcomps.txt({text}.__update(fontSub))
    : defcomps.txt(text)
}

let mkStatusRow = @(text, icon) {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [smallPadding, 0]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    hintText(text)
    icon
  ]
}

let vehicleStatusRow = @(item) item == null || item.status.flags == CAN_USE ? null
  : mkStatusRow(item.status?.statusText ?? "",
      (item.status.flags & (LOCKED | CANT_USE)) ? statusIconLocked : statusIconBlocked)

let backButton = Flat(loc("mainmenu/btnBack"), vehicleClear,
  { margin = [0, bigPadding, 0, 0] })

let openResearchUpgradeMsgbox = function(item, armyId) {
  let research = findResearchUpgradeUnlock(armyId, item)
  if (research == null)
    showMsgbox({
      text = loc("itemUpgradeNoSquad")
      buttons = [
        {
          text = loc("squads/gotoUnlockBtn")
          action = jumpToArmyProgress
          isCurrent = true
        }
        { text = loc("Ok"), isCancel = true }
      ]
    })
  else
    showMsgbox({
      text = loc("itemUpgradeResearch")
      buttons = [
        {
          text = loc("mainmenu/btnResearch")
          action = function() {
            focusResearch(research)
          }
          isCurrent = true
          customStyle = { hotkeys = [["^J:X" ]] }
        }
        { text = loc("Close"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B}" ]] } }
      ]
    })
}

let function mkUpgradeBtn(item) {
  let upgradeDataWatch = mkItemUpgradeData(item)
  return function() {
    let res = {
      watch = [upgradeDataWatch, curUnseenAvailableUpgrades, isUpgradeUsed,
        curUpgradeDiscount, campPresentation]
    }
    let upgradeData = upgradeDataWatch.value
    if (!upgradeData.isUpgradable)
      return res

    res.margin <- [0, bigPadding, 0, 0]
    let { isResearchRequired, armyId, hasEnoughOrders, upgradeMult, itemBaseTpl } = upgradeData

    if (isResearchRequired)
      return res.__update({
        children = Flat(loc("btn/upgrade"), @() openResearchUpgradeMsgbox(item, armyId), {
          margin = 0
          cursor = normalTooltipTop
          onHover = @(on) setTooltip(on ? loc("tip/btnUpgradeVehicle") : null)
          hotkeys = [["^J:X"]]
        })
      })

    let discount = round_by_value(100 - upgradeMult * 100, 1).tointeger()
    let bCtor = hasEnoughOrders ? PrimaryFlat : Flat
    let upgradeMultInfo = upgradeMult == 1.0 ? null
      : txt({
          text = loc("upgradeDiscount", { discount })
          color = activeTxtColor
        }).__update(curUpgradeDiscount.value > 0.0 ? {
          rendObj = ROBJ_SOLID
          color = campPresentation.value?.darkColor
        } : {})
    return res.__update({
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        upgradeMultInfo
        {
          children = [
            bCtor(loc("btn/upgrade"),
              @() openUpgradeItemMsg(item, upgradeData), {
                margin = 0
                cursor = normalTooltipTop
                onHover = function(on) {
                  if (!isUpgradeUsed.value && item?.basetpl in curUnseenAvailableUpgrades.value)
                    hoverHoldAction("unseenUpdate", itemBaseTpl,
                      @(tpl) markSeenUpgrades(selectVehParams.value?.armyId, [tpl]))(on)
                  setTooltip(on ? loc("tip/btnUpgrade") : null)
                }
                hotkeys = [["^J:X"]]
              })
            !isUpgradeUsed.value && item?.basetpl in curUnseenAvailableUpgrades.value
              ? unseenIcon
              : null
          ]
        }
      ]
    })
  }
}

let function mkDisposeBtn(item) {
  let disposeDataWatch = mkItemDisposeData(item)
  return function() {
    let res = { watch = [disposeDataWatch] }
    let disposeData = disposeDataWatch.value
    if (!disposeData.isDisposable)
      return res

    res.margin <- [0, bigPadding, 0, 0]
    let { disposeMult, isDestructible = false, isRecyclable = false } = disposeData

    let bCtor = Flat
    let bonus = round_by_value(disposeMult * 100 - 100, 1).tointeger()
    let disposeMultInfo = disposeMult == 1.0 ? null : txt({
      text = loc("disposeBonus", { bonus })
      color = activeTxtColor
    })
    return res.__update({
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        disposeMultInfo
        bCtor(loc(isRecyclable ? "btn/recycle" : isDestructible ? "btn/dispose" : "btn/downgrade"),
          @() openDisposeItemMsg(item, disposeData), {
            margin = 0
            cursor = normalTooltipTop
            onHover = @(on)
              setTooltip(on ? loc(isRecyclable ? "tip/btnRecycle"
                  : isDestructible ? "tip/btnDispose"
                  : "tip/btnDowngrade")
                : null)
          })
      ]
    })
  }
}

let function mkChooseButton(curVehicle, selVehicle) {
  if (curVehicle.basetpl == selVehicle.basetpl || curVehicle == null)
    return null

  let { status } = curVehicle
  let { flags = 0 } = status
  if (flags == CAN_USE)
    return PrimaryFlat(loc("mainmenu/btnSelect"), @()
      selectVehicle(curVehicle), {
        margin = [0, bigPadding, 0, 0]
        hotkeys = [[ "^J:Y" ]]
      })

  if (flags & CAN_PURCHASE) {
    let { basetpl } = curVehicle
    let shopItemsCmp = getShopItemsCmp(basetpl)
    return Flat(loc("GoToShop"),
      @() openAndHighlightItems(shopItemsCmp.value, curArmyShopItems.value),
      { margin = [0, bigPadding, 0, 0], hotkeys = [[ "^J:Y" ]] }
    )
  }

  if (flags & LOCKED)
    return !(flags & (CAN_RECEIVE_BY_ARMY_LEVEL | AVAILABLE_AT_CAMPAIGN)) ? null
      : Flat(loc("GoToArmyLeveling"),
          function() {
            scrollToCampaignLvl(status?.levelLimit)
            jumpToArmyProgress()
          },
          { margin = [0, bigPadding, 0, 0], hotkeys = [[ "^J:Y" ]] })

  return null
}

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "vehicleDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "vehicleDetailsAnim"}
]

let manageButtons = @() {
  watch = [viewVehicle, canModifyItems, selectedVehicle, isGamepad]
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = bigPadding
  children = {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = textBgBlurColor
    flow = FLOW_HORIZONTAL
    padding = [bigPadding, 0, bigPadding, bigPadding]
    valign = ALIGN_BOTTOM
    children = isItemActionInProgress.value
      ? [waitingSpinner]
      : [
          mkUpgradeBtn(viewVehicle.value)
          mkDisposeBtn(viewVehicle.value)
          mkChooseButton(viewVehicle.value, selectedVehicle.value)
        ]
      .append(isGamepad.value
        ? null
        : backButton)
  }
}

local lastVehicleTpl = null
return function() {
  let res = { watch = [ viewVehicle, isDmViewerEnabled] }
  let vehicle = viewVehicle.value
  if (vehicle == null)
    return res

  if (lastVehicleTpl != vehicle?.basetpl) {
    lastVehicleTpl = vehicle?.basetpl
    anim_start("vehicleDetailsAnim")
  }
  return res.__update({
    size = [inventoryItemDetailsWidth, flex()]
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    transform = {}
    animations = animations
    children = !isDmViewerEnabled.value
      ? [
          {
          size = flex()
          flow = FLOW_VERTICAL
          valign = ALIGN_BOTTOM
          gap = bigPadding
          children = [
            mkViewItemDetails(viewVehicle.value)
            vehicleStatusRow(vehicle)
          ]
        }
        manageButtons
      ]
      : manageButtons
  })
}


