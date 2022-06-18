let { is_xbox, is_sony, is_pc, is_nswitch, is_android } = require("%dngscripts/platform.nut")
let { startsWith, endsWith } = require("%sqstd/string.nut")
let {get_setting_by_blk_path} = require("settings")

let needPlatformMorphemesReplacement = get_setting_by_blk_path("needPlatformMorphemesReplacement") ?? false

let PC_ICON = "⋆"
let TV_ICON = "⋇"
let NBSP = " " // Non-breaking space character

let namePostfix = {
  ["@live"] = is_xbox? "" : TV_ICON,
  ["@psn"] = is_sony? "" : TV_ICON,
  ["@steam"] = is_pc? "" : PC_ICON,
  ["@epic"] = is_pc? "" : PC_ICON,
  ["@nintendo"] = is_nswitch? "" : TV_ICON,
  ["@googleplay"] = is_android? "" : TV_ICON,
  [" "] = "" //bot name suffix
}

let namePrefix = {
  ["^"] = is_xbox? "" : TV_ICON,
  ["*"] = is_sony? "" : TV_ICON
}

let pcAddIcon = is_pc? "" : PC_ICON

let addIcon = needPlatformMorphemesReplacement ? (@(name, icon) icon == "" ? name : $"{icon}{NBSP}{name}")
  : @(name, _icon) name

return function(name) {
  if (typeof name != "string" || name == "")
    return ""

  foreach (morpheme, icon in namePostfix)
    if (endsWith(name, morpheme))
      return addIcon(name.slice(0, -morpheme.len()), icon)

  foreach (morpheme, icon in namePrefix)
    if (startsWith(name, morpheme))
      return addIcon(name.slice(morpheme.len()), icon)

  return addIcon(name, pcAddIcon)
}