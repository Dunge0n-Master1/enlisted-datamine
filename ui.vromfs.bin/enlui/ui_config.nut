let {get_setting_by_blk_path} = require("settings")
let {DBGLEVEL} = require("dagor.system")

let config = require("daRg").gui_scene.config
let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")

if (sub_txt!=null) {
  config.defaultFont = require("%enlSqGlob/ui/fonts_style.nut").sub_txt?.font
  config.defaultFontSize = require("%enlSqGlob/ui/fonts_style.nut").sub_txt.fontSize
}

config.reportNestedWatchedUpdate = (DBGLEVEL > 0) ? true : get_setting_by_blk_path("debug/reportNestedWatchedUpdate") ?? false
config.kbCursorControl = true
config.gamepadCursorSpeed = 1.85
//config.gamepadCursorDeadZone - depending on driver deadzon in controls_setup, default is setup in library

config.gamepadCursorNonLin = 0.5
config.gamepadCursorHoverMinMul = 0.07
config.gamepadCursorHoverMaxMul = 0.8
config.gamepadCursorHoverMaxTime = 1.0
//config.defSceneBgColor =Color(10,10,10,160)
//config.gamepadCursorControl = true

//config.clickRumbleLoFreq = 0
//config.clickRumbleHiFreq = 0.7
config.clickRumbleLoFreq = 0
config.clickRumbleHiFreq = 0.8
config.clickRumbleDuration = 0.04
