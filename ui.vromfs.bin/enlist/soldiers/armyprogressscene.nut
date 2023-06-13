from "%enlSqGlob/ui_library.nut" import *

let armyUnlocksUi = require("%enlist/soldiers/armyUnlocksUi.nut")


let armyProgressScene = {
  key = "armyProgressScene"
  size = flex()
  children = armyUnlocksUi
}

return armyProgressScene
