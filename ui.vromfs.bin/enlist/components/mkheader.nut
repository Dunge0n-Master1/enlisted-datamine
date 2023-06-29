from "%enlSqGlob/ui_library.nut" import *

let { navHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { windowsInterval } = require("%enlSqGlob/ui/viewConst.nut")
let { sceneHeaderText } = require("%enlSqGlob/ui/defcomps.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")

let mkHeader = @(textLocId, closeButton = null, armyId = null, addToRight = null) {
  size = [flex(), navHeight]
  flow = FLOW_HORIZONTAL
  gap = fsh(1)
  valign = ALIGN_CENTER
  margin = [0, 0, windowsInterval]
  children = [
    armyId ? mkArmyIcon(armyId, hdpx(46)) : null
    textLocId.len() > 0 ? sceneHeaderText(loc(textLocId)) : null
    { size = flex() }
    addToRight
    closeButton
  ]
}

return kwarg(mkHeader)
