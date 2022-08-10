import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let textButton = require("%ui/components/textButton.nut")
let console = require("console")
let camera = require("camera")
let cursors = require("%ui/style/cursors.nut")
let fa = require("%ui/components/fontawesome.map.nut")

let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { blurBgFillColor, blurBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let { h2_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let { replayCurTime, replayPlayTime, replayTimeSpeed, canShowReplayHud,
  isFreeTpsMode } = require("replayState.nut")
let { format } = require("string")
let { NextReplayTarget, ReplaySetFpsCamera, ReplaySetFreeTpsCamera, ReplaySetTpsCamera } = require("dasevents")
let { setInteractiveElement } = require("%ui/hud/state/interactive_state.nut")
let { localPlayerName } = require("%ui/hud/state/local_player.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")
let timeSpeedVariants = [0, 0.1, 0.25, 0.5, 1, 1.5, 2, 3, 4]

let function timeSpeedInscrese(curTimeSpeed) {
  foreach (timeSpeed in timeSpeedVariants)
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
    textButton(fa["minus"], @() timeSpeedDecrese(replayTimeSpeed.value), fontawesome)
    {
      rendObj = ROBJ_TEXT
      text = format("x%.2f", replayTimeSpeed.value)
      padding = [hdpx(20), 0]
      color = Color(255,255,255)
    }.__update(h2_txt)
    textButton(fa["plus"], @() timeSpeedInscrese(replayTimeSpeed.value), fontawesome)
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
  watch = inVehicle
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("CAMERA: ")
      padding = [fsh(2), 0]
      color = Color(255,255,255)
    }.__update(h2_txt)
    textButton("FPS", @() ecs.g_entity_mgr.broadcastEvent(ReplaySetFpsCamera()), { isEnabled = !inVehicle.value })
    textButton("TPS", @() ecs.g_entity_mgr.broadcastEvent(ReplaySetTpsCamera()), {})
    textButton("Free TPS", @() ecs.g_entity_mgr.broadcastEvent(ReplaySetFreeTpsCamera()), {})
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
  padding = hdpx(10)
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

let replayHideHudHint = @() {
  flow = FLOW_VERTICAL
  hplace = ALIGN_LEFT
  watch = isFreeTpsMode
  children = [
    tipCmp({
      text = loc("F6 disable/enable HUD")
      inputId = "Replay.DisableHUD"
      textColor = Color(255,255,255)
    })
    tipCmp({
      text = loc("tips/replay/disableGameHud")
      inputId = "Replay.DisableGameHUD"
      textColor = Color(255,255,255)
    })
    isFreeTpsMode.value ? tipCmp({
      text = loc("tips/replay/tpsFreeCamera")
      inputId = "Replay.ToggleCamera"
      textColor = Color(255,255,255)
    }) : null
  ]
}

foreach(s in [isReplay, canShowReplayHud])
  s.subscribe(@(...) setInteractiveElement("ReplayHud", isReplay.value && canShowReplayHud.value))


return @() {
  size = flex()
  flow = FLOW_VERTICAL
  key = "ReplayHud"
  behavior = Behaviors.MenuCameraControl

  children = {
    size = flex()
    children = [
      {
        size=[fsh(40),flex()]
        padding = hdpx(10)
        children = replayHideHudHint
      }
      {
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        size = [flex(), flex(1)]
        children = [
          replayTargetName
          replayBottomPlayMenu
        ]
      }
    ]
  }
  cursor = cursors.normal
}

