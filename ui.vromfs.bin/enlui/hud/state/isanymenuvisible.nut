from "%enlSqGlob/ui_library.nut" import *

let {showGameMenu} = require("%ui/hud/menus/game_menu.nut")
let {showSettingsMenu} = require("%ui/hud/menus/settings_menu.nut")
let {showControlsMenu} = require("%ui/hud/menus/controls_setup.nut")
let {showExitGameMenu, showSuicideMenu} = require("%ui/hud/menus/init_game_menu_items.nut")
let {needSpawnMenu} = require("%ui/hud/state/respawnState.nut")

return Computed(@() showGameMenu.value
  || showSettingsMenu.value
  || showControlsMenu.value
  || showSuicideMenu.value
  || showExitGameMenu.value
  || needSpawnMenu.value)