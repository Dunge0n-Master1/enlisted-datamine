from "%enlSqGlob/ui_library.nut" import *

let { sendQuickChatSoundMsg } = require("%ui/hud/huds/send_quick_chat_msg.nut")
let { CmdRequestAmmoBoxMarker, CmdRequestRallyPointMarker, sendNetEvent } = require("dasevents")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")

let getPieElementByCmd = @(cmd) {
  action = function() {
    sendQuickChatSoundMsg(cmd.text, cmd?.qmsg ?? {}, cmd?.sound)
    cmd?.action()
  }
  text = loc(cmd.text, cmd?.qmsg)
}

let askCommands = [
  { text = "quickchat/needCoordinates", sound = "qm_mark_enemy_vehicle" },
  // { text = "quickchat/followMe", sound = "qm_follow_me", action = @() sendNetEvent(watchedHeroEid.value, CmdBlinkMarker()) },
  // { text = "quickchat/coverMe", sound = "qm_cover_me" },
  { text = "quickchat/requestRallyPoint", sound = "qm_request_rally_point", action = @() sendNetEvent(watchedHeroEid.value, CmdRequestRallyPointMarker()) },
  { text = "quickchat/requestAmmoBox", sound = "qm_request_ammo_box", action = @() sendNetEvent(watchedHeroEid.value, CmdRequestAmmoBoxMarker()) }
].map(getPieElementByCmd)

let baseCommands = [
  // { text = "quickchat/yes", sound = "qm_accept" },
  // { text = "quickchat/no", sound = "qm_decline" },
  { text = "quickchat/thanks", sound = "qm_thanks" },
  { text = "quickchat/goodJob", sound = "qm_well_done" },
  { text = "quickchat/sorry", sound = "qm_sorry" },
  { text = "quickchat/defend" },
  { text = "quickchat/attack" }
].map(getPieElementByCmd)

return {
  quickChatCommands = [].extend(askCommands, baseCommands)
}