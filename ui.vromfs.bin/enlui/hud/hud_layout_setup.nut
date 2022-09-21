from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("state/hudGameModes.nut")
let hudLayoutState = require("%ui/hud/state/hud_layout_state.nut")
let maintenanceProgress = require("%ui/hud/huds/maintenance_progress_hint.nut")
let bombSiteProgress = require("%ui/hud/huds/bomb_site_progress_hint.nut")
let ammoRequestCooldown = require("huds/ammo_request_cooldown_hint.nut")
let vehicleSeats = require("huds/vehicle_seats.ui.nut")
let vehicleChangeSeats = require("huds/vehicle_change_seats.nut")
let pushObjectTip = require("huds/push_object_tip.nut")
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
  minimalistHud, showBattleChat, showSelfAwards
} = require("%ui/hud/state/hudOptionsState.nut")
let {showSquadSpawn} = require("%ui/hud/state/respawnState.nut")
let {playerDeaths} = require("huds/player_deaths.nut")
let {tkWarning} = require("huds/team_kills.nut")
let {text} = require("%ui/components/text.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")

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
    watch = minHud
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = minHud.value
      ? [localTeamEnemyHint].extend(wallposterActions)
      : [].extend(planeTakeOffTips,
                  [medicHealTip, maintenanceHint, mainAction, localTeamEnemyHint, vehicleFreeSeatTip],
                  vehicleActions, buildingActions, wallposterActions)
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

let function tutorialHudLayout(){
  let chat = hasServiceMessages.value ? serviceMessages
    : showChat.value ? chatRoot
    : null
  /// Left Panel
  hudLayoutState.leftPanelTop([planeHud, vehicleHud])
  hudLayoutState.leftPanelMiddle([chat, vehicleSeats, squadMembersUi, artilleryOrderUi])
  hudLayoutState.leftPanelBottom([minimap_mod])

  /// Center Panel
  hudLayoutState.centerPanelTop([hints, warnings, noRespawnTip, vehicleChangeSeats,
    enterVehicleIndicator, exitVehicleIndicator])

  hudLayoutState.centerPanelMiddle([
    outsideBattleAreaWarning, vehicleWarnings, vehicleRepair, maintenanceProgress,
    fortificationRepairProgress, bombSiteProgress, ammoRequestCooldown, putOutFire,
    fortificationAction,playerDeaths])

  hudLayoutState.centerPanelBottom([
        playerEventsRoot, cannotDigAtPosTip, ammoDepletedInTank, actionsRoot,
        throw_grenade_tip, artillery_ratio_tip, vehicleResupplyTip,
        spectatorKeys, friendly_fire_warning, pushObjectTip
    ])

  /// Right Panel
  hudLayoutState.rightPanelTop([hitcamera])
  hudLayoutState.rightPanelBottom([playerDynamic])
}

let function setHudLayout(...) {
  let isHudMinimal = minHud.value
  let onlyFull = isHudMinimal ? @(_list) [] : @(list) list
  let chat = hasServiceMessages.value ? serviceMessages
    : showChat.value ? chatRoot
    : null
  let mnlstHud = minimalistHud.value

  if (isTutorial.value){
    tutorialHudLayout()
    return
  }
  /// Left Panel
  hudLayoutState.leftPanelTop(showSquadSpawn.value ? null : onlyFull([planeHud, vehicleHud]))
  hudLayoutState.leftPanelMiddle(isHudMinimal ? [chat] : [chat, squadMembersUi, artilleryOrderUi])
  hudLayoutState.leftPanelBottom((minimalistHud.value || showSquadSpawn.value)
    ? []
    : [!forcedMinimalHud.value ? vehicleSeats : null, minimap_mod])

  /// Center Panel
  hudLayoutState.centerPanelTop(isHudMinimal
    ? [gameMode, spectatorMode_tip, noRespawnTip, vehicleChangeSeats, enterVehicleIndicator, exitVehicleIndicator]
    : [gameMode, hints, warnings, spectatorMode_tip, noRespawnTip, vehicleChangeSeats,
        enterVehicleIndicator, exitVehicleIndicator])

  hudLayoutState.centerPanelMiddle(isHudMinimal
    ? [
        playerEventsRoot, vehicleRepair, maintenanceProgress, fortificationRepairProgress, bombSiteProgress,
        tkWarning, putOutFire, fortificationAction, playerDeaths
      ]
    : [
        outsideBattleAreaWarning, playerEventsRoot,
        vehicleWarnings, vehicleRepair, maintenanceProgress, fortificationRepairProgress,
        bombSiteProgress, tkWarning, ammoRequestCooldown, putOutFire,
        fortificationAction, showSelfAwards.value ? awards : null, playerDeaths
      ]
  )

  hudLayoutState.centerPanelBottom(!isHudMinimal
    ? [
        lieDownToShootAccuratelyTip, hasToChargeTip,
        cannotDigAtPosTip, ammoDepletedInTank, lie_down_to_save_from_expl_tip,
        showBigMap.value ? null : actionsRoot, throw_grenade_tip, melee_charge_tip, artillery_ratio_tip,
        vehicleResupplyTip, spectatorKeys, friendly_fire_warning,
        pushObjectTip
      ]
    : [ actionsRoot, artillery_ratio_tip, friendly_fire_warning])

  /// Right Panel
  hudLayoutState.rightPanelTop(onlyFull([hitcamera]))
  hudLayoutState.rightPanelMiddle(onlyFull(showBigMap.value ? [] : [killLog]))
  hudLayoutState.rightPanelBottom(mnlstHud ? [] : [playerDynamic])
}
setHudLayout()
foreach (s in [showChat, minHud, minimalistHud, forcedMinimalHud, showSelfAwards, showSquadSpawn,
                showBigMap, isTutorial, hasServiceMessages])
  s.subscribe(setHudLayout)
