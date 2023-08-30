import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {setMenuItems} = require("%ui/hud/menus/game_menu.nut")
let {showScores} = require("%ui/hud/huds/scores.nut")
let { showBriefing } = require("%ui/hud/state/briefingState.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { has_network } = require("net")
let {showPlayersMenu} = require("%ui/hud/menus/players.nut")
let {is_sony} = require("%dngscripts/platform.nut")
let {DBGLEVEL} = require("dagor.system")
let {sendNetEvent, RequestSuicide, CmdSwitchSquad} = require("dasevents")
let {get_controlled_hero, find_local_player} = require("%dngscripts/common_queries.nut")
let allowChangeSquad = require("%ui/hud/state/allow_squad_change.nut")
let { btnResume, btnOptions, btnBindKeys, btnExitGame, showExitGameMenu, exitAction} = require("%ui/hud/menus/game_menu_items.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let { canShowReplayHud } = require("%ui/hud/replay/replayState.nut")
let { isCinemaRecording, setCinemaRecording } = require("%ui/hud/replay/replayCinematicState.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let JB = require("%ui/control/gui_buttons.nut")

let showSuicideMenu = mkWatched(persist, "showSuicideMenu", false)

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