from "%enlSqGlob/ui_library.nut" import *

let { globalWatched } = require("%dngscripts/globalState.nut")
let { set_setting_by_blk_path, save_settings, get_setting_by_blk_path } = require("settings")
let { initGraphicsAutodetect, getGpuBenchmarkDuration, startGpuBenchmark,
  closeGraphicsAutodetect, getPresetFor60Fps, getPresetForMaxQuality,
  getPresetForMaxFPS } = require("gpuBenchmark")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let textButton = require("%ui/components/textButton.nut")
let { graphicsPresetUpdate } = require("%ui/hud/menus/options/quality_preset_common.nut")
let { get_time_msec } = require("dagor.time")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")

const WND_UID = "benchmark"
const BENCHMARK_FLAG_BLK = "graphics/benchmark"

let { benchmarkWindowSeen, benchmarkWindowSeenUpdate } = globalWatched("benchmarkWindowSeen",
  @() get_setting_by_blk_path(BENCHMARK_FLAG_BLK))

enum BMState {
  WAIT = 0
  RUNNING = 1
  DONE = 2
}

let timeRem = Watched(0)
let runState = Watched(BMState.WAIT)
local timeEnd

let gpuBenchmarkPresets = [
  {
    presetId = "presetMaxQuality"
    getPresetFunc = getPresetForMaxQuality
  }
  {
    presetId = "presetMaxFPS"
    getPresetFunc = getPresetForMaxFPS
  }
  {
    presetId = "preset60Fps"
    getPresetFunc = getPresetFor60Fps
  }
]

let function onTimer(){
  timeRem((timeEnd - get_time_msec()) / 1000)
  if (timeRem.value <= 0){
    gui_scene.clearTimer(onTimer)
    runState(BMState.DONE)
    closeGraphicsAutodetect()
  }
}

let function closeWindow(){
  if (timeRem.value > 0){
    gui_scene.clearTimer(onTimer)
    closeGraphicsAutodetect()
  }
  removeModalWindow(WND_UID)
}

let function applyQuality(quality){
  graphicsPresetUpdate(quality)
  closeWindow()
}

let function mkBMResult(){
  let res = gpuBenchmarkPresets.map(function(pres) {
    let quality = pres.getPresetFunc()
    return {
      flow = FLOW_HORIZONTAL
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_RIGHT
          children =
            textButton(loc($"benchmark/{pres.presetId}"), @() applyQuality(quality))
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_LEFT
          children = {
            rendObj = ROBJ_TEXT
            text = loc($"option/{quality}")
          }.__update(body_txt)
        }
      ]
    }
  })
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [SIZE_TO_CONTENT, flex()]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("benchmark/result")
      }.__update(body_txt)
      {
        flow = FLOW_VERTICAL
        children = res
      }
      textButton(loc("Cancel"), @() closeWindow())
    ]
  }
}

let function runBenchmark(){
  initGraphicsAutodetect()
  // duration + 1 second, otherwise results are not ready by the timer end:
  timeEnd = get_time_msec() + (getGpuBenchmarkDuration().tointeger() + 1)*1000
  gui_scene.setInterval(0.5, onTimer)
  runState(BMState.RUNNING)
  startGpuBenchmark()
}

let textBlock = @() {
  watch = [runState, timeRem]
  children = runState.value == BMState.DONE ? mkBMResult()
    : {
        size = flex()
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = {
          size = SIZE_TO_CONTENT
          rendObj = ROBJ_TEXT
          text = runState.value == BMState.WAIT ? loc("benchmark/runTitle")
            : loc("benchmark/timeRemain", { time = secondsToStringLoc(timeRem.value) })
        }.__update(body_txt)
      }
}

let buttonsBlock = @() {
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_BOTTOM
  gap = bigPadding
  watch = [runState]
  children = runState.value == BMState.WAIT ? [
      textButton(loc("Cancel"), @() closeWindow())
      textButton(loc("benchmark/runBenchmarkBtn"), @() runBenchmark())
    ]
  : runState.value == BMState.RUNNING ? textButton(loc("Cancel"), @() closeWindow())
  : null
}

let benchmarkWnd = {
  flow = FLOW_VERTICAL
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = Color(0,0,0,220)
  size = [sw(50), sh(35)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    textBlock
    buttonsBlock
  ]
}

let function gpuBenchmarkWnd(){
  set_setting_by_blk_path(BENCHMARK_FLAG_BLK, true)
  save_settings()
  runState(BMState.WAIT)
  benchmarkWindowSeenUpdate(true)
  addModalWindow({
    key = WND_UID
    size = [sw(100), sh(100)]
    onClick = @() null
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = benchmarkWnd
  })
}

let runBenchmarkBtn = textButton(loc("benchmark/runBenchmark"), gpuBenchmarkWnd,
  { skipDirPadNav = true })

let function resetBenchmark(){
  set_setting_by_blk_path(BENCHMARK_FLAG_BLK, false)
  save_settings()
}

console_register_command(@() resetBenchmark(), "meta.resetBenchmark")

return { gpuBenchmarkWnd, runBenchmarkBtn, benchmarkWindowSeen }