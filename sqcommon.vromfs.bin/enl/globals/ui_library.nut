let { loc } = require("%dngscripts/localizations.nut")
let { register_command, command } = require("console")
let { defer } = require("dagor.workcycle")

global enum Layers {
  Default
  Upper
  ComboPopup
  MsgBox
  Blocker
  Tooltip
  Inspector
}

let export = {
  loc
  console_register_command = register_command
  console_command = command
  defer
}
let darg = require("daRg")
let logs = require("library_logs.nut")

/*
let Pic = darg.Picture
let { send_error_log } = require("clientlog")

darg.Picture <- function(s){
  if (s.contains("/.svg") || s.contains("#.svg")) {
    logs.log(getstackinfos(2))
    send_error_log("incorrect_image_name", {
      attach_game_log = true
      collection = "events"
      meta = {
        hint = "error"
      }
    })
    return null
  }
  return Pic(s)
}
*/
return export.__update(
  darg,
  require("frp"),
  logs,
  require("%darg/darg_library.nut"),
  require("%sqstd/functools.nut")
)
