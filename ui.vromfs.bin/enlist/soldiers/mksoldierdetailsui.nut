from "%enlSqGlob/ui_library.nut" import *

let soldierEquipUi = require("soldierEquipUi.nut")
let soldierPerksUi = require("soldierPerksUi.nut")
let soldierAppearanceUi = require("soldierAppearanceUi.nut")


let soldierLookUi = require("soldierLook.ui.nut")
let faComp = require("%ui/components/faComp.nut")

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let { notChoosenPerkSoldiers } = require("model/soldierPerks.nut")
let { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
let { curUnseenUpgradesBySoldier, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let canSwitchSoldierLook = hasClientPermission("debug_soldier_look")

let {
  colFull, colPart, columnGap, bigPadding, defTxtColor, titleTxtColor,
  accentColor, panelBgColor, hoverPanelBgColor, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let {
  mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")


let tabHeight = colPart(0.8)
let equipBlockWidth = colFull(5)


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let activeTxtStyle = { color = darkTxtColor }.__update(fontMedium)

let defIconStyle = { fontSize = hdpx(15), color = defTxtColor }
let hoverIconStyle = { fontSize = hdpx(15), color = titleTxtColor }


let soldierTabsData = {
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
    locId = "soldierAppearance"
    content = soldierAppearanceUi
  }
  look = {
    iconId = "address-card"
    content = soldierLookUi // TODO: need to insert new designed UI
  }
}


let soldierTabs = Computed(function() {
  let res = ["weaponry", "perks", "customize"]
  if (canSwitchSoldierLook.value)
    res.append("look")
  return res
})


let curTabId = mkWatched(persist, "soldierTabIdx", soldierTabs.value[0])
let getTabById = @(id) soldierTabsData?[id] ?? soldierTabsData[soldierTabs.value[0]]


let idlePageSlotOverride = {
  rendObj = ROBJ_SOLID
  color = panelBgColor
}


let mkTabsList = @(soldier, availTabs) @() {
  watch = [soldierTabs, curTabId]
  size = [flex(), tabHeight]
  flow = FLOW_HORIZONTAL
  children = soldierTabs.value
    .filter(@(id) availTabs.len() == 0 || availTabs.contains(id))
    .map(function(id) {
      let tab = soldierTabsData[id]
      let isSelected = Computed(@() curTabId.value == id)
      return watchElemState(function(sf) {
        let isSelectedVal = isSelected.value
        let isHover = (sf & S_HOVER) != 0
        let textStyle = isSelectedVal ? activeTxtStyle
          : isHover ? hoverTxtStyle
          : defTxtStyle
        let iconStyle = { margin = [0, bigPadding] }
          .__update(isHover || isSelectedVal ? hoverIconStyle : defIconStyle)
        let tabTextObj = "locId" in tab ? {
              margin = bigPadding
              rendObj = ROBJ_TEXT
              text = loc(tab.locId)
            }.__update(textStyle)
          : "iconId" in tab ? faComp(tab.iconId, iconStyle)
          : null

        return {
          size = [SIZE_TO_CONTENT, flex()]
          behavior = Behaviors.Button
          onClick = @() curTabId(id)
          children = @() {
            watch = isSelected
            size = [SIZE_TO_CONTENT, flex()]
            valign = ALIGN_CENTER
            children = [
              {
                rendObj = ROBJ_SOLID
                color = isSelectedVal ? accentColor
                  : isHover ? hoverPanelBgColor
                  : panelBgColor
                key = $"tab_{id}_(isSelectedVal)"
                size = [SIZE_TO_CONTENT, flex()]
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = tabTextObj
              }
              tab?.childCtor(soldier)
            ]
          }
        }
      })
    })
}.__update(idlePageSlotOverride)


let mkSoldierDetailsUi = kwarg(function(
  soldierWatch, onResearchClickCb = null, availTabs = []
) {
  return function() {
    let res = { watch = soldierWatch }
    let soldier = soldierWatch.value
    if (soldier == null)
      return res

    return res.__update({
      size = [equipBlockWidth, flex()]
      flow = FLOW_VERTICAL
      gap = columnGap
      children = [
        mkTabsList(soldier, availTabs)
        @() {
          watch = curTabId
          size = flex()
          children = getTabById(curTabId.value).content({
            soldier = soldierWatch
            onResearchClickCb
          }, KWARG_NON_STRICT)
        }
      ]
    })
  }
})


return mkSoldierDetailsUi
