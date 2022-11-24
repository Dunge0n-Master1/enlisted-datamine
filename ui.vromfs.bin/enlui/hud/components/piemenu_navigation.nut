import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {
  radius, pieMenuLayer, showPieMenu
} = require("%ui/hud/state/pie_menu_state.nut")
let { canUseWallposter } = require("%ui/hud/state/wallposters_use_state.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { CmdWallposterPreview } = require("dasevents")
let { wallPostersMaxCount, wallPostersCurCount, wallPosters } = require("%ui/hud/state/wallposter.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { TextActive } = require("%ui/style/colors.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")


let noWallposterAvailable = Computed(@() !canUseWallposter.value
  || wallPostersMaxCount.value == 0
  || wallPostersCurCount.value >= wallPostersMaxCount.value)

let function wallposterNavClick() {
  if (pieMenuLayer.value == 0) {
    pieMenuLayer(1)
    return
  }
  if (noWallposterAvailable.value)
    return

  if (wallPosters.value.len() == 1) {
    ecs.g_entity_mgr.sendEvent(
      localPlayerEid.value, CmdWallposterPreview({enable=true, wallPosterId=0}))
    showPieMenu(false)
  }
  else
    pieMenuLayer(0)
}

let wallposterNavText = Computed(@() pieMenuLayer.value == 0 ? loc("piemenu/squad_commands")
  : !canUseWallposter.value ? loc("wallposter/cant_use")
  : wallPostersMaxCount.value == 0
    || wallPostersCurCount.value >= wallPostersMaxCount.value ? loc("wallposter/nomore")
  : wallPostersMaxCount.value == 1 ? loc("wallposter/place")
  : loc("piemenu/wallposters"))


let wallposterNavigationHint = [
  mkHotkey("J:X | Q", wallposterNavClick)
  @() {
    rendObj = ROBJ_TEXT
    watch = wallposterNavText
    text = wallposterNavText.value
    color = TextActive
  }.__update(body_txt)
]


let quickchatNavClick = @() pieMenuLayer(pieMenuLayer.value == 2 ? 1 : 2)

let quickchatNavigationHint = [
  mkHotkey("J:Y | E", quickchatNavClick)
  @() {
    rendObj = ROBJ_TEXT
    watch = pieMenuLayer
    text = pieMenuLayer.value == 2 ? loc("piemenu/squad_commands") : loc("piemenu/quick_chat")
    color = TextActive
  }.__update(body_txt)
]


let mkPieMenuNavigationTip = @(action, children, isInactive = Watched(false)) watchElemState(@(sf) {
  watch = isInactive
  behavior = isGamepad.value ? null : Behaviors.Button
  rendObj = ROBJ_WORLD_BLUR
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(6)
  padding = [hdpx(3), hdpx(9)]
  color = (sf & S_HOVER) && !isInactive.value ? Color(220,220,220) : Color(240,240,240)
  onClick = action
  stopMouse = true
  children
})


let pieMenuNavigation = {
  watch = radius
  size = [radius.value * 2, 0]
  pos = [0, radius.value + hdpx(10)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = [
    {
      size = [pw(50), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      children = mkPieMenuNavigationTip(wallposterNavClick, wallposterNavigationHint, noWallposterAvailable)
    }
    {
      size = [pw(50), SIZE_TO_CONTENT]
      halign = ALIGN_LEFT
      children = mkPieMenuNavigationTip(quickchatNavClick, quickchatNavigationHint)
    }
  ]
}

return {
  pieMenuNavigation
}