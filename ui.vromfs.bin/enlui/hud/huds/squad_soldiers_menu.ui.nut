from "%enlSqGlob/ui_library.nut" import *

let mkPieMenu = require("%ui/components/mkPieMenuHoldable.nut")
let {
  showSquadSoldiersMenu, squadSoldiersMenuItems, radius, elemSize
} = require("%ui/hud/state/squad_soldiers_menu_state.nut")
let { changeBehaviour, changeFormation } = require("%ui/hud/components/squad_behavior.nut")


let squadSoldiersMenu = mkPieMenu({
  actions = squadSoldiersMenuItems,
  showPieMenu = showSquadSoldiersMenu
  radius = radius,
  elemSize = elemSize
})

let squadBehaviorPanel = @() {
  watch = radius
  size = [radius.value * 2, 0]
  pos = [radius.value * 2 + hdpx(10), hdpx(90)]
  children = {
    stopMouse = true
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    padding = hdpx(5)
    children = [
      changeFormation
      changeBehaviour
    ]
  }
}

return {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    squadSoldiersMenu
    squadBehaviorPanel
  ]
  key = "squadSoldiersMenuTabs"
}
