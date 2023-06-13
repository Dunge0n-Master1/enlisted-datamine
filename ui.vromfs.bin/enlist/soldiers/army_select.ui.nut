from "%enlSqGlob/ui_library.nut" import *

let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { bigPadding, hoverSlotBgColor, miniPadding, panelBgColor, accentColor } = require("%enlSqGlob/ui/designConst.nut")
let { mkArmyIcon, mkArmySimpleIcon } = require("components/armyPackage.nut")
let { allArmiesInfo } = require("model/config/gameProfile.nut")
let { curArmy, selectArmy, curArmiesList } = require("model/state.nut")
let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")


let colorGray = Color(30, 44, 52)
let sizeIcon = hdpx(26)
let showNameArmy =  Computed(@() curArmiesList.value.len() > 2)
let selectedColor = mul_color(panelBgColor, 1.25)

let sound = freeze({
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
})
let function armyBtn(armyId) {
  let isSelected = Computed(@() armyId == curArmy.value)
  let onClick = @() selectArmy(armyId)
  let icon = mkArmyIcon(armyId, sizeIcon, {margin = 0})
  let function builder(sf) {
    let colorIcon = (sf & S_HOVER) && !isSelected.value
      ? colorGray
      : hoverSlotBgColor

    return {
      rendObj = ROBJ_BOX
      watch = [isSelected, showNameArmy]
      borderWidth = isSelected.value ? [0, 0, hdpx(2), 0] : 0
      borderColor = accentColor
      fillColor = (sf & S_HOVER)
        ? hoverSlotBgColor
        : isSelected.value ? selectedColor : panelBgColor
      behavior = Behaviors.Button
      skipDirPadNav = true
      sound
      onClick
      children = {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        padding = showNameArmy.value ? [hdpx(6), hdpx(14)] : [hdpx(6), hdpx(22)]
        vplace = ALIGN_BOTTOM
        children = isSelected.value
          ? icon
          : mkArmySimpleIcon(armyId, sizeIcon, {
              color = colorIcon
              margin = 0
            })
      }
    }
  }
  return watchElemState(builder)
}

let function switchArmy(delta) {
  let armies = curArmiesList.value ?? []
  let curArmyIdx = armies.indexof(curArmy.value) ?? 0
  let newArmyId = armies?[curArmyIdx + delta]
  if (newArmyId != null)
    selectArmy(newArmyId)
}

let tb = @(key, val, params) @() {
  watch = [isGamepad, curArmiesList]
  isHidden = !isGamepad.value
  children = mkHotkey(key, @() switchArmy(val))
}.__update(params)

let armySelectButtons = {
  valign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  children = [
    function() {
      let children = curArmiesList.value
        .map(@(armyId) armyBtn(armyId))
      return {
        watch = curArmiesList
        flow = FLOW_HORIZONTAL
        children = children.len() > 1 ? children : null
      }
    }
    tb("^J:LT", -1, { pos = [-hdpx(15), 0] })
    tb("^J:RT", 1, { hplace = ALIGN_RIGHT, pos = [hdpx(15), 0] })
  ]
}

let mkUpperText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = Color(179, 189, 193)
  text = utf8ToUpper(text)
}.__update(override)

let armySelectText = @() {
  watch = [curArmy, showNameArmy, allArmiesInfo]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  rendObj = ROBJ_BOX
  children = showNameArmy.value
    ? [
        mkUpperText(loc("selected_army"), fontSmall)
        { size = flex() }
        mkUpperText(loc($"country/{allArmiesInfo.value[curArmy.value].country}"), fontSmall)
      ]
    : mkUpperText(loc("select_army"), fontSmall)
}

let armySelectUi = {
  flow = FLOW_VERTICAL
  gap = miniPadding
  children = [
    armySelectText
    armySelectButtons
  ]
}

return armySelectUi
