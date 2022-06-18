from "%enlSqGlob/ui_library.nut" import *

let {setInteractiveElement} = require("%ui/hud/state/interactive_state.nut")
let mkPieMenu = require("%ui/components/mkPieMenu.nut")
let {
  showSquadSoldiersMenu, squadSoldiersMenuItems, radius, elemSize
} = require("%ui/hud/state/squad_soldiers_menu_state.nut")

showSquadSoldiersMenu.subscribe(@(val) setInteractiveElement("SquadSoldiersMenu", val))

let squadSoldiersMenu = mkPieMenu({
  actions = squadSoldiersMenuItems,
  showPieMenu = showSquadSoldiersMenu
  radius = radius,
  elemSize = elemSize,
  close = @() showSquadSoldiersMenu(false)
})

return {
  size = flex()
  children = squadSoldiersMenu
  key = "squadSoldiersMenuTabs"
}
