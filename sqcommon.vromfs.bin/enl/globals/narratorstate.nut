from "%darg/ui_imports.nut" import *

let { get_setting_by_blk_path } = require("settings")
let narratorNativeLang = mkWatched(persist, "narratorNativeLang", get_setting_by_blk_path("gameplay/narrator_nativeLanguage") ?? false)

return narratorNativeLang