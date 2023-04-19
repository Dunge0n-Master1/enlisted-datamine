from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("state/hudGameModes.nut")
let hudLayoutState = require("%ui/hud/state/hud_layout_state.nut")
let maintenanceProgress = require("%ui/hud/huds/maintenance_progress_hint.nut")
let bombSiteProgress = require("%ui/hud/huds/bomb_site_progress_hint.nut")
let ammoRequestCooldown = require("huds/ammo_request_cooldown_hint.nut")
let vehicleSeats = require("huds/vehicle_seats.ui.nut")
let vehicleChangeSeats = require("huds/vehicle_change_seats.nut")
let pushObjectTip = require("huds/push_object_tip.nut")
let paratroopersSupplyBoxTip = require("huds/paratroopers_supply_box_tip.nut")
let grenadeRethrowTip = require("huds/grenade_rethrow_tip.nut")
let fortificationAction = require("%ui/hud/huds/fortification_builder_action.nut")
let { enterVehicleIndicator, exitVehicleIndicator } = require("%ui/hud/huds/enter_exit_vehicle.nut")
let putOutFire = require("%ui/hud/huds/put_out_fire_indicator.nut")
let squadMembersUi = require("huds/squad_members.ui.nut")
let voteKickUi = require("huds/vote_kick.ui.nut")
let artilleryOrderUi = require("huds/artillery_order.ui.nut")
let { chatRoot } = require("%ui/hud/chat.ui.nut")
let { serviceMessages, hasServiceMessages } = require("huds/serviceMessages.nut")
let vehicleRepair = require("%ui/hud/huds/vehicle_repair.nut")
let playerEventsRoot = require("%ui/hud/huds/player_events.nut")
let throw_grenade_tip = require("%ui/hud/huds/tips/throw_grenade_tip.nut")
let melee_charge_tip = require("%ui/hud/huds/tips/melee_charge_tip.nut")
let artillery_ratio_tip = require("huds/tips/artillery_radio_tip.nut")
let friendly_fire_warning = require("%ui/hud/huds/friendly_fire_warning.nut")
let ammoDepletedInTank = require("huds/tips/ammo_depleted_in_tank.nut")
let lieDownToShootAccuratelyTip = require("huds/tips/lie_down_to_shoot_accurately_tip.nut")
let hasToChargeTip = require("huds/tips/has_to_charge_tip.nut")
let cannotDigAtPosTip = require("huds/tips/cannot_dig_at_pos.nut")
let lie_down_to_save_from_expl_tip = require("huds/tips/lie_down_to_save_from_expl_tip.nut")
let minimap = require("%ui/hud/menus/enlisted_maps.nut").minimap()
let hitcamera = require("%ui/hud/huds/hitcamera.ui.nut")
let dmPanel = require("%ui/hud/huds/dm_panel.ui.nut")
let fortificationRepairProgress = require("%ui/hud/huds/fortification_repair_progress_hint.nut")
let outsideBattleAreaWarning = require("%ui/hud/huds/battle_area_warnings_hint.nut")

let vehicleWarnings = require("%ui/hud/huds/vehicle_warnings.nut")
let vehicleSteerTip = require("%ui/hud/huds/vehicle_steer_tip.nut")
let planeSteerTip = require("%ui/hud/huds/tips/plane_steer_tip.nut")
let vehicleResupplyTip = require("%ui/hud/huds/tips/vehicle_resupply.nut")
let {planeHud} = require("%ui/hud/huds/plane_hud.nut")

let medicHealTip = require("%ui/hud/huds/tips/medic_heal_tip.nut")

let spectatorKeys_tip = require("%ui/hud/huds/tips/spectatorKeys_tip.nut")
let hasSpectatorKeys = require("%ui/hud/state/hasSpectatorKeys.nut")
let { mainAction } = require("%ui/hud/huds/actions.nut")
let maintenanceHint = require("%ui/hud/huds/maintenance_hint.nut")
let { localTeamEnemyHint } = require("%ui/hud/huds/enemy_hint.nut")
let vehicleActions = require("%ui/hud/huds/vehicleActions.nut")
let planeTakeOffTips = require("%ui/hud/huds/planeTakeOffTips.nut")
let buildingActions = require("huds/tips/building_tool_tip.nut")
let vehicleFreeSeatTip = require("huds/tips/vehicle_free_seat_tip.nut")
let wallposterActions = require("huds/tips/wallposter_tool_tip.nut")
let noRespawnTip = require("huds/tips/no_respawn_reason_tip.nut")
let vehicleHud = require("huds/vehicle_hud.nut")
let { curCapZone } = require("%ui/hud/state/capZones.nut")
let {compassZoneCtor, compassZoneWatch} = require("%ui/hud/huds/compass_zones.nut")
let compassStrip = require("%ui/hud/huds/compass/mk_compass_strip.nut")({
  size = [hdpx(220), hdpx(40)],
  compassObjects = [{watch = compassZoneWatch, childrenCtor = compassZoneCtor}] //!!FIX ME: why subscription here?
  globalScale = 0.8
})
let gameModeBlock = require("huds/game_mode.ui.nut")
let awards = require("huds/score_awards.nut")
let warnings = require("huds/warnings.nut")
let spectatorMode_tip = require("%ui/hud/huds/tips/spectatorMode_tip.nut")
let hints = require("%ui/hud/huds/hints.nut")
let killLog = require("huds/killLog.nut")
let playerDynamic = require("huds/player_weapons.ui.nut")
let mortarTips = require("%ui/hud/huds/tips/mortar_tips.nut")
let {isMortarMode} = require("%ui/hud/state/mortar.nut")
let {inPlane} = require("%ui/hud/state/vehicle_state.nut")
let {showBigMap} = require("%ui/hud/menus/big_map.nut")
let {showArtilleryMap} = require("menus/artillery_radio_map.nut")
let {
  minimalistHud, showBattleChat
} = require("%ui/hud/state/hudOptionsState.nut")
let { mkHudElement, HUD_FLAGS, hudFlags } = require("%ui/hud/state/hudFlagsState.nut")
let {showSquadSpawn} = require("%ui/hud/state/respawnState.nut")
let {playerDeaths} = require("huds/player_deaths.nut")
let {tkWarning} = require("huds/team_kills.nut")
let {text} = require("%ui/components/text.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let logHUD = require("%enlSqGlob/library_logs.nut").with_prefix("[HUD] ")

let minHud = keepref(Computed(@() forcedMinimalHud.value || minimalistHud.value))
let showGameMode = Computed( @() !minHud.value || showSquadSpawn.value || showBigMap.value)
let curCapZoneTitle = Computed(@() curCapZone.value?.caption)
let showCurCapZoneTitle = Watched(false)
let hideCurCapZoneTitle = @() showCurCapZoneTitle(false)
curCapZoneTitle.subscribe(function(v){
  if ((v ?? "") == "")
    return
  showCurCapZoneTitle(true)
  gui_scene.resetTimeout( 6, hideCurCapZoneTitle)
})
let czTitleAnims = freeze([
  { prop=AnimProp.opacity, from=0, to=1.0, duration=0.4, play=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=1.0, to=0.0, duration=3, playFadeOut=true, easing=InCubic}
])

let capZoneTitle = @(){
  watch = curCapZoneTitle
  animations = czTitleAnims
  children = text(loc(curCapZoneTitle.value))
}
let gameMode = @(){
  watch = [showGameMode, showCurCapZoneTitle]
  children = showGameMode.value
    ? gameModeBlock
    : showCurCapZoneTitle.value
      ? capZoneTitle
      : null
}

let actionsRoot = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM

  children = @() {
    size=SIZE_TO_CONTENT
    watch = [minHud, isTutorial]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = minHud.value
      ? [localTeamEnemyHint].extend(wallposterActions)
      : [].extend(planeTakeOffTips, buildingActions,
                  [medicHealTip, maintenanceHint, mainAction, localTeamEnemyHint, vehicleFreeSeatTip],
                  isTutorial.value ? [] : vehicleActions, wallposterActions)
  }
}

let showMinimap = Computed(@() !forcedMinimalHud.value && !(showArtilleryMap.value || showBigMap.value))

let compassAndMap = @(){
  watch = [showMinimap, forcedMinimalHud]
  flow = FLOW_VERTICAL
  children = [!forcedMinimalHud.value ? dmPanel : null, showMinimap.value ? minimap : null, compassStrip]
  gap = hdpx(10)
  size = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
}

let compassOnly = @() {
  flow = FLOW_VERTICAL
  watch = forcedMinimalHud
  children = [!forcedMinimalHud.value ? dmPanel : null, compassStrip]
  gap = hdpx(10)
  size = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
}

let function minimap_mod() {
  local mc
  if (inPlane.value)
    mc = [compassOnly, voteKickUi, vehicleSteerTip, planeSteerTip]
  else if (isMortarMode.value)
    mc = [compassAndMap, voteKickUi, mortarTips]
  else
    mc = [compassAndMap, vehicleSteerTip, planeSteerTip, voteKickUi]
  return {
    children = mc
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap = hdpx(5)
    watch = [isMortarMode, inPlane]
  }
}

hudLayoutState.centerPanelTopStyle({ gap = hdpx(2), size = flex(4) })
hudLayoutState.centerPanelMiddleStyle({ gap = hdpx(2), size = flex(4) })
hudLayoutState.centerPanelBottomStyle({ gap = hdpx(2), size = flex(1.5) })
hudLayoutState.leftPanelBottomStyle({valign = ALIGN_BOTTOM, padding = 0, gap=0})
let showChat = keepref(Computed(@() showBattleChat.value))

let spectatorKeys = @() {
  watch = hasSpectatorKeys
  children = hasSpectatorKeys.value ? spectatorKeys_tip : null
}

let chat = @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = [hasServiceMessages, showChat]
  children = hasServiceMessages.value ? serviceMessages
    : showChat.value ? chatRoot
    : null
}

let LEFT_PANEL_TOP = [
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = planeHud }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = vehicleHud }
]

let LEFT_PANEL_MIDDLE = [
  { flags = HUD_FLAGS.MINIMAL, comp = chat }

  { flags = HUD_FLAGS.FULL, comp = chat }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.TUTORIAL, comp = vehicleSeats }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = squadMembersUi }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = artilleryOrderUi }
]

let LEFT_PANEL_BOTTOM = [
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_MINIMALIST | HUD_FLAGS.NO_SQUAD_SPAWN | HUD_FLAGS.NO_HARDCORE, comp = vehicleSeats }
  { flags = HUD_FLAGS.NO_MINIMALIST | HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_SQUAD_SPAWN, comp = minimap_mod }
]

let CENTER_PANEL_TOP = [
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.PLAYER_UI, comp = gameMode }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_TIPS, comp = spectatorMode_tip }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = noRespawnTip }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleChangeSeats }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = enterVehicleIndicator }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = exitVehicleIndicator }

  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = gameMode }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = hints }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = warnings }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = spectatorMode_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = noRespawnTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleChangeSeats }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = enterVehicleIndicator }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = exitVehicleIndicator }
]

let CENTER_PANEL_MIDDLE = [
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerEventsRoot }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleRepair }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = maintenanceProgress }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationRepairProgress }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = bombSiteProgress }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.MINIMAL, comp = tkWarning }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = putOutFire }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationAction }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerDeaths }

  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = outsideBattleAreaWarning }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerEventsRoot }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleWarnings }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = vehicleRepair }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = maintenanceProgress }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationRepairProgress }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = bombSiteProgress }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL, comp = tkWarning }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = ammoRequestCooldown }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = putOutFire }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = fortificationAction }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_AWARDS, comp = awards }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = playerDeaths }
]

let CENTER_PANEL_BOTTOM = [
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_TIPS | HUD_FLAGS.NO_BIG_MAP, comp = actionsRoot }
  { flags = HUD_FLAGS.MINIMAL | HUD_FLAGS.SHOW_TIPS, comp = artillery_ratio_tip }
  { flags = HUD_FLAGS.MINIMAL, comp = friendly_fire_warning }

  { flags = HUD_FLAGS.TUTORIAL | HUD_FLAGS.FULL, comp = playerEventsRoot }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = lieDownToShootAccuratelyTip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = hasToChargeTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = cannotDigAtPosTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_GAME_MODE_HINTS, comp = ammoDepletedInTank }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = lie_down_to_save_from_expl_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.NO_BIG_MAP | HUD_FLAGS.SHOW_TIPS, comp = actionsRoot }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = throw_grenade_tip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = melee_charge_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = artillery_ratio_tip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = vehicleResupplyTip }
  { flags = HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = spectatorKeys }
  { flags = HUD_FLAGS.FULL, comp = friendly_fire_warning }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = pushObjectTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = paratroopersSupplyBoxTip }
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.SHOW_TIPS, comp = grenadeRethrowTip }
]

let RIGHT_PANEL_TOP = [
  { flags = HUD_FLAGS.FULL | HUD_FLAGS.PLAYER_UI, comp = hitcamera }
]

let RIGHT_PANEL_MIDDLE = [
  { flags = HUD_FLAGS.PLAYER_UI | HUD_FLAGS.NO_TUTORIAL | HUD_FLAGS.FULL | HUD_FLAGS.NO_BIG_MAP, comp = killLog }
]

let RIGHT_PANEL_BOTTOM = [
  { flags = HUD_FLAGS.NO_MINIMALIST | HUD_FLAGS.PLAYER_UI, comp = playerDynamic }
]

let function setHudLayout(...) {
  logHUD($"hudFlags = {hudFlags.value}")

  /// Left Panel
  hudLayoutState.leftPanelTop(LEFT_PANEL_TOP.map(mkHudElement))
  hudLayoutState.leftPanelMiddle(LEFT_PANEL_MIDDLE.map(mkHudElement))
  hudLayoutState.leftPanelBottom(LEFT_PANEL_BOTTOM.map(mkHudElement))

  /// Center Panel
  hudLayoutState.centerPanelTop(CENTER_PANEL_TOP.map(mkHudElement))
  hudLayoutState.centerPanelMiddle(CENTER_PANEL_MIDDLE.map(mkHudElement))
  hudLayoutState.centerPanelBottom(CENTER_PANEL_BOTTOM.map(mkHudElement))

  /// Right Panel
  hudLayoutState.rightPanelTop(RIGHT_PANEL_TOP.map(mkHudElement))
  hudLayoutState.rightPanelMiddle(RIGHT_PANEL_MIDDLE.map(mkHudElement))
  hudLayoutState.rightPanelBottom(RIGHT_PANEL_BOTTOM.map(mkHudElement))
}
setHudLayout()
hudFlags.subscribe(setHudLayout)
