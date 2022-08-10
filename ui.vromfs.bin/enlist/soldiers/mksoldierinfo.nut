from "%enlSqGlob/ui_library.nut" import *

let {
  gap, bigPadding, soldierWndWidth, blurBgColor, blurBgFillColor, listBtnAirStyle
} = require("%enlSqGlob/ui/viewConst.nut")
let textButton = require("%ui/components/textButton.nut")
let { notChoosenPerkSoldiers } = require("model/soldierPerks.nut")
let soldierEquipUi = require("soldierEquip.ui.nut")
let soldierPerksUi = require("soldierPerks.ui.nut")
let mkSoldierCustomisationTab = require("mkSoldierCustomisationTab.nut")
let soldierLookUi = require("soldierLook.ui.nut")
let {
  mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { curUnseenUpgradesBySoldier, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let canSwitchSoldierLook = hasClientPermission("debug_soldier_look")
let mkNameBlock = require("%enlist/components/mkNameBlock.nut")

let tabsData = {
  weaponry = {
    locId = "soldierWeaponry"
    content = soldierEquipUi
    childCtor = @(soldier) soldier == null ? null
      : mkAlertIcon(ITEM_ALERT_SIGN, Computed(function() {
          let weapCount = unseenSoldiersWeaponry.value?[soldier?.guid].len() ?? 0
          let upgrCount = (isUpgradeUsed.value ?? false) ? 0
            : (curUnseenUpgradesBySoldier.value?[soldier?.guid] ?? 0)
          return weapCount + upgrCount > 0
        }))
  }
  perks = {
    locId = "soldierPerks"
    content = soldierPerksUi
    childCtor = @(soldier) soldier == null ? null
      : mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
          (notChoosenPerkSoldiers.value?[soldier.guid] ?? 0) > 0
        ))
  }
  customize = {
    iconId = "pencil"
    content = mkSoldierCustomisationTab
  }
  look = {
    iconId = "address-card"
    content = soldierLookUi
  }
}

let tabs = Computed(function() {
  let res = ["weaponry", "perks", "customize"]
  if (canSwitchSoldierLook.value)
    res.append("look")
  return res
})

let curTabId = mkWatched(persist, "soldierInfoTabId", tabs.value[0])
let getTabById = @(tabId) tabsData?[tabId] ?? tabsData[tabs.value[0]]

let hdrAnimations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic, trigger = "hdrAnim"}
  { prop = AnimProp.translate, from =[-hdpx(70), 0], to = [0, 0], duration = 0.15, easing = OutQuad, trigger = "hdrAnim"}
]


let mkAnimations = @(isMoveRight) [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150) * (isMoveRight ? -1 : 1), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [hdpx(150) * (isMoveRight ? 1 : -1), 0], duration = 0.2, easing = OutQuad }
]

let listBtnStyle = @(isSelected, idx)
  listBtnAirStyle(isSelected, idx).__update({ size = [flex(), SIZE_TO_CONTENT] })

let tabsList = @(soldier, availTabs) @() {
  animations = hdrAnimations
  transform = {}
  watch = [tabs, curTabId, soldier]
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = gap
  children = tabs.value
    .filter(@(id) availTabs.len() == 0 || availTabs.contains(id))
    .map(function(id, idx) {
      let tab = tabsData[id]
      let isCurrent = curTabId.value == id
      return "locId" in tab ? {
            size = [flex(), SIZE_TO_CONTENT]
            children = [
              textButton(loc(tab.locId), @() curTabId(id),
                listBtnStyle(isCurrent, idx))
              tab?.childCtor(soldier.value)
            ]
          }
        : "iconId" in tab ? {
            size = [ph(100), SIZE_TO_CONTENT]
            children = [
              textButton.FAButton(tab.iconId, @() curTabId(id),
                listBtnStyle(isCurrent, idx).__update({padding = [hdpx(13), 0, 0, 0]}))
            ]
          }
        : null
    })
}

let content = kwarg(@(
  soldier, canManage, animations, selectedKeyWatch, mkDismissBtn,
  availTabs, onDoubleClickCb = null, onResearchClickCb = null,
  getDropExceptionCb = null
) {
  clipChildren = true
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  size = [soldierWndWidth, flex()]
  animations = animations
  transform = {}
  children = {
    size = [soldierWndWidth, flex()]
    gap = bigPadding
    flow = FLOW_VERTICAL
    padding = bigPadding
    children = [
      mkNameBlock(soldier)
      tabsList(soldier, availTabs)
      @() {
        animations = hdrAnimations
        transform = {}
        watch = curTabId
        size = flex()
        children = getTabById(curTabId.value).content({
          soldier = soldier.value
          canManage
          selectedKeyWatch
          onDoubleClickCb
          getDropExceptionCb
          onResearchClickCb
        }, KWARG_NON_STRICT)
      }
      mkDismissBtn(soldier.value)
    ]
  }
})

return kwarg(function(
  soldierInfoWatch, isMoveRight = true, selectedKeyWatch = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, mkDismissBtn = @(_) null,
  getDropExceptionCb = null, availTabs = []
) {
  let animations = mkAnimations(isMoveRight)
  local lastSoldierGuid = soldierInfoWatch.value?.guid
  return function soldierInfoUi() {
    let newSoldierGuid = soldierInfoWatch.value?.guid
    if (lastSoldierGuid != null && newSoldierGuid != lastSoldierGuid)
      anim_start("hdrAnim") //no need change content anim when window appear anim playing
    lastSoldierGuid = newSoldierGuid

    return {
      watch = soldierInfoWatch
      size = soldierInfoWatch.value != null ? [soldierWndWidth, flex()] : null
      children = soldierInfoWatch.value != null ? content({
        soldier = soldierInfoWatch
        canManage = true
        animations
        selectedKeyWatch
        onDoubleClickCb
        getDropExceptionCb
        onResearchClickCb
        mkDismissBtn
        availTabs
      }) : null
    }
  }
})