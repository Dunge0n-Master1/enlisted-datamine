let {DBGLEVEL} = require("dagor.system")
let { is_xbox, is_xbox_scarlett, is_ps5 } = require("%dngscripts/platform.nut")
let { optXboxGraphicsPreset, optPSGraphicsPreset
  } = require("%ui/hud/menus/options/quality_preset_console_options.nut")
let { optGraphicsQualityPreset }  = require("%ui/hud/menus/options/quality_preset_option.nut")

return (DBGLEVEL > 0 ? is_xbox : is_xbox_scarlett) ? optXboxGraphicsPreset
  : is_ps5 ? optPSGraphicsPreset
  : optGraphicsQualityPreset