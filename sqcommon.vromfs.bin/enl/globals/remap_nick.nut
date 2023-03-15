let { is_xbox, is_sony, is_pc, is_android } = require("%dngscripts/platform.nut")
let { startsWith, endsWith } = require("%sqstd/string.nut")
let {get_setting_by_blk_path} = require("settings")
let userInfo = require("%enlSqGlob/userInfo.nut")

let needPlatformMorphemesReplacement = get_setting_by_blk_path("needPlatformMorphemesReplacement") ?? false

let PC_ICON = "⋆"
let TV_ICON = "⋇"
let PSN_ICON = "⋊"
let NBSP = " " // Non-breaking space character

let namePostfix = {
  ["@live"] = is_xbox? "" : TV_ICON,
  ["@psn"] = is_sony? PSN_ICON : TV_ICON,
  ["@steam"] = is_pc? "" : PC_ICON,
  ["@epic"] = is_pc? "" : PC_ICON,
  ["@googleplay"] = is_android? "" : TV_ICON,
  [" "] = "" //bot name suffix
}

let namePrefix = {
  ["^"] = is_xbox? "" : TV_ICON,
  ["*"] = is_sony? PSN_ICON : TV_ICON
}

let pcAddIcon = is_pc? "" : PC_ICON

let addIcon = needPlatformMorphemesReplacement ? (@(name, icon) icon == "" ? name : $"{icon}{NBSP}{name}")
  : @(name, _icon) name

let function remap_nick(name) {
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

let remap_others = @(name) name == userInfo.value?.name
  ? userInfo.value?.nameorig
  : remap_nick(name)

return {
  remap_nick
  remap_others
}