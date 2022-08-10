from "%enlSqGlob/ui_library.nut" import *

let {inspectorRoot} = require("%darg/helpers/inspector.nut")
let {lastActiveControlsType} = require("%ui/control/active_controls.nut")
let {gameHudGen, getGameHud}  = require("%ui/hud/state/gameHuds.nut")
let {showSettingsMenu, mkSettingsMenuUi} = require("%ui/hud/menus/settings_menu.nut")

let {gameMenu, showGameMenu} = require("%ui/hud/menus/game_menu.nut")

let settingsMenuUi = mkSettingsMenuUi({
  onClose = @() showSettingsMenu(false)
})

let {controlsMenuUi, showControlsMenu} = require("%ui/hud/menus/controls_setup.nut")

let voteToKickMenu = require("%ui/hud/huds/vote_kick_menu.ui.nut")

let function gameMenus(){
  local children
  if (showGameMenu.value)
    children = [gameMenu, voteToKickMenu]
  else if (showSettingsMenu.value)
    children = settingsMenuUi
  else if (showControlsMenu.value)
    children = controlsMenuUi

  return {
    size = flex()
    children = children
    eventHandlers = {["HUD.GameMenu"] = @(_event) showGameMenu(!showGameMenu.value)}
    watch = [showSettingsMenu, showControlsMenu,
      showGameMenu]
  }
}

let function HudRoot() {
  let children = [].extend(getGameHud()  ?? []).append(gameMenus, inspectorRoot)

  return {
    size = flex()
    children = children
    watch = [lastActiveControlsType, gameHudGen]
  }
}

return HudRoot
