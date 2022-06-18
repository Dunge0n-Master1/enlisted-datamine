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

return export.__update(
  require("daRg"),
  require("frp"),
  require("library_logs.nut"),
  require("%darg/darg_library.nut"),
  require("%sqstd/functools.nut")
)
