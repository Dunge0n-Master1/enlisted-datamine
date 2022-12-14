from "%enlSqGlob/ui_library.nut" import *

let {globalWatched} = require("%dngscripts/globalState.nut")
let platform = require("%dngscripts/platform.nut")
let { get_setting_by_blk_path } = require("settings")

let function is_voice_chat_available() {
  let isAvailableByBlk = get_setting_by_blk_path("voiceChatAvailable") ?? true
  if (platform.is_xbox) {
    // disable if xbox gamechat is available, enable otherwise
    let xbchat = require("xbox.chat")
    return isAvailableByBlk && !xbchat.is_available()
  }
  return isAvailableByBlk && (platform.is_pc || platform.is_sony || platform.is_nswitch)
}
let {voiceChatEnabled, voiceChatEnabledUpdate} = globalWatched("voiceChatEnabled", is_voice_chat_available)
let {voiceChatRestricted, voiceChatRestrictedUpdate} = globalWatched("voiceChatRestricted", @() false)
return {
  voiceChatEnabled, voiceChatEnabledUpdate,
  voiceChatRestricted, voiceChatRestrictedUpdate
}
