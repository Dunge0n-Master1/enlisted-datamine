let { get_setting_by_blk_path } = require("settings")

let { nicknames } = (get_setting_by_blk_path("isChineseVersion") ?? false)
   ? require("generated_nicknames_chinese.nut")
   : require("generated_nicknames_eng.nut")

return {
  generatedNames = nicknames
  botSuffix = " "
}
