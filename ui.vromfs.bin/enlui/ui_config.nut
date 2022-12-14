from "daRg" import gui_scene
let {get_setting_by_blk_path} = require("settings")
let {DBGLEVEL} = require("dagor.system")

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")

if (sub_txt!=null) {
  gui_scene.setConfigProps({
    defaultFont = sub_txt?.font ?? gui_scene.config.defaultFont
    defaultFontSize = sub_txt?.fontSize ?? gui_scene.config.defaultFontSize
  })
}

gui_scene.setConfigProps({
  reportNestedWatchedUpdate = (DBGLEVEL > 0) ? true : get_setting_by_blk_path("debug/reportNestedWatchedUpdate") ?? false
  kbCursorControl = true
  gamepadCursorSpeed = 1.85
  //gamepadCursorDeadZone - depending on driver deadzon in controls_setup, default is setup in library

  gamepadCursorNonLin = 0.5
  gamepadCursorHoverMinMul = 0.07
  gamepadCursorHoverMaxMul = 0.8
  gamepadCursorHoverMaxTime = 1.0
  //defSceneBgColor =Color(10,10,10,160)
  //gamepadCursorControl = true

  //clickRumbleLoFreq = 0
  //clickRumbleHiFreq = 0.7
  clickRumbleLoFreq = 0
  clickRumbleHiFreq = 0.8
  clickRumbleDuration = 0.04
})
