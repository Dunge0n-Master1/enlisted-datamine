import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge, fontSmall, fontLarge, fontMedium
} = require("%enlSqGlob/ui/fontsStyle.nut")
let console = require("console")
let { colFull, colPart, panelBgColor, columnGap, commonBtnHeight, defTxtColor, midPadding,
  smallPadding, bigPadding, maxContentWidth, titleTxtColor, accentColor, smallBtnHeight,
  hoverBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { Bordered, FAButton, SmallBordered, PressedBordered
} = require("%ui/components/txtButton.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { replayCurTime, replayPlayTime, replayTimeSpeed, canShowReplayHud, isTpsFreeCamera,
  canShowGameHudInReplay, curSoldierInfo, isFreeInput, FPS_CAMERA, TPS_CAMERA,
  TPS_FREE_CAMERA, activeCameraId
} = require("replayState.nut")
let camera = require("camera")
let { format } = require("string")
let { ReplaySetFpsCamera, ReplaySetFreeTpsCamera, ReplaySetTpsCamera,
  ReplayToggleFreeCamera, NextReplayTarget
} = require("dasevents")
let { setInteractiveElement } = require("%ui/hud/state/interactive_state.nut")
let { localPlayerName } = require("%ui/hud/state/local_player.nut")
let { secondsToString } = require("%ui/helpers/time.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let { showScores } = require("%ui/hud/huds/scores.nut")
let mkReplayTimeLine = require("%ui/hud/replay/mkReplayTimeLine.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let faComp = require("%ui/components/faComp.nut")
let cursors = require("%daeditor/components/cursors.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let mkToggle = require("%ui/components/mkToggle.nut")
let mkCheckbox = require("%ui/components/mkCheckbox.nut")
let mkReplaySlider = require("%ui/hud/replay/mkReplaySlider.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { levelTimeOfDay, changeDayTime, changeCameraFov, cameraFov, isRain, isSnow, isLightning,
  isCinematicModeActive, changeBloom, changeAbberation, changeFilmGrain, changeMotionBlur,
  changeVignette, motionBlur, bloomEffect, filmGrain, abberation, vigneteEffect, weatherPreset,
  weatherPresetList, dofFocusDist, dofFocalLength, dofStop, dofBokeCount, dofBokeSize,
  changeBoke, changeBokeSize, changeStop, changeFocalLength, changeFocusDist, isDofCameraEnabled,
  isDofFocalActive, setRandomWeather, hasSnow, hasRain, hasLightning, lenseFlareIntensity,
  changeLenseFlareIntensity, setCinemaRecording, isCinemaRecording, changeSuperPixel,
  makeScreenShot, superPixel, changeCameraLerpFactor, cameraLerpFactor, hasCameraLerpFactor,
  enablePostBloom, cameraStopLerpFactor, changeCameraStopLerpFactor
} = require("%ui/hud/replay/replayCinematicState.nut")
let { savePreset, replayPresets, lastChoosenPreset, deletePreset, MAX_PRESETS,
  saveToCurrentPreset, saveDefaultSettings, restoreDefaultSettings
} = require("%ui/hud/replay/saveReplaySettings.nut")
let { mkSmallSelection } = require("%ui/components/mkSelection.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let vehicleSeats = require("%ui/hud/state/vehicle_seats.nut")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let { is_pc, is_win32 } = require("%dngscripts/platform.nut")
let { showSettingsMenu } = require("%ui/hud/menus/settings_menu.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { showGameMenu } = require("%ui/hud/menus/game_menu.nut")

let timeSpeedVariants = [0, 0.1, 0.25, 0.5, 1, 1.5, 2, 3, 4]
let isAdvancedSettingsActive = Watched(false)
let isNavigationBlockHidden = Watched(false)
let isAnyAdvancedSettingsOn = Computed(@() isDofCameraEnabled.value || isCinematicModeActive.value)
let isAdvancedBtnEnabled = Computed(@() !showSettingsMenu.value)
let showAdvancedSettings = keepref( Computed(@() !showGameMenu.value
  && canShowReplayHud.value
  && isAdvancedSettingsActive.value
  && !showSettingsMenu.value))

const CINEMATIC_SETTINGS_WND = "CINEMATIC_MODE_WND"
local lastReplayTimeSpeed = 1
let bottomMargin = [0, 0, colPart(0.5), 0]
let isAllSettingsEnabled = Computed(@() !isCinemaRecording.value)
let isSnowAvailable = Computed(@() hasSnow.value && isAllSettingsEnabled.value )
let isRainAvailable = Computed(@() hasRain.value && isAllSettingsEnabled.value )
let isLightningAvailable = Computed(@() hasLightning.value && isAllSettingsEnabled.value )

let needShowCursor = Computed(@() (canShowReplayHud.value || showScores.value) && !(isGamepad.value && isFreeInput.value))

// this is hack for gamepad camera control
// Problem: we can't hook stick event in UI if cursor in null for some reason
// Fix: create a invisible cursor
let gamepad_cursors_hide = Cursor(@() null)

let replayBgColor = mul_color(panelBgColor, 0.8)
let replayBlockPadding = [columnGap, colPart(0.55)]
let soldierIconSize = colPart(0.4)
let hideHudBtnSize = [colPart(0.5), colPart(0.9)]



let squareButtonStyle = { btnWidth = commonBtnHeight }
let smallSquareButtonStyle = { btnWidth = smallBtnHeight * 3, btnHeight = smallBtnHeight}
let defTxtStyle = { color = defTxtColor }.__update(fontXLarge)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let brightTxtStyle = { color = titleTxtColor }.__update(fontXLarge)
let hintTxtStyle = { color = defTxtColor }.__update(fontSmall)
let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)


let function timeSpeedIncrease(curTimeSpeed) {
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

let hideReplayHudBtn = FAButton("chevron-down", @() canShowReplayHud(false), {
  btnHeight = hideHudBtnSize[0]
  btnWidth = hideHudBtnSize[1]
  style = {
    defBgColor = panelBgColor
    hoverBgColor
  }
})

let hideReplayBlock = {
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = smallPadding
  halign = ALIGN_CENTER
  pos = [0, -hideHudBtnSize[0] / 2]
  children = [
    hideReplayHudBtn
    tipCmp({ inputId = "Replay.DisableHUD", style = { rendObj = null } })
  ]
}

let soldierInfo = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    @() {
      watch = localPlayerName
      rendObj = ROBJ_TEXT
      text = loc("replay/player", { player = remap_others(localPlayerName.value)})
    }.__update(brightTxtStyle)
    @() {
      watch = curSoldierInfo
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        kindIcon(curSoldierInfo.value?.soldier__sClass, soldierIconSize ?? "")
        {
          rendObj = ROBJ_TEXT
          text = curSoldierInfo.value?.name ?? ""
        }.__update(brightTxtStyle)
      ]
    }
  ]
}


let replayTiming = @() {
  watch = [replayCurTime, replayPlayTime]
  rendObj = ROBJ_TEXT
  text = $"{secondsToString(replayCurTime.value)} / {secondsToString(replayPlayTime.value)}"
}.__update(brightTxtStyle)


let replayTopBlock = @() {
  watch = replayPlayTime
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        soldierInfo
        replayTiming
      ]
    }
    mkReplayTimeLine(replayCurTime, {
      min = 0
      max = replayPlayTime.value
      canChangeVal = false
    })
  ]
}

let bottomHint = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(hintTxtStyle)

let mkSquareBtn = @(locId, action, btnHint) {
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  children = [
    tipCmp({ inputId = btnHint, style = { rendObj = null } })
    FAButton(locId, action)
  ]
}


let replayTimeControl = @() {
  watch = replayTimeSpeed
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = [
    replayTimeSpeed.value <= 0
      ? mkSquareBtn("play", @() console.command($"app.timeSpeed {lastReplayTimeSpeed}"),
        "Replay.Pause")
      : mkSquareBtn("pause", function(){
          lastReplayTimeSpeed = replayTimeSpeed.value
          console.command("app.timeSpeed 0")
        }, "Replay.Pause")
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      valign = ALIGN_BOTTOM
      children = [
        mkSquareBtn("minus", @() timeSpeedDecrese(replayTimeSpeed.value), "Replay.SpeedDown")
        {
          rendObj = ROBJ_TEXT
          text = format("x%.2f", replayTimeSpeed.value)
          size = [SIZE_TO_CONTENT, commonBtnHeight]
          valign = ALIGN_CENTER
        }.__update(defTxtStyle)
        mkSquareBtn("plus", @() timeSpeedIncrease(replayTimeSpeed.value), "Replay.SpeedUp")
      ]
    }
  ]
}

let replayTimeBlock = {
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  children = [
    replayTimeControl
    bottomHint(loc("replay/timeBlockHint"))
  ]
}

let canUseFPSCam = Computed(function(){
  let seat = vehicleSeats.value.data.findvalue(@(s) s?.owner.eid == watchedHeroEid.value)
  return seat?.order?.canPlaceManually ?? true
})

let function setFirstCameraActive() {
  if (canUseFPSCam.value)
    ecs.g_entity_mgr.broadcastEvent(ReplaySetFpsCamera())
}

let camerasList = [
  {
    text = "1"
    id = FPS_CAMERA
    action = setFirstCameraActive
    handlers = { ["Replay.Camera1"] = @(_event) setFirstCameraActive()}
    hotkey = "1"
    isEnabled = canUseFPSCam
  }
  {
    text = "2"
    id = TPS_CAMERA
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplaySetTpsCamera())
    handlers = { ["Replay.Camera2"] =
      @(_event) ecs.g_entity_mgr.broadcastEvent(ReplaySetTpsCamera()) }
    hotkey ="2"
  }
  {
    text = "3"
    id = TPS_FREE_CAMERA
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplaySetFreeTpsCamera())
    handlers = { ["Replay.Camera3"] =
      @(_event) ecs.g_entity_mgr.broadcastEvent(ReplaySetFreeTpsCamera()) }
    hotkey ="3"
  }
]


let function changeCamera(delta) {
  let curCameraIdx = camerasList.findindex(@(v) v.id == activeCameraId.value)
  if (curCameraIdx == null)
    return
  let newIdx = curCameraIdx + delta
  if (camerasList?[newIdx] != null)
    camerasList[newIdx].action()
}

let wndEventHandlers = {
  ["Replay.PrevCamera"] = @(_event) changeCamera(-1),
  ["Replay.NextCamera"] = @(_event) changeCamera(1),
  ["Replay.RecordVideo"] = @(_event) setCinemaRecording(!isCinemaRecording.value),
  ["Replay.AdvancedSettings"] =
    @(_event) isAdvancedSettingsActive(!isAdvancedSettingsActive.value),
  ["Replay.Next"] = @(_event) ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(),
    NextReplayTarget({ delta = 1 })),
  ["Replay.Prev"] = @(_event) ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(),
    NextReplayTarget({ delta = -1 })),
}


let replayCameraControl = @() {
  watch = [activeCameraId, canUseFPSCam]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = midPadding
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = colPart(1.5)
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = [
        tipCmp({ inputId = "Replay.PrevCamera", style = { rendObj = null } })
        tipCmp({ inputId = "Replay.NextCamera", style = { rendObj = null } })
      ]
    }
    @() {
      watch = activeCameraId
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = camerasList.map(function(cam) {
        let isPressed = activeCameraId.value == cam.id
        let btnParams = squareButtonStyle.__merge({
          hotkeys = [[cam.hotkey, cam.action]]
          isEnabled = cam?.isEnabled.value ?? true
          eventHandlers = { ["Replay.AdvancedSettings"] =
            @(_event) isAdvancedSettingsActive(!isAdvancedSettingsActive.value) }
        })
        return isPressed
          ? PressedBordered(cam.text, cam.action, btnParams)
          : Bordered(cam.text, cam.action, btnParams)
      })
    }
    bottomHint(loc("replay/camera", {
      camera = loc($"replay/cameraType/{activeCameraId.value}") }))
  ]
}


let function mkBtnWithHint(btnParams) {
  let { text, action, btnHint, actionDesc, isBtnSelected = Watched(false),
    isBtnEnabled = Watched(true), eventHandlers = null } = btnParams
  return @() {
    watch = [isBtnSelected, isBtnEnabled]
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_CENTER
    eventHandlers
    children = [
      tipCmp({ inputId = btnHint, style = { rendObj = null } })
      !isBtnEnabled.value ? Bordered(text, action, { isEnabled = false })
        : isBtnSelected.value ? PressedBordered(text, action)
        : Bordered(text, action)
      {
        rendObj = ROBJ_TEXT
        text = actionDesc
      }.__update(hintTxtStyle)
    ]
  }
}


let buttons = [
  {
    text = loc("replay/tracking")
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplayToggleFreeCamera())
    btnHint = "Replay.ToggleCamera"
    actionDesc = loc("replay/trackingHint")
    isBtnSelected = isFreeInput
    isBtnEnabled = isTpsFreeCamera
  }
  {
    text = loc("replay/teams")
    action = @() showScores(!showScores.value)
    btnHint = "HUD.Scores"
    actionDesc = loc("replay/teamsHint")
    isBtnSelected = showScores
  }
  {
    text = loc("replay/showHud")
    action = @() canShowGameHudInReplay(!canShowGameHudInReplay.value)
    btnHint = "Replay.DisableGameHUD"
    actionDesc = loc("replay/showHudHint")
    isBtnSelected = canShowGameHudInReplay
  }
  {
    text = loc("replay/advancedSettings")
    action = @() isAdvancedSettingsActive(!isAdvancedSettingsActive.value)
    btnHint = "Replay.AdvancedSettings"
    eventHandlers = { ["Replay.AdvancedSettings"] =
      @(_event) isAdvancedSettingsActive(!isAdvancedSettingsActive.value) }
    actionDesc = loc("replay/advancedSettingsHint")
    isBtnSelected = isAdvancedSettingsActive
    isBtnEnabled = isAdvancedBtnEnabled
  }
]


let buttonsBlock = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  hplace = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  children = buttons.map(mkBtnWithHint)
}

let cinematicToggleBlock = @() {
  watch = isAllSettingsEnabled
  size = [flex(), SIZE_TO_CONTENT]
  margin = bottomMargin
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("replay/cinematicMode")
    }.__update(titleTxtStyle)
    mkToggle(isCinematicModeActive, isAllSettingsEnabled.value)
  ]
}


let mkSettingsHeader = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  text = utf8ToUpper(text)
}.__update(headerTxtStyle)

let mkCheckboxBlock = @(title, value, isActive = Watched(true)) @() {
  watch = isActive
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = title
    }.__update(hintTxtStyle)
    mkCheckbox(value, isActive.value)
  ]
}

let enviromentSettings = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkSettingsHeader(loc("replay/environment"))
      @() {
        watch = [levelTimeOfDay, isAllSettingsEnabled]
        size = [flex(), SIZE_TO_CONTENT]
        children = mkReplaySlider(levelTimeOfDay, loc("replay/dayTime"), {
            max = 24
            setValue = @(newTime) changeDayTime(newTime)
            valueToShow = secondsToString(levelTimeOfDay.value * 60)
            isEnabled = isAllSettingsEnabled.value
          })
      }
    function() {
      let wPreset = weatherPreset.value
      let wHeader = wPreset != null
        ? loc("replay/wPreset", { preset = loc($"weatherPreset/{wPreset}")})
        : loc("replay/chooseWeather")
      return {
        watch = [weatherPresetList, weatherPreset, isAllSettingsEnabled]
        size = [flex(), SIZE_TO_CONTENT]
        children = mkSmallSelection(weatherPresetList.value, weatherPreset, {
          header = wHeader
          isEnabled = isAllSettingsEnabled.value
        })
      }
    }
    @() {
      watch = isAllSettingsEnabled
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = { size = flex() }
      children = [
        mkCheckboxBlock(loc("replay/weatherSnow"), isSnow, isSnowAvailable)
        mkCheckboxBlock(loc("replay/weatherRain"), isRain, isRainAvailable)
        mkCheckboxBlock(loc("replay/weatherLightning"), isLightning, isLightningAvailable)
      ]
    }
    @() {
      watch = [weatherPresetList, isAllSettingsEnabled]
      children = SmallBordered(loc("replay/randomWeather"), setRandomWeather, {
        isEnabled = isAllSettingsEnabled.value && weatherPresetList.value.len() > 1
      })
    }
  ]
}


let cameraSettingsBlock = @() {
  watch = [cameraFov, isAllSettingsEnabled, cameraLerpFactor, hasCameraLerpFactor]
  size = [flex(), SIZE_TO_CONTENT]
  margin = bottomMargin
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkSettingsHeader(loc("replay/cameraSettings"))
    mkReplaySlider(cameraFov, loc("replay/cameraFov"), {
      setValue = @(newVal) changeCameraFov(newVal)
      min = 10
      max = 130
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(cameraLerpFactor, loc("replay/cameraLerpFactor"), {
      setValue = @(newVal) changeCameraLerpFactor(newVal)
      min = 1
      max = 10
      isEnabled = isAllSettingsEnabled.value && hasCameraLerpFactor.value
    })
    mkReplaySlider(cameraStopLerpFactor, loc("replay/cameraStopLerpFactor"), {
      setValue = @(newVal) changeCameraStopLerpFactor(newVal)
      min = 0.75
      max = 0.99
      step = 0.01
      isEnabled = isAllSettingsEnabled.value && isTpsFreeCamera.value
    })
  ]
}


let dofToggleBlock = @() {
  watch = isAllSettingsEnabled
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  margin = bottomMargin
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("replay/dofMode")
    }.__update(titleTxtStyle)
    mkToggle(isDofCameraEnabled, isAllSettingsEnabled.value)
  ]
}


let dofSettings = @() {
  watch = [isDofFocalActive, isAllSettingsEnabled]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children =  [
    mkSettingsHeader(loc("replay/dofSettings"))
    mkReplaySlider(dofFocusDist, loc("replay/focusDist"), {
      min = 0.1
      max = 20
      setValue = @(newVal) changeFocusDist(newVal)
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(dofStop, loc("replay/focusStop"), {
      min = 1
      max = 22
      setValue = @(newVal) changeStop(newVal)
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(dofBokeCount, loc("replay/bokeCount"), {
      min = 3
      max = 15
      setValue = @(newVal) changeBoke(newVal)
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(dofBokeSize, loc("replay/bokeSize"), {
      min = 1
      max = 16
      setValue = @(newVal) changeBokeSize(newVal)
      isEnabled = isAllSettingsEnabled.value
    })
    mkCheckboxBlock(loc("replay/isFocalActive"), isDofFocalActive, isAllSettingsEnabled)
    mkReplaySlider(dofFocalLength, loc("replay/focalLength"), {
      min = 12
      max = 300
      setValue = @(newVal) changeFocalLength(newVal)
      isEnabled = isDofFocalActive.value && isAllSettingsEnabled.value
    })
  ]
}


let postProcessinSettings = @() {
  watch = isAllSettingsEnabled
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkSettingsHeader(loc("replay/postProcessing"))
    mkReplaySlider(motionBlur, loc("replay/motionBlur"), {
      setValue = @(newVal) changeMotionBlur(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(bloomEffect, loc("replay/bloomEffect"), {
      setValue = @(newVal) changeBloom(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(filmGrain, loc("replay/filmicNoise"), {
      setValue = @(newVal) changeFilmGrain(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(abberation, loc("replay/chromaticAbb"), {
      setValue = @(newVal) changeAbberation(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(vigneteEffect, loc("replay/vignette"), {
      setValue = @(newVal) changeVignette(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.value
    })
    mkReplaySlider(lenseFlareIntensity, loc("replay/lensFlare"), {
      setValue = @(newVal) changeLenseFlareIntensity(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.value
    })
    mkCheckboxBlock(loc("replay/enablePostBloom"), enablePostBloom, isAllSettingsEnabled)
  ]
}


let mkSettingsBlock = @(watchedFlag, content) @(){
  watch = watchedFlag
  size = [flex(), SIZE_TO_CONTENT]
  transform = { scale = watchedFlag.value ? [1, 1] : [1, 0] }
  transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
  margin = watchedFlag.value ? bottomMargin : 0
  children = watchedFlag.value ? content : null
}


let function presetBlock() {
  let header = replayPresets.value.len() <= 0
    ? loc("replay/createPreset")
    : loc("replay/choosePreset")
  let preset = lastChoosenPreset.value
  return {
    watch = [replayPresets, lastChoosenPreset, isAllSettingsEnabled]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = bottomMargin
    gap = bigPadding
    children = [
      mkSmallSelection(replayPresets.value, lastChoosenPreset, {
        header = preset ?? header
        isEnabled = isAllSettingsEnabled.value
      })
      @() {
        watch = [isAnyAdvancedSettingsOn, isAllSettingsEnabled]
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          SmallBordered(loc("replay/savePreset"), savePreset, {
            isEnabled = replayPresets.value.len() < MAX_PRESETS && isAnyAdvancedSettingsOn.value
              && isAllSettingsEnabled.value
            btnWidth = flex() })
          SmallBordered(loc("replay/changePreset"),
            @() saveToCurrentPreset(lastChoosenPreset.value), {
            isEnabled = lastChoosenPreset.value != null && isAllSettingsEnabled.value
            btnWidth = flex()})
        ]
      }
      SmallBordered(loc("replay/deletePreset"), @() deletePreset(lastChoosenPreset.value), {
        isEnabled = lastChoosenPreset.value != null && isAllSettingsEnabled.value
        btnWidth = flex()
      })
    ]
  }}


let makeScreenshotBlock = @() {
  watch = [isCinematicModeActive, isAllSettingsEnabled]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    @() {
      watch = superPixel
      size = [flex(), SIZE_TO_CONTENT]
      children = mkReplaySlider(superPixel, loc("replay/suprePixel"), {
        min = 1
        max = 4
        setValue = changeSuperPixel
        isEnabled = isCinematicModeActive.value && isAllSettingsEnabled.value
        valueToShow = $"x{superPixel.value}"
      })
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = { size = flex() }
      valign = ALIGN_CENTER
      children = [
        tipCmp({ inputId = "Global.ScreenshotNoGUI", style = { rendObj = null }})
        FAButton("camera", makeScreenShot, {
          style = { defTxtColor =0xFF138808, hoverTxtColor = 0xFF138808 }
          isEnabled = isCinematicModeActive.value && isAllSettingsEnabled.value
        }.__update(smallSquareButtonStyle))
      ]
    }
  ]
}


let recordSignColor = 0xFFB00000
let recordBtnStyle = {
  defTxtColor = recordSignColor,
  hoverTxtColor = recordSignColor,
  activeTxtColor = recordSignColor
}

let recordVideoBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  valign = ALIGN_CENTER
  children = [
    tipCmp({inputId = "Replay.RecordVideo", style = { rendObj = null }})
    @() {
      watch = [isCinemaRecording, isCinematicModeActive]
      children = FAButton("circle", @() setCinemaRecording(!isCinemaRecording.value), {
        style = isCinemaRecording.value ? { defTxtColor = recordSignColor } : recordBtnStyle
        isEnabled = isCinematicModeActive.value
      }.__update(smallSquareButtonStyle))
    }
  ]
}


let screenVideoBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    mkSettingsHeader(loc("replay/screenVideoHeader"))
    makeScreenshotBlock
    is_win32 ? null : recordVideoBlock
  ]
}

let resetToDefaultBtn = @() {
  watch = isAllSettingsEnabled
  size = [flex(), SIZE_TO_CONTENT]
  children = SmallBordered(loc("replay/resetDefaultSettings"), restoreDefaultSettings, {
    btnWidth = flex()
    margin = bottomMargin
    isEnabled = isAllSettingsEnabled.value
  })
}

let advancedSettingsWnd = {
  key = CINEMATIC_SETTINGS_WND
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = replayBgColor
  size = [colFull(6), SIZE_TO_CONTENT]
  margin = colFull(1)
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  onClick = @() null
  hotkeys = [[$"^{JB.B} | Esc", @() isAdvancedSettingsActive(false)]]
  onAttach = saveDefaultSettings
  children = makeVertScroll(
    {
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      padding = [colPart(0.3), colPart(0.5)]
      children = [
        cameraSettingsBlock
        cinematicToggleBlock
        mkSettingsBlock(Computed(@() is_pc && isCinematicModeActive.value), screenVideoBlock)
        mkSettingsBlock(isCinematicModeActive, enviromentSettings)
        mkSettingsBlock(isCinematicModeActive, postProcessinSettings)
        dofToggleBlock
        mkSettingsBlock(isDofCameraEnabled, dofSettings)
        presetBlock
        resetToDefaultBtn
      ]
    }, {
      size = [colFull(6), SIZE_TO_CONTENT],
      maxHeight = sh(70)
      rootBase = class {
        behavior = Behaviors.Pannable
        wheelStep = 1
      }
      styling = thinStyle
  })
}

showAdvancedSettings.subscribe(@(v) v
  ? addModalWindow(advancedSettingsWnd)
  : removeModalWindow(CINEMATIC_SETTINGS_WND))



let replayBottomBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        replayTimeBlock
        replayCameraControl
      ]
    }
    buttonsBlock
  ]
}


let replayNavigation = {
  size = [colFull(24), colPart(3.6)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = replayBgColor
  children = [
    hideReplayBlock
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = bigPadding
      padding = replayBlockPadding
      children = [
        replayTopBlock
        replayBottomBlock
      ]
    }
  ]
}


let hiddenNavigationBlock = watchElemState(function(sf) {
  let res = {
    watch = isNavigationBlockHidden
    onDetach = @() isNavigationBlockHidden(false)
  }
  if (isNavigationBlockHidden.value)
    return res

  return res.__update({
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = sf & S_HOVER ? accentColor : replayBgColor
    padding = [midPadding, colPart(0.2)]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = smallPadding
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0, duration = 1, delay = 4,
        play = true, onFinish = @() isNavigationBlockHidden(true) }
      { prop = AnimProp.opacity, from = 0, to = 0, delay = 4.9, duration = 1,
        play = true }
    ]
    children = [
      faComp("chevron-up", {
        fontSize = fontLarge.fontSize
      })
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          tipCmp({ inputId = "Replay.DisableHUD", style = { rendObj = null } })
          {
            rendObj = ROBJ_TEXT
            text = loc("replay/showReplayUi")
          }.__update(hintTxtStyle)
        ]
      }
    ]
  })
})

let replayNavigationBlock = @() {
  watch = canShowReplayHud
  children = canShowReplayHud.value
    ? replayNavigation
    : hiddenNavigationBlock
}


foreach(s in [isReplay, canShowReplayHud])
  s.subscribe(@(...) setInteractiveElement("ReplayHud", isReplay.value && canShowReplayHud.value))


return function() {
  camerasList.each(function(v) {
    let bindedKey = v.handlers.keys()[0]
    let bindedAction = v.handlers.values()[0]
    wndEventHandlers[bindedKey] <- bindedAction
  })
  return {
    watch = [needShowCursor, isFreeInput, showGameMenu, isGamepad]
    size = flex()
    maxWidth = maxContentWidth
    flow = FLOW_VERTICAL
    key = "ReplayHud"
    eventHandlers = wndEventHandlers
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    cursor = needShowCursor.value ? cursors.normal : (isGamepad.value ? gamepad_cursors_hide : null)
    valign = ALIGN_BOTTOM
    behavior = isFreeInput.value ? (showGameMenu.value ? null : Behaviors.ReplayFreeCameraControl) : Behaviors.MenuCameraControl
    children = replayNavigationBlock
  }
}