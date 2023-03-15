from "%enlSqGlob/ui_library.nut" import *

let soldierEquipUi = require("soldierEquipUi.nut")
let soldierPerksUi = require("soldierPerks.ui.nut")
let mkSoldierCustomisationTab = require("mkSoldierCustomisationTab.nut")
let soldierLookUi = require("soldierLook.ui.nut")
let faComp = require("%ui/components/faComp.nut")

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let canSwitchSoldierLook = hasClientPermission("debug_soldier_look")

let {
  colFull, colPart, columnGap, bigPadding, defTxtColor, titleTxtColor,
  accentColor, smallPadding, panelBgColor, activeTabBgImg
} = require("%enlSqGlob/ui/designConst.nut")


let tabHeight = colPart(1)
let equipBlockWidth = colFull(5)


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontMedium)

let defIconStyle = { fontSize = hdpx(15), color = defTxtColor }
let hoverIconStyle = { fontSize = hdpx(15), color = titleTxtColor }


let soldierTabsData = {
  weaponry = {
    locId = "soldierWeaponry"
    content = soldierEquipUi // TODO: need to insert new designed UI
  }
  perks = {
    locId = "soldierPerks"
    content = soldierPerksUi // TODO: need to insert new designed UI
  }
  customize = {
    iconId = "pencil"
    content = mkSoldierCustomisationTab // TODO: need to insert new designed UI
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

let activePageSlotOverride = {
  rendObj = ROBJ_IMAGE
  image = activeTabBgImg
}

let selectedPageSlotLine = {
  size = [flex(), smallPadding]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_SOLID
  color = accentColor
}

let mkTabsListUi = @(availTabs) @() {
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
        let textStyle = isHover || isSelectedVal ? hoverTxtStyle : defTxtStyle
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
                key = $"tab_{id}_(isSelectedVal)"
                size = [SIZE_TO_CONTENT, flex()]
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = tabTextObj
              }.__update(isSelectedVal || isHover ? activePageSlotOverride : idlePageSlotOverride)
              isSelectedVal ? selectedPageSlotLine : null
            ]
          }
        }
      })
    })
}


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
        mkTabsListUi(availTabs)
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
