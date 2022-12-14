from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")

let headshotSoundEnabled = Watched(get_setting_by_blk_path("sound/headshot_sound_enabled") ?? true)
let battleMusicEnabled = Watched(get_setting_by_blk_path("sound/battle_music_enabled") ?? true)

return {
  headshotSoundEnabled
  battleMusicEnabled
}