from "%enlSqGlob/ui_library.nut" import *

let { isMainMenuVisible } = require("%enlist/mainMenu/sectionsState.nut")
let { hasMsgBoxes } = require("%enlist/components/msgbox.nut")
let { hasModalWindows } = require("%ui/components/modalWindows.nut")


let canDisplay = Computed(@() isMainMenuVisible.value
  && !hasMsgBoxes.value
  && !hasModalWindows.value)

return canDisplay
