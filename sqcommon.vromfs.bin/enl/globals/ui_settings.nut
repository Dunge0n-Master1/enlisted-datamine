from "%darg/darg_library.nut" import mkWatched

let {is_nswitch,is_mobile} = require("%dngscripts/platform.nut")
let {reload_ui_scripts, reload_enlist_scripts} = require("app")
let useBigFonts = mkWatched(persist, "useBigFonts", is_nswitch || is_mobile)
let console = require("console")

useBigFonts.subscribe(function(_){
  reload_ui_scripts()
  reload_enlist_scripts()
})

console.register_command(@() useBigFonts(!useBigFonts.value), "ui.bigFonts")

return {
  useBigFonts
}
