import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sendQuickChatSoundMsg } = require("%ui/hud/huds/send_quick_chat_msg.nut")
let {CmdBlinkMarker, CmdRequestAmmoBoxMarker, CmdRequestRallyPointMarker, sendNetEvent} = require("dasevents")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")

let capzones = Watched({})

ecs.register_es("capzone_get_active_titles_es", {
  [["onInit", "onChange"]] =
    @(eid, comp) capzones.mutate(@(v) v[eid] <- { active = comp.active, title = comp["capzone__title"] })
},
{
  comps_track = [["active", ecs.TYPE_BOOL]]
  comps_ro = [["capzone__title", ecs.TYPE_STRING]]
}, {})

let getPieElementByCmd = @(cmd) {
  action = function() {
    sendQuickChatSoundMsg(cmd.text, cmd?.qmsg ?? {}, cmd?.sound)
    cmd?.action()
  }
  text = loc(cmd.text, cmd?.qmsg)
  closeOnClick = true
}

let capzoneCommands = Computed(function() {
  let cmdsAttack = []
  let cmdsDefend = []

  let activeCapzones =
    capzones.value.filter(@(item) item.active).map(@(item) item.title).values().sort()

  foreach (zone in activeCapzones) {
    cmdsAttack.append(getPieElementByCmd({
      text = "quickchat/attackPoint"
      qmsg = { zone = zone }
      sound = $"qm_attack_point_{zone.tolower()}"
    }))
    cmdsDefend.append(getPieElementByCmd({
      text = "quickchat/defendPoint"
      qmsg = { zone = zone }
      sound = $"qm_defend_point_{zone.tolower()}"
    }))
  }

  if (cmdsAttack.len() == 1)
    return cmdsAttack.extend(cmdsDefend)
  else if (cmdsAttack.len() == 0)
    return cmdsAttack.resize(2)


  return [
    {
      id = "quickchat_cap_attack"
      text = loc("quickchat/attack")
      items = cmdsAttack
      closeOnClick = false
    }
    {
      id = "quickchat_cap_defend"
      text = loc("quickchat/defend")
      items = cmdsDefend
      closeOnClick = false
    }
  ]
})

let askCommands = [
  { text = "quickchat/needCoordinates", sound = "qm_mark_enemy_vehicle" },
  { text = "quickchat/followMe", sound = "qm_follow_me", action = @() sendNetEvent(watchedHeroEid.value, CmdBlinkMarker()) },
  { text = "quickchat/coverMe", sound = "qm_cover_me" },
  { text = "quickchat/requestAmmoBox", sound = "qm_request_ammo_box", action = @() sendNetEvent(watchedHeroEid.value, CmdRequestAmmoBoxMarker()) },
  { text = "quickchat/requestRallyPoint", sound = "qm_request_rally_point", action = @() sendNetEvent(watchedHeroEid.value, CmdRequestRallyPointMarker()) }
].map(getPieElementByCmd)

let askCmd = [{
  id = "quickchat_ask"
  text = loc("quickchat/ask")
  items = askCommands
  closeOnClick = false
}]

let baseCommands = [
  // sounds are missing for now
  // TODO: quickchat is hidden for chinese version using disable_quick_chat flag in settings
  // This is done because currently the whole chat window is hidden and we cant recieve any messages
  // When force_disable_battle_chat is set
  // But when audio will be added to these commands HERE disable_quick_chat should be removed
  // See commands_menu_setup.nut
  // TODO2: show quickchat chat messages even with chat turned off?
  { text = "quickchat/yes", sound = "qm_accept" },
  { text = "quickchat/no", sound = "qm_decline" },
  { text = "quickchat/sorry", sound = "qm_sorry" },
  { text = "quickchat/thanks", sound = "qm_thanks" },
  { text = "quickchat/goodJob", sound = "qm_well_done" }
].map(getPieElementByCmd)

let cmdQuickChat = Computed(@() {
  id = "quickchat_items"
  items = [].extend(askCmd, baseCommands, capzoneCommands.value)
  text = loc("quickchat/quickchat", "Quick chat")
  closeOnClick = false
})

return {
  cmdQuickChat
}