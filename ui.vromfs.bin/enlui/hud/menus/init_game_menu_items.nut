import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {exit_to_enlist} = require("app")
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
let {sendNetEvent, RequestSuicide, CmdSwitchSquad} = require("dasevents")
let {get_controlled_hero, find_local_player} = require("%dngscripts/common_queries.nut")
let allowChangeSquad = require("%ui/hud/state/allow_squad_change.nut")
let { btnResume, btnOptions, btnBindKeys } = require("%ui/hud/menus/game_menu_items.nut")
let {client_request_unicast_net_sqevent} = require("ecs.netevent")

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

let btnExitGame = {
  text = !isSandboxEditor() ? loc("gamemenu/btnExitGame")
                            : loc("sandboxeditor/exitSandbox", "Exit Sandbox")
  action = function() {
    if (isSandboxEditor()) {
      quitSandboxEditor()
      return
    }
    showExitGameMenu(true)
    msgbox.show({
      text = loc("exit_game_confirmation")
      buttons = [
        { text = loc("Yes"),
          action = function() {
            let playerEid = localPlayerEid.value
            if (playerEid == INVALID_ENTITY_ID) {
              exit_to_enlist()
              return
            }
            ecs.g_entity_mgr.sendEvent(playerEid, ecs.event.CmdGetBattleResult({}))
            if (has_network()) {
              client_request_unicast_net_sqevent(playerEid, ecs.event.CmdGetBattleResult({a=false})) // non empty payload to get "fromconnid"
              gui_scene.resetTimeout(2.0, exit_to_enlist)
            } else
              exit_to_enlist()
          }
        }
        { text = loc("No"), isCurrent = true}
      ]
      onClose = @() showExitGameMenu(false)
    })
  }
}

let function setEnlistedMenuItems() {
  setMenuItems([
    btnResume,
    btnOptions,
    btnBindKeys,
    btnSuicide,
    btnChangeSquad,
    btnShowScores,
    (DBGLEVEL > 0 || is_sony) ? btnPlayersInSession : null,
    btnBriefing,
    btnExitGame,
  ])
}

setEnlistedMenuItems()
allowChangeSquad.subscribe(@(_) setEnlistedMenuItems())

return {
  showExitGameMenu
  showSuicideMenu
}