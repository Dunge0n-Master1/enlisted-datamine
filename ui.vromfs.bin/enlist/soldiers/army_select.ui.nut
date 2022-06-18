from "%enlSqGlob/ui_library.nut" import *

let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { gap, bigGap, activeTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { mkArmyBack, mkArmyIcon, mkArmyName } = require("components/armyPackage.nut")
let { allArmiesInfo } = require("model/config/gameProfile.nut")
let { curArmy, selectArmy, curArmiesList } = require("model/state.nut")

let armyBtn = kwarg(function (armyId, hasBackImage = false, addChild = null) {
  let function builder(sf) {
    let isSelected = armyId == curArmy.value
    return {
      rendObj = ROBJ_BOX
      watch = [curArmy, allArmiesInfo]
      borderWidth = (isSelected || (sf & S_HOVER)) ? [0, 0, hdpx(4), 0] : 0
      children = [
        hasBackImage ? mkArmyBack(armyId) : null
        {
          flow = FLOW_HORIZONTAL
          gap = gap
          padding = bigGap
          vplace = ALIGN_BOTTOM
          children = [
            mkArmyIcon(armyId)
            mkArmyName(armyId, isSelected, sf)
          ]
        }
        addChild?(armyId, sf)
      ]
    }.__update(isSelected ? {} : {
      behavior = Behaviors.Button
      skipDirPadNav = true
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
      onClick = @() selectArmy(armyId)
    })
  }
  return watchElemState(builder)
})

let function selectArmyByGamepad(val) {
  let armies = curArmiesList.value ?? []
  let newArmyId = armies?[val]
  if (newArmyId != null)
    selectArmy(newArmyId)
}

let function armySelect(hasHotkeys = true, addChild = null, hasBackImage = false, override = {}, customGap = null) {
  let res = function() {
    let children = curArmiesList.value
      .map(@(armyId) armyBtn({
        armyId
        hasBackImage
        addChild
      }))
    return {
      watch = curArmiesList
      flow = FLOW_HORIZONTAL
      gap = customGap ?? {
        rendObj = ROBJ_TEXT
        text = loc("mainmenu/versus_short")
        vplace = ALIGN_BOTTOM
        margin = hdpx(20)
        color = activeTitleTxtColor
      }
      children = children.len() > 1 ? children : null
    }.__update(override)
  }
  if (!hasHotkeys)
    return res

  let tb = @(key, val) @() {
    children = mkHotkey(key, @() selectArmyByGamepad(val))
    isHidden = !isGamepad.value
    watch = [isGamepad, curArmiesList]
    size = SIZE_TO_CONTENT
  }
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      tb("^J:LT", 0)
      res
      tb("^J:RT", 1)
    ]
  }
}

return kwarg(armySelect)
