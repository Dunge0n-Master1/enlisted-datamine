import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let hudLayoutState = require("%ui/hud/state/hud_layout_state.nut")
let textButton = require("%ui/components/textButton.nut")
let console = require("console")
let camera = require("camera")
let cursors = require("%ui/style/cursors.nut")
let fa = require("%darg/components/fontawesome.map.nut")

let { blurBgFillColor, blurBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let { h2_txt, body_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let { replayCurTime, replayPlayTime, replayTimeSpeed, canShowReplayHud } = require("replayState.nut")
let { format } = require("string")
let { NextReplayTarget } = require("dasevents")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { setInteractiveElement } = require("%ui/hud/state/interactive_state.nut")
let { localPlayerName } = require("%ui/hud/state/local_player.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")

let timeSpeedVariants = [0, 0.1, 0.25, 0.5, 1, 1.5, 2, 3, 4]

let function timeSpeedInscrese(curTimeSpeed) {
  foreach(timeSpeed in timeSpeedVariants)
    if (curTimeSpeed < timeSpeed) {
      console.command($"app.timeSpeed {timeSpeed}")
      return
    }
}

let function timeSpeedDecrese(curTimeSpeed) {
  for (local i = timeSpeedVariants.len() - 1; i >= 0; --i)
    if (curTimeSpeed > timeSpeedVariants[i]) {
      console.command($"app.timeSpeed {timeSpeedVariants[i]}")
      return
    }
}

let replayTiming = @() {
  watch = [replayCurTime, replayPlayTime]
  flow = FLOW_VERTICAL
  padding = [fsh(1), fsh(1), fsh(2)]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = $"{secondsToStringLoc(replayCurTime.value)} | {secondsToStringLoc(replayPlayTime.value)}"
      color = Color(255,255,255)
    }.__update(h2_txt)
  ]
}

let replayTimeControl = @() {
  watch = [replayTimeSpeed]
  flow = FLOW_HORIZONTAL
  children = [
    replayTimeSpeed.value <= 0
      ? textButton(fa["play"], @() console.command("app.timeSpeed 1"), fontawesome)
      : textButton(fa["pause"], @() console.command("app.timeSpeed 0"), fontawesome)
    textButton(fa["fast-backward"], @() timeSpeedDecrese(replayTimeSpeed.value), fontawesome)
    {
      rendObj = ROBJ_TEXT
      text = format("x%.2f", replayTimeSpeed.value)
      padding = [hdpx(20), 0]
      color = Color(255,255,255)
    }.__update(h2_txt)
    textButton(fa["fast-forward"], @() timeSpeedInscrese(replayTimeSpeed.value), fontawesome)
  ]
}

let replayPlayerControl = {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  size = flex()
  children = [
    textButton(
      loc("Prev Player"),
      @() ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(), NextReplayTarget({delta=-1}))
    )
    textButton(
      loc("Next Player"),
      @() ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(), NextReplayTarget({delta=1}))
    )
  ]
}

let replayCameraControl = @() {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  size = flex()
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("CAMERA: ")
      padding = [fsh(2), 0]
      color = Color(255,255,255)
    }.__update(h2_txt)
    textButton("FPS", @() console.command("replay.fps_camera"), {})
    textButton("TPS", @() console.command("replay.tps_camera"), {})
    textButton("Free TPS", @() console.command("replay.tps_free_camera"), {})
  ]
}

let replayControl = {
  flow = FLOW_HORIZONTAL
  size = flex()
  children = [
    {
      flow = FLOW_VERTICAL
      size = flex()
      children = [
        replayTiming
        replayTimeControl
      ]
    }
    {
      flow = FLOW_VERTICAL
      size = flex()
      children = [
        replayPlayerControl
        replayCameraControl
      ]
    }
  ]
}

let replayTargetName = @() {
  watch = localPlayerName
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  size = flex()
  children = [
    {
      rendObj = ROBJ_TEXT
      text = localPlayerName.value
      color = Color(255,255,255)
    }.__update(h2_txt)
  ]
}

let replayBottomPlayMenu = {
  cursor = cursors.normal
  size = [sw(100), hdpx(200)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = [hdpx(30), hdpx(30), 0, hdpx(30)]
  children = replayControl
}

let replayHideHudHint = {
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = txt({
      text = loc("F6 disable/enable HUD")
      color = Color(255,255,255)
    }.__update(body_txt))
}

canShowReplayHud.subscribe(@(val) setInteractiveElement("ReplayHud", val))

return function() {
  setInteractiveElement("ReplayHud", true)
  hudLayoutState.centerPanelTop([replayHideHudHint])
  hudLayoutState.centerPanelBottom([replayBottomPlayMenu])


  hudLayoutState.leftPanelTop([])
  hudLayoutState.leftPanelMiddle([])
  hudLayoutState.leftPanelBottom([])
  hudLayoutState.centerPanelMiddle([])
  hudLayoutState.rightPanelTop([])
  hudLayoutState.rightPanelMiddle([])
  hudLayoutState.rightPanelBottom([replayTargetName])
}

