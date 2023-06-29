from "%enlSqGlob/ui_library.nut" import *

let {
  bigPadding, smallPadding, soldierWndWidth, unitSize, hoverTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { notChoosenPerkSoldiers } = require("model/soldierPerks.nut")
let soldierEquipUi = require("soldierEquip.ui.nut")
let soldierPerksUi = require("soldierPerks.ui.nut")
let mkSoldierCustomisationTab = require("mkSoldierCustomisationTab.nut")
let soldierLookUi = require("soldierLook.ui.nut")
let {
  mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let canSwitchSoldierLook = hasClientPermission("debug_soldier_look")
let mkNameBlock = require("%enlist/components/mkNameBlock.nut")
let { defTxtColor, titleTxtColor, accentColor, panelBgColor, hoverSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let { closeEquipPresets } = require("%enlist/preset/presetEquipUi.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = hoverTxtColor }.__update(fontMedium)
let activeTxtStyle = { color = titleTxtColor }.__update(fontMedium)

let defIconStyle = { fontSize = hdpx(15), color = defTxtColor }
let hoverIconStyle = { fontSize = hdpx(15), color = hoverTxtColor }
let activeIconStyle = { fontSize = hdpx(15), color = titleTxtColor }

let tabHeight = unitSize

let tabsData = {
  weaponry = {
    locId = "soldierWeaponry"
    content = soldierEquipUi
    childCtor = @(soldier) soldier == null ? null
      : mkAlertIcon(ITEM_ALERT_SIGN, Computed(@()
          (unseenSoldiersWeaponry.value?[soldier?.guid].len() ?? 0) > 0
        ))
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
    locId = "soldierAppearance"
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

curTabId.subscribe(@(_) closeEquipPresets())

let mkAnimations = @(isMoveRight) [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150) * (isMoveRight ? -1 : 1), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [hdpx(150) * (isMoveRight ? 1 : -1), 0], duration = 0.2, easing = OutQuad }
]

let selectedColor = mul_color(panelBgColor, 1.5)

let tabsList = @(soldier, availTabs) @() availTabs.len() == 1 ? null : {
  watch = [tabs, curTabId, soldier]
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  clipChildren = true
  gap = smallPadding
  children = tabs.value
    .filter(@(id) availTabs.len() == 0 || availTabs.contains(id))
    .map(function(id) {
      let tab = tabsData[id]
      let isSelected = Computed(@() curTabId.value == id)
      let size = ["locId" in tab ? flex() : tabHeight, tabHeight]
      return watchElemState(function(sf) {
        let isSelectedVal = isSelected.value
        let isHover = (sf & S_HOVER) != 0
        let textStyle = isHover ? hoverTxtStyle
          : isSelectedVal ? activeTxtStyle
          : defTxtStyle
        let iconStyle = isSelectedVal ? activeIconStyle
            : isHover ? hoverIconStyle : defIconStyle
        let tabTextObj = "locId" in tab ? {
              rendObj = ROBJ_TEXT
              text = loc(tab.locId)
            }.__update(textStyle)
          : "iconId" in tab ? faComp(tab.iconId, iconStyle)
          : null
        let fillColor = isHover ? hoverSlotBgColor
          : isSelectedVal ? selectedColor
          : panelBgColor

        return {
          size
          watch = isSelected
          rendObj = ROBJ_BOX
          behavior = Behaviors.Button
          onClick = @() curTabId(id)
          sound = {
            hover = "ui/enlist/button_highlight"
            click = "ui/enlist/button_click"
            active = "ui/enlist/button_action"
          }
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          fillColor
          borderColor = accentColor
          borderWidth = isSelectedVal ? [0, 0, hdpx(4), 0] : 0
          children = [
            tabTextObj
            {
              hplace = ALIGN_RIGHT
              vplace = ALIGN_TOP
              children = tab?.childCtor(soldier.value)
            }
          ]
        }
      })
    })
}

let content = kwarg(@(
  soldier, canManage, animations, selectedKeyWatch, mkDismissBtn,
  availTabs, onDoubleClickCb = null, onResearchClickCb = null,
  dropExceptionCb = null
) {
  size = [soldierWndWidth, flex()]
  children = {
    size = [soldierWndWidth, flex()]
    flow = FLOW_VERTICAL
    gap = bigPadding
    animations
    transform = {}
    children = [
      mkNameBlock(soldier)
      tabsList(soldier, availTabs)
      @() {
        watch = curTabId
        size = flex()
        children = getTabById(curTabId.value).content({
          soldier
          canManage
          selectedKeyWatch
          onDoubleClickCb
          dropExceptionCb
          onResearchClickCb
        }, KWARG_NON_STRICT)
      }
      @() {
        watch = soldier
        size = [flex(), SIZE_TO_CONTENT]
        children = mkDismissBtn(soldier.value)
      }
    ]
  }
})

return kwarg(function(
  soldierInfoWatch, isMoveRight = true, selectedKeyWatch = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, mkDismissBtn = @(_) null,
  dropExceptionCb = null, availTabs = []
) {
  let animations = mkAnimations(isMoveRight)
  local lastSoldierGuid = soldierInfoWatch.value?.guid

  let children = content({
    soldier = soldierInfoWatch
    canManage = true
    animations
    selectedKeyWatch
    onDoubleClickCb
    dropExceptionCb
    onResearchClickCb
    mkDismissBtn
    availTabs
  })

  return function() {
    let newSoldierGuid = soldierInfoWatch.value?.guid
    if (lastSoldierGuid != null && newSoldierGuid != lastSoldierGuid)
      anim_start("hdrAnim") //no need change content anim when window appear anim playing
    lastSoldierGuid = newSoldierGuid

    return {
      watch = soldierInfoWatch
      size = soldierInfoWatch.value != null ? [soldierWndWidth, flex()] : null
      children = soldierInfoWatch.value != null ? children : null
    }
  }
})