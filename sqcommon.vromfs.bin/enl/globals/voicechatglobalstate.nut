from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let platform = require("%dngscripts/platform.nut")
let { get_setting_by_blk_path } = require("settings")

let function is_voice_chat_available() {
  let isAvailableByBlk = get_setting_by_blk_path("voiceChatAvailable") ?? true
  if (platform.is_xbox) {
    return false
  }
  return isAvailableByBlk && (platform.is_pc || platform.is_sony || platform.is_nswitch)
}

return {
  voiceChatEnabled = sharedWatched("voiceChatEnabled", is_voice_chat_available)
  voiceChatRestricted = sharedWatched("voiceChatRestricted", @() false)
}
