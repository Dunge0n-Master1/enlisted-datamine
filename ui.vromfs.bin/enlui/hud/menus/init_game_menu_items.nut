import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {switch_to_menu_scene} = require("app")
let {isSandboxEditor, quitSandboxEditor} = require("%ui/sandbox_editor.nut")
let {setMenuItems} = require("%ui/hud/menus/game_menu.nut")
let {showScores} = require("%ui/hud/huds/scores.nut")
let { showBriefing } = require("%ui/hud/state/briefingState.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { has_network } = require("net")
let {showPlayersMenu} = require("%ui/hud/menus/players.nut")
let {is_sony} = require("%dngscripts/platform.nut")
let {DBGLEVEL} = require("dagor.system")
let {sendNetEvent, RequestSuicide, CmdSwitchSquad, CmdGetDebriefingResult, CmdGetBattleResult} = require("dasevents")
let {get_controlled_hero, find_local_player} = require("%dngscripts/common_queries.nut")
let allowChangeSquad = require("%ui/hud/state/allow_squad_change.nut")
let { btnResume, btnOptions, btnBindKeys} = require("%ui/hud/menus/game_menu_items.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let { canShowReplayHud } = require("%ui/hud/replay/replayState.nut")
let { isCinemaRecording, setCinemaRecording } = require("%ui/hud/replay/replayCinematicState.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { attentionTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { h1_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let JB = require("%ui/control/gui_buttons.nut")

let showSuicideMenu = mkWatched(persist, "showSuicideMenu", false)
let showExitGameMenu = mkWatched(persist, "showExitGameMenu", false)

let btnSuicide = {
  text = loc("gamemenu/btnSuicide")
  action = function() {
    showSuicideMenu(true)
    msgbox.show({
      text = loc("suicide_confirmation")
      buttons = [
        { text=loc("Yes"), action = @() sendNetEvent(get_controlled_hero(), RequestSuicide()) }
        { text=loc("No"), isCurrent = true}
      ]
      onClose = @() showSuicideMenu(false)
    })
  }
}


let btnShowScores = {
  text = loc("controls/HUD.Scores")
  action = @() showScores(true)
}

let btnBriefing = {
  text = loc("gamemenu/btnBriefing")
  action = @() showBriefing(true)
}

let btnChangeSquad = {
  text = loc("gamemenu/btnChangeSquad", "Change Squad")
  action = @() ecs.g_entity_mgr.sendEvent(find_local_player(), CmdSwitchSquad())
  isAvailable = @() allowChangeSquad.value
}

let btnPlayersInSession = {
  text = loc("Players in session")
  action = @() showPlayersMenu(true)
  isAvailable = has_network
}

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

let function msgExitReplay() {
  showExitGameMenu(true)
  return msgbox.show({
    text = loc("exit_replay_confirmation")
    buttons = [
      { text = loc("Yes"), action = exitAction }
      { text = loc("No"), isCurrent = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
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
        }.__update(h1_txt)
        {
          size = [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("exit_game_confirmation")
        }.__update(body_txt)
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
      quitSandboxEditor()
      return
    }
    msgDesertBattle()
  }
}

let btnExitReplay = {
  text = loc("replay/exitReplay")
  action = msgExitReplay
}

let btnShowReplayHud = {
  text = loc("replay/showReplayUi")
  action = @() canShowReplayHud(true)
}

let btnStopRecord = {
  text = loc("replay/btn/stopRecord")
  action = @() msgbox.show({
    text = loc("replay/stopRecord")
    buttons = [
      {
        text = loc("Yes")
        action = @() setCinemaRecording(false)
      }
      {
        text = loc("No")
        isCancel = true
        isCurrent = true
      }
    ]
  })
}

let needAddReplayHudBtn = Computed(@() isReplay.value && !canShowReplayHud.value)

let function setEnlistedMenuItems() {
  setMenuItems([
    btnResume,
    isCinemaRecording.value ? btnStopRecord : btnOptions,
    btnBindKeys,
    isReplay.value || isTutorial.value ? null : btnSuicide,
    btnChangeSquad,
    btnShowScores,
    (DBGLEVEL > 0 || is_sony) && !isReplay.value ? btnPlayersInSession : null,
    isReplay.value ? null : btnBriefing,
    needAddReplayHudBtn.value ? btnShowReplayHud : null,
    isReplay.value ? btnExitReplay : btnExitGame
  ])
}

setEnlistedMenuItems()
foreach (option in [allowChangeSquad, isReplay, isTutorial, needAddReplayHudBtn, isCinemaRecording])
  option.subscribe(@(_) setEnlistedMenuItems())


return {
  showExitGameMenu
  showSuicideMenu
}