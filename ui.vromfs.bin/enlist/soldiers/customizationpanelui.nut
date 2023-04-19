from "%enlSqGlob/ui_library.nut" import *

let icon3dByGameTemplate = require("%enlSqGlob/ui/icon3dByGameTemplate.nut")

let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let {
  blockOnClick, availableCItem, currentItemPart
} = require("soldierCustomizationState.nut")
let {
  midPadding, colFull, colPart, columnGap, leftAppearanceAnim, defSlotBgColor,
  defItemBlur, hoverSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")


let blockWidth = colFull(5)
let slotSize = [(blockWidth - midPadding) / 2, colPart(2.2)]

let itemParams = {
  width = colPart(2.2)
  height = slotSize[1] - columnGap
}

let wrapParams = {
  width = blockWidth
  hGap = midPadding
  vGap = midPadding
}


let function mkCustomizationSlot(itemToShow, idx, curPart, sInfo) {
  let { slotName, iconAttachments, itemTemplate } = itemToShow
  let { armyId = null, guid = null } = sInfo
  let isSelected = slotName == curPart
  if (armyId == null || guid == null)
    return null

  return watchElemState(@(sf) {
    key = $"{guid}_{idx}"
    size = slotSize
    behavior = Behaviors.Button
    onClick = @() blockOnClick(slotName)
    children = [
      {
        size = flex()
        rendObj = ROBJ_WORLD_BLUR
        fillColor = isSelected || (sf & S_HOVER) != 0
          ? hoverSlotBgColor
          : defSlotBgColor
        color =     defItemBlur
      }
      icon3dByGameTemplate(itemTemplate, itemParams.__merge({
        genOverride = { iconAttachments }
        shading = "same"
      }))
    ]
  }.__update(leftAppearanceAnim(idx * 0.025)))
}

let customizationUi = function() {
  let curPart = currentItemPart.value
  let sInfo = curSoldierInfo.value
  return {
    watch = [availableCItem, currentItemPart, curSoldierInfo]
    size = [flex(), SIZE_TO_CONTENT]
    children = wrap(availableCItem.value
      .map(@(item, idx) mkCustomizationSlot(item, idx, curPart, sInfo)), wrapParams
    )
  }
}

return customizationUi
