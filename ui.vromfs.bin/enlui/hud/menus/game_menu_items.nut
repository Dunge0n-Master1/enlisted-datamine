import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { has_network } = require("net")
let { showSettingsMenu } = require("settings_menu.nut")
let { showControlsMenu } = require("controls_setup.nut")
let { app_is_offline_mode, switch_to_menu_scene } = require("app")
let { attentionTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { fontHeading1, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let JB = require("%ui/control/gui_buttons.nut")
let {sendNetEvent, CmdGetDebriefingResult, CmdGetBattleResult} = require("dasevents")
let msgbox = require("%ui/components/msgbox.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { isPractice } = require("%ui/hud/state/practice_state.nut")
let eventbus = require("eventbus")
let entity_editor = require_optional("entity_editor")
let isSandboxEditor = @() entity_editor != null && app_is_offline_mode()

let showExitGameMenu = mkWatched(persist, "showExitGameMenu", false)

let exitAction = function() {
  let playerEid = localPlayerEid.value
  if (playerEid == ecs.INVALID_ENTITY_ID) {
    switch_to_menu_scene()
    return
  }
  ecs.g_entity_mgr.sendEvent(playerEid, CmdGetDebriefingResult())
  if (has_network()) {
    sendNetEvent(playerEid, CmdGetBattleResult())
    gui_scene.resetTimeout(2.0, switch_to_menu_scene)
  } else
    switch_to_menu_scene()
}

let function msgExitBattle() {
  showExitGameMenu(true)
  return msgbox.show({
    text = loc("exit_game_confirmation")
    buttons = [
      { text = loc("Yes"), action = exitAction }
      { text = loc("No"), isCurrent = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
    ]
    onClose = @() showExitGameMenu(false)
  })
}

let function msgDesertBattle() {
  showExitGameMenu(true)
  return msgbox.showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        {
          size = [sw(35), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = attentionTxtColor
          text = loc("userLog/battleRes/deserter")
        }.__update(fontHeading1)
        {
          size = [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("exit_game_confirmation")
        }.__update(fontBody)
      ]
    }
    buttons = [
      { text = loc("btn/desert"), action = exitAction }
      { text = loc("No"), isCurrent = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
    onClose = @() showExitGameMenu(false)
  })
}


let btnExitGame = {
  text = !isSandboxEditor() ? loc("gamemenu/btnExitGame")
    : loc("sandboxeditor/exitSandbox", "Exit Sandbox")
  action = function() {
    if (isSandboxEditor()) {
      eventbus.send("sandbox_editor.quit", null)
      return
    }
    if (isTutorial.value || isPractice.value) {
      msgExitBattle()
    } else {
      msgDesertBattle()
    }
  }
}

return {
  showExitGameMenu
  exitAction
  btnResume = {
    text = loc("gamemenu/btnResume")
    action = @() true
  }
  btnOptions = {
    text = loc("gamemenu/btnOptions")
    action = @() showSettingsMenu.update(true)
  }
  btnBindKeys = {
    text = loc("gamemenu/btnBindKeys")
    action = @() showControlsMenu.update(true)
  }
  btnExitGame
}
