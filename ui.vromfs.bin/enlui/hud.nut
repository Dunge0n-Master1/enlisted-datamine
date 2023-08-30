from "%enlSqGlob/ui_library.nut" import *

let {inspectorRoot} = require("%darg/helpers/inspector.nut")
let {lastActiveControlsType} = require("%ui/control/active_controls.nut")
let {showSettingsMenu, mkSettingsMenuUi} = require("%ui/hud/menus/settings_menu.nut")
let {gameMenu, showGameMenu} = require("%ui/hud/menus/game_menu.nut")
let {menusUi} = require("%ui/hud/ct_hud_menus.nut")
let { mkHudElement, HUD_FLAGS, hudFlags } = require("%ui/hud/state/hudFlagsState.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let hud_under = require("%ui/hud/hud_under.nut")
let {crosshairOverheat, crosshairReload, crosshairHitmarks, crosshairForbidden, crosshairOverlayTransparency, crosshair}
  = require("%ui/hud/huds/crosshair.nut")
let crosshairImmunity = require("%ui/hud/huds/immunity_crosshair.nut")
let turretCrosshair = require("%ui/hud/huds/enlisted_turret_crosshair.nut")
let vehicleCrosshair = require("%ui/hud/huds/vehicle_crosshair.nut")
let forestall = require("%ui/hud/huds/forestall.ui.nut")
let killMarks = require("%ui/hud/huds/kill_marks.nut")
let {posHitMarks} = require("%ui/hud/huds/hit_marks.nut")
let zonePointers = require("%ui/hud/huds/zone_pointers.nut")
let resupplyPointers = require("%ui/hud/huds/resupply_pointers.nut")
let landingPointers = require("%ui/hud/huds/aircraft_respawn_landing_pointers.nut")
let respawn = require("%ui/hud/menus/respawn.nut")

let all_tips = require("%ui/hud/huds/tips/all_tips.nut")
let hudLayout = require("%ui/hud/hud_layout.nut")
let replayHudLayout = require("%ui/hud/replay/replay_hud_layout.nut")

let network_error = require("%ui/hud/huds/tips/network_error.nut")
let perfStats = require("%ui/hud/huds/perf_stats.nut")
let tutorialZonePointers = require("%ui/hud/tutorial/huds/tutorial_zone_pointers.nut")

hudFlags.subscribe(@(v) showPlayerHuds((v & HUD_FLAGS.PLAYER) == HUD_FLAGS.PLAYER))
showPlayerHuds((hudFlags.value & HUD_FLAGS.PLAYER) == HUD_FLAGS.PLAYER)


let HUD_ELEMENTS = [
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = zonePointers }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL | HUD_FLAGS.SQUAD_SPAWN, comp = zonePointers }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.TUTORIAL, comp = tutorialZonePointers }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = resupplyPointers }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = landingPointers }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = hud_under }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = hud_under }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.SHOW_TIPS, comp = all_tips }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = hudLayout }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = hudLayout }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = forestall }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = crosshairImmunity }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = killMarks }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = posHitMarks }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER, comp = turretCrosshair }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.TUTORIAL | HUD_FLAGS.VEHICLE_CROSSHAIR, comp = vehicleCrosshair }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.NO_TUTORIAL, comp = vehicleCrosshair }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.NO_REPLAY, comp = respawn }
  { flags = HUD_FLAGS.REPLAY, comp = replayHudLayout }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER, comp = crosshairForbidden }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.PLAYER_UI, comp = crosshairOverheat }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.PLAYER_UI, comp = crosshairReload }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.FULL, comp = crosshairHitmarks }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.PLAYER_UI, comp = crosshairOverlayTransparency }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.PLAYER | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = crosshair }

  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = network_error }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.FULL, comp = perfStats }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = network_error }
  { flags = HUD_FLAGS.GAME_HUD | HUD_FLAGS.MINIMAL, comp = perfStats }
]

let hud = @() {
  watch = hudFlags
  size = flex()
  children = HUD_ELEMENTS.map(mkHudElement)
}

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
  return {
    size = flex()
    children = [hud, menusUi, gameMenus, inspectorRoot]
    watch = [lastActiveControlsType]
  }
}

return HudRoot
