let { is_xbox, is_sony, is_pc, is_android } = require("%dngscripts/platform.nut")
let { startsWith, endsWith } = require("%sqstd/string.nut")
let {get_setting_by_blk_path} = require("settings")
let userInfo = require("%enlSqGlob/userInfo.nut")


let { isHarmonizationEnabled } = require("%enlSqGlob/harmonizationState.nut")
let isChineseVersion = require("%enlSqGlob/isChineseVersion.nut")
let { nicknames } = isChineseVersion
   ? require("%enlSqGlob/data/generated_nicknames_chinese.nut")
   : require("%enlSqGlob/data/generated_nicknames_eng.nut")

let harmonize = @(nickname, withHarmonize = false) is_pc && isHarmonizationEnabled.value
  && withHarmonize
    ? nicknames[nickname.hash() % nicknames.len()]
    : nickname

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

let addIcon = needPlatformMorphemesReplacement
  ? (@(name, icon) icon == "" ? name : $"{icon}{NBSP}{name}")
  : @(name, _icon) name

let function remap_nick(name, withHarmonize = false) {
  if (typeof name != "string" || name == "")
    return ""

  foreach (morpheme, icon in namePostfix)
    if (endsWith(name, morpheme))
      return addIcon(harmonize(name.slice(0, -morpheme.len()), withHarmonize), icon)

  foreach (morpheme, icon in namePrefix)
    if (startsWith(name, morpheme))
      return addIcon(harmonize(name.slice(morpheme.len()), withHarmonize), icon)

  return addIcon(harmonize(name, withHarmonize), pcAddIcon)
}

let remap_others = @(name, withHarmonize = false) name == userInfo.value?.name
  ? userInfo.value?.nameorig
  : remap_nick(name, withHarmonize)

return {
  remap_nick
  remap_others
}