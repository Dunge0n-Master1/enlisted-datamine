from "%enlSqGlob/ui_library.nut" import *

require("state/debriefing_es.nut")//fixme
let { get_setting_by_blk_path } = require("settings")
let { showChatInput } =  require("%ui/hud/chat.ui.nut")
let briefing = require("huds/overlays/enlisted_briefing.nut")
let { showBriefing } = require("state/briefingState.nut")
let { playersMenuUi, showPlayersMenu } = require("%ui/hud/menus/players.nut")

let { menusUi, hudMenus, openMenu } = require("%ui/hud/ct_hud_menus.nut")
let { scoresMenuUi, showScores } = require("huds/scores.nut")
let { showBigMap, bigMap } = require("%ui/hud/menus/big_map.nut")
let { showPieMenu } = require("%ui/hud/state/pie_menu_state.nut")
let pieMenu = require("%ui/hud/pieMenu.ui.nut")
let { showBuildingToolMenu } = require("%ui/hud/state/building_tool_menu_state.nut")
let buildingToolMenu = require("%ui/hud/huds/building_tool_menu.ui.nut")
let { isBuildingToolMenuAvailable } = require("%ui/hud/state/building_tool_state.nut")
let squadSoldiersMenu = require("%ui/hud/huds/squad_soldiers_menu.ui.nut")
let { showSquadSoldiersMenu, isSquadSoldiersMenuAvailable } = require("%ui/hud/state/squad_soldiers_menu_state.nut")
let { forceDisableBattleChat } = require("%ui/hud/state/hudOptionsState.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let dainput = require("dainput2")
//local { forcedMinimalHud } = require("state/hudGameModes.nut")

let function openBuildingToolMenu() {
  if (isBuildingToolMenuAvailable.value)
    showBuildingToolMenu(true)
}

let function openSquadSoldiersMenu() {
  if (isSquadSoldiersMenuAvailable.value)
    showSquadSoldiersMenu(true)
}

isSquadSoldiersMenuAvailable.subscribe(function(isAvailable) {
  if (!isAvailable)
    showSquadSoldiersMenu(false)
})

let { artilleryMap, showArtilleryMap } = require("%ui/hud/menus/artillery_radio_map.nut")

let { debriefingShow, debriefingDataExt } = require("%ui/hud/state/debriefingStateInBattle.nut")
let debriefing = require("menus/mk_debriefing.nut")(debriefingDataExt)

let openCommandsMenu = @() showPieMenu(true)

let groups = {
  debriefing = 1
  gameHud   = 3
  chatInput = 4
  pieMenu   = 5
}
let showChatInputAct = Computed( @() /*!forcedMinimalHud.value && */ showChatInput.value)
let showPieMenuAct = Computed(@() showPieMenu.value && !isReplay.value)

let disableMenu = get_setting_by_blk_path("disableMenu") ?? false
let huds = [
  {
    show = showBuildingToolMenu
    menu = buildingToolMenu
    close = @() showBuildingToolMenu(false)
    open = openBuildingToolMenu
    event = "HUD.BuildingToolMenu"
    group = groups.pieMenu
    id = "BuildingToolMenu"
  },
  {
    show = showPieMenuAct,
    open = function () {
      if (!isReplay.value)
        openCommandsMenu()
    },
    close = @() showPieMenu(false)
    menu = pieMenu
    holdToToggleDurMsec = -1
    event = "HUD.CommandsMenu"
    group = groups.pieMenu
    id = "PieMenu"
  },
  {
    show = showSquadSoldiersMenu
    menu = squadSoldiersMenu
    open = openSquadSoldiersMenu
    holdToToggleDurMsec = -1
    close = @() showSquadSoldiersMenu(false)
    event = "HUD.SquadSoldiersMenu"
    group = groups.pieMenu
    id = "SquadSoldiersMenu"
  },
  forceDisableBattleChat ? null : {
    show = showChatInputAct
    open = function() {
      // if (!forcedMinimalHud.value)
        showChatInput(true)
    }
    close = @() showChatInput(false)
    event = "HUD.ChatInput"
    group = groups.chatInput
    id = "Chat"
  },
  {
    show = showBriefing
    menu = briefing
    event = "HUD.Briefing"
    group = groups.gameHud
    id = "Briefing"
  },
  {
    show = showArtilleryMap
    menu = artilleryMap
    group = groups.gameHud
    id = "ArtilleryMap"
  },
  {
    show = showBigMap
    menu = bigMap
    event = "HUD.BigMap"
    group = groups.gameHud
    id = "BigMap"
  },
  {
    show = showPlayersMenu
    menu = playersMenuUi
    group = groups.gameHud
    id = "Players"
  },
  {
    show = showScores
    menu = scoresMenuUi
    event = "HUD.Scores"
    group = disableMenu ? groups.debriefing : groups.gameHud
    id = "Scores"
  },
  {
    show = debriefingShow
    menu = debriefing
    group = groups.debriefing
    id = "Debriefing"
  }
].filter(@(v) v!=null)

let function unstickEventWhenHudClosed(menu) {
  if (menu?.event == null || !(menu?.show instanceof Watched))
    return
  menu.show.subscribe(function(val) {
    if (!val)
      dainput.reset_digital_action_sticky_toggle(dainput.get_action_handle(menu.event, 0xFFFF))
  })
}

// if menu was opened with a sticky key and closed not by clicking that key, we want to unstick it
// otherwise the next click of the key will do the unstick and no menu will open
huds.each(unstickEventWhenHudClosed)
hudMenus(huds)

debriefingDataExt.subscribe(function(val) {
  if (val.len() > 0)
    openMenu("Debriefing")
})

return menusUi