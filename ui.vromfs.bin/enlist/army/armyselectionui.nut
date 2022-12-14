from "%enlSqGlob/ui_library.nut" import *

let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { colFull, colPart, defTxtColor, hoverTxtColor, titleTxtColor, columnGap, commonBorderRadius,
  panelBgColor, accentColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkArmyIcon, requestMoveToElem, armyMarker, armyIconSize
} = require("%enlist/army/armyPackage.nut")
let { curArmy, selectArmy, curArmiesList } = require("%enlist/soldiers/model/state.nut")

let armyBtnSize = [colFull(2) / 2, colPart(0.58)]

let function armyBtn(armyId) {
  let isSelected = Computed(@() armyId == curArmy.value)
  local wasSelected = isSelected.value
  return watchElemState(function(sf) {
    let iconOverride = {
      color = isSelected.value ? accentColor
        : sf & S_ACTIVE ? titleTxtColor
        : sf & S_HOVER ? hoverTxtColor
        : defTxtColor
    }
    if (isSelected.value)
      wasSelected = false
    return {
      watch = [curArmy, isSelected]
      rendObj = ROBJ_BOX
      borderRadius = commonBorderRadius
      behavior = [Behaviors.Button, Behaviors.RecalcHandler]
      function onClick(evt){
        if (!isSelected.value)
          requestMoveToElem(evt.target)
        selectArmy(armyId)
      }
      function onRecalcLayout(initial, elem) {
        if ((initial || !wasSelected) && isSelected.value){
          wasSelected = true
          requestMoveToElem(elem)
        }
      }
      skipDirPadNav = isSelected.value
      size = armyBtnSize
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
      children = mkArmyIcon(armyId, armyIconSize, iconOverride)
    }
  })
}

let function selectArmyByHotkey(val) {
  let armies = curArmiesList.value ?? []
  let newArmyId = armies?[val]
  if (newArmyId != null)
    selectArmy(newArmyId)
}


let armyButtonsBlock = {
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  fillColor = panelBgColor
  children = [
    armyMarker
    @() {
      watch = curArmiesList
      flow = FLOW_HORIZONTAL
      children = curArmiesList.value.map(@(armyId) armyBtn(armyId))
    }
  ]
}

let armyHotkeysBlock = {
  size = [colFull(1), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  children = [
    mkHotkey("^J:LT | A", @() selectArmyByHotkey(0))
    mkHotkey("^J:RT | D", @() selectArmyByHotkey(1))
  ]
}

let armySelectUi = {
  flow = FLOW_HORIZONTAL
  gap = columnGap
  valign = ALIGN_CENTER
  children = [
    armyButtonsBlock
    armyHotkeysBlock
  ]
}

return armySelectUi
