import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { Point3 } = require("dagor.math")
let { RequestSquadMateOrder, CmdHeroLogEvent } = require("gameevents")
let { RequestOpenArtilleryMap, CmdShowArtilleryCooldownHint, RqCancelContextCommand } = require("dasevents")
let { CmdWallposterPreview } = require("wallposterevents")
let { pieMenuItems, showPieMenu } = require("%ui/hud/state/pie_menu_state.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { isDowned, isAlive, hp, maxHp } = require("%ui/hud/state/health_state.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")
let { hasPrimaryWeapon } = require("%ui/hud/state/hero_weapons.nut")
let { isAttachedToGun } = require("%ui/hud/state/attached_gun_state.nut")
let { requestAmmoTimeout } = require("state/requestAmmoState.nut")
let { localPlayerSquadMembers } = require("state/squad_members.nut")
let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { isLeaderNeedsAmmo, hasSpaceForMagazine, isCompatibleWeapon } = require("%ui/hud/state/hero_squad.nut")
let { artilleryIsReady, artilleryIsAvailable, artilleryAvailableTimeLeft, isHeroRadioman, wasArtilleryAvailableForSquad
} = require("%ui/hud/state/artillery.nut")
let { isBinocularMode } = require("%ui/hud/state/binocular.nut")
let { wallPostersMaxCount, wallPostersCurCount, wallPosters } = require("%ui/hud/state/wallposter.nut")
let { showWallposterMenu } = require("%ui/hud/state/wallposter_menu.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { get_controlled_hero } = require("%dngscripts/common_queries.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { cmdQuickChat } = require("quickchat_menu.nut")
let colorize = require("%ui/components/colorize.nut")
let { ESMO_BRING_AMMO, ESMO_HEAL, ESFN_CLOSEST, ESFN_STANDARD, ESFN_WIDE } = require("ai")
let { SquadBehaviour } = require("%enlSqGlob/dasenums.nut")
let { get_setting_by_blk_path } = require("settings")

let { forcedMinimalHud, noBotsModeHud } = require("state/hudGameModes.nut")
let { setSquadFormation, squadFormation } = require("state/squad_formation.nut")
let { setSquadBehaviour, squadBehaviour } = require("state/squad_behaviour.nut")
let pieMenuTextItemCtor = require("components/pieMenuTextItemCtor.nut")

let disableQuickChat = get_setting_by_blk_path("gameplay/disable_quick_chat") ?? false

let noMembersColor = 0xFFFF6060

let isControllable = Computed(@() controlledHeroEid.value == watchedHeroEid.value)
let hasActive = Computed(@() localPlayerSquadMembers.value
  .findvalue(@(m) m.eid != controlledHeroEid.value && m.isAlive) != null)
let available = Computed(@() hasActive.value && !inVehicle.value)
let notAvailable = Computed(@() !available.value)
let noMembersText = Computed(@() hasActive.value ? null
  : colorize(noMembersColor, loc("msg/noAliveMembersToOrder")))

let sendCmd = @(orderType)
  ecs.g_entity_mgr.sendEvent(ecs.obsolete_dbg_get_comp_val(controlledHeroEid.value, "squad_member__squad", INVALID_ENTITY_ID),
    RequestSquadMateOrder(orderType, Point3(), INVALID_ENTITY_ID))

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

let addTextCtor = @(cmd) cmd.__merge({
  ctor = pieMenuTextItemCtor({
    text = cmd.text, available = cmd?.available ?? Watched(true), isBlocked = cmd?.isBlocked ?? Watched(false)
  })
})

let cmdFollowMe = addTextCtor({
  action = @() ecs.g_entity_mgr.sendEvent(controlledHeroEid.value, RqCancelContextCommand({include_personal_orders=true}))
  text = Computed(@() loc("squad_orders/follow"))
  disabledtext = noMembersText
  closeOnClick = true
  available = available
  isBlocked = notAvailable
})

// TODO: move squad behaviour and formation constructors to another file
let squadBehaviourNames = {
  [SquadBehaviour.ESB_AGRESSIVE] = loc("squad_orders/behaviour_agressive", "Aggressive"),
  [SquadBehaviour.ESB_PASSIVE] = loc("squad_orders/behaviour_passive", "Passive")
}

let squadBehaviourDescs = {
  [SquadBehaviour.ESB_AGRESSIVE] = loc("squad_orders/behaviour_agressive/desc"),
  [SquadBehaviour.ESB_PASSIVE] = loc("squad_orders/behaviour_passive/desc")
}

let currentSquadBehaviourText = Computed(@()
  loc("squad_orders/current_behaviour", {current=squadBehaviourNames[squadBehaviour.value]}))

let squadBehaviourHint = @(behaviour) Computed(@() "\n\n".concat(
  squadBehaviourNames[behaviour],
  squadBehaviourDescs[behaviour],
  currentSquadBehaviourText.value))

let addSquadBehaviourCtor = @(behaviour) addTextCtor({
  action = @() setSquadBehaviour(behaviour)
  disabledAction = @() null
  text = squadBehaviourNames[behaviour]
  disabledtext = noMembersText
  closeOnClick = true
  available = available
  isBlocked = notAvailable
}).__update({text = squadBehaviourHint(behaviour)})

let cmdSquadBehaviour = addTextCtor({
  id = "squadbehaviour_items"
  items = [
    addSquadBehaviourCtor(SquadBehaviour.ESB_AGRESSIVE),
    addSquadBehaviourCtor(SquadBehaviour.ESB_PASSIVE),
  ]
  text = loc("squad_orders/behaviour", "Behaviour")
  closeOnClick = false
  available = available
  isBlocked = notAvailable
})

let squadFormationNames = {
  [ESFN_CLOSEST] = loc("squad_orders/formation_close", "Closest"),
  [ESFN_STANDARD] = loc("squad_orders/formation_standard", "Standard"),
  [ESFN_WIDE] = loc("squad_orders/formation_wide", "Wide")
}

let squadFormationDescs = {
  [ESFN_CLOSEST] = loc("squad_orders/formation_close/desc"),
  [ESFN_STANDARD] = loc("squad_orders/formation_standard/desc"),
  [ESFN_WIDE] = loc("squad_orders/formation_wide/desc")
}

let currentSquadFormationText = Computed(@()
  loc("squad_orders/current_formation", {current=squadFormationNames[squadFormation.value]}))

let squadFormationHint = @(formation) Computed(@() "\n\n".concat(
  squadFormationNames[formation],
  squadFormationDescs[formation],
  currentSquadFormationText.value))

let addSquadFormationCtor = @(formation) addTextCtor({
  action = @() setSquadFormation(formation)
  disabledAction = @() null
  text = squadFormationNames[formation]
  disabledtext = noMembersText
  closeOnClick = true
  available = available
  isBlocked = notAvailable
}).__update({text = squadFormationHint(formation)})

let cmdSquadFormation = addTextCtor({
  id = "squadformation_items"
  items = [
    addSquadFormationCtor(ESFN_CLOSEST),
    addSquadFormationCtor(ESFN_STANDARD),
    addSquadFormationCtor(ESFN_WIDE),
  ]
  text = loc("squad_orders/formation", "Formation")
  closeOnClick = false
  available = available
  isBlocked = notAvailable
})

let canRequestAmmo = Computed(@() isLeaderNeedsAmmo.value
  && requestAmmoTimeout.value <= 0
  && available.value
  && !isAttachedToGun.value)
let cantRequestAmmoText = Computed(@() (isLeaderNeedsAmmo.value && requestAmmoTimeout.value > 0
    ? loc("msg/canRequestIn", { time = secondsToStringLoc(requestAmmoTimeout.value) })
    : null))

let requestAmmoReason = Computed(function() {
  if (isAttachedToGun.value)
    return loc("msg/cannotRequestAmmoWhenMounted")
  if (inVehicle.value)
    return loc("msg/cannotRequestAmmoFromVehicle")
  if (!hasPrimaryWeapon.value)
    return loc("msg/hasNoWeaponForAmmoRequest")
  if (!isCompatibleWeapon.value)
    return loc("msg/cantRequestAmmoForThisWeapon")
  if (!hasSpaceForMagazine.value)
    return loc("msg/hasNoSpaceForMagazine")
  if (requestAmmoTimeout.value > 0)
    return loc("msg/canRequestIn", { time = secondsToStringLoc(requestAmmoTimeout.value) })
  return loc("msg/hasAmmo")
})

let cmdBringAmmo = addTextCtor({
  action = @() sendCmd(ESMO_BRING_AMMO)
  disabledAction = @() showMsg(requestAmmoReason.value)
  text = Computed(@() "\n".concat(loc("squad_orders/bring_ammo"), cantRequestAmmoText.value ?? ""))
  disabledtext = Computed(@() noMembersText.value ?? cantRequestAmmoText.value ?? loc("pieMenu/actionUnavailable"))
  closeOnClick = true
  available = canRequestAmmo
  isBlocked = notAvailable
})


let function artillery_action() {
  ecs.g_entity_mgr.sendEvent(get_controlled_hero(), RequestOpenArtilleryMap())
}

let canRequestArtillery = Computed(@() !isDowned.value
  && artilleryIsReady.value
  && !inVehicle.value
  && (isHeroRadioman.value || available.value))

let cantRequestArtilleryText = Computed(function(){
  if (!wasArtilleryAvailableForSquad.value)
    return loc("squad_orders/artillery_strike")
  return (!isDowned.value && artilleryIsAvailable.value && artilleryAvailableTimeLeft.value > 0
    ? loc("artillery/cooldown", { timeLeft = secondsToStringLoc(artilleryAvailableTimeLeft.value) })
    : !artilleryIsReady.value ? loc("artillery/team_limit_reached")
    : null)
 })

let function showDisabledArtilleryHint() {
  if (!artilleryIsAvailable.value || isDowned.value)
    showMsg(loc("msg/artilleryUnavailable"))
  else if (artilleryAvailableTimeLeft.value > 0)
    ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdShowArtilleryCooldownHint())
  else if (!artilleryIsReady.value)
    ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdHeroLogEvent("artillery", "artillery/team_limit_reached", "", 0))
}

let cmdArtillery = addTextCtor({
  action = @() artillery_action()
  disabledAction = @() showDisabledArtilleryHint()
  text = Computed(@() cantRequestArtilleryText.value ?? loc("squad_orders/artillery_strike") )
  disabledtext = Computed(function() {
    if (!wasArtilleryAvailableForSquad.value)
      return loc("squad_orders/artillery_strike")
    if (isHeroRadioman.value)
      return cantRequestArtilleryText.value ?? loc("pieMenu/actionUnavailable")
    return noMembersText.value ?? cantRequestArtilleryText.value ?? loc("pieMenu/actionUnavailable")
  })
  closeOnClick = true
  available = canRequestArtillery
  isBlocked = Computed(@() (!isHeroRadioman.value && !available.value) || !wasArtilleryAvailableForSquad.value)
})

let healCount = Computed(@() (localPlayerSquadMembers.value ?? [])
  .reduce(@(res, m) m.eid != controlledHeroEid.value && m.isAlive ? res + m.targetHealCount : res, 0))
let reviveCount = Computed(@() (localPlayerSquadMembers.value ?? [])
  .reduce(@(res, m) m.eid != controlledHeroEid.value && m.isAlive ? res + m.targetReviveCount : res, 0))
let canRequestHeal = Computed(@() available.value
  && isAlive.value
  && !isAttachedToGun.value
  && ((isDowned.value && reviveCount.value > 0)
    || ((hp.value ?? 0) < maxHp.value && healCount.value > 0)))
let textWithInfo = @(text, info) $"{text} ({info})"

let cmdHeal = addTextCtor({
  action = @() sendCmd(ESMO_HEAL)
  disabledAction = function() {
    if (isAttachedToGun.value)
      showMsg(loc("msg/cantHealWhenMounted"))
    else if ((hp.value ?? 0) >= maxHp.value)
      showMsg(loc("msg/noNeedHeal"))
    else if (!hasActive.value)
      showMsg(loc("msg/noAliveMembersToOrder"))
    else if (isDowned.value ? reviveCount.value <= 0 : healCount.value <= 0)
      showMsg(loc("msg/noMedkits"))
  }
  text = Computed(@() isDowned.value ? textWithInfo(loc("squad_orders/revive_me"), reviveCount.value)
      : textWithInfo(loc("squad_orders/heal_me"), healCount.value))
  disabledtext = Computed(@() noMembersText.value ?? loc("pieMenu/actionUnavailable"))
  available = canRequestHeal
  isBlocked = notAvailable
  closeOnClick = true
})

let isUnavailableWallposter = Computed(@() !isAlive.value
  || !isControllable.value
  || isDowned.value
  || inVehicle.value
  || wallPostersMaxCount.value == 0
  || isBinocularMode.value)

let canUseWallposter = Computed(@() !isUnavailableWallposter.value
  && wallPostersCurCount.value < wallPostersMaxCount.value)

let cmdWallPoster = addTextCtor({
  action = @() wallPosters.value.len() > 1
    ? showWallposterMenu(true)
    : ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdWallposterPreview(true, 0))
  disabledAction = function() {
    if (wallPostersCurCount.value >= wallPostersMaxCount.value)
      showMsg(loc("wallposter/nomore"))
  }
  text = Computed(@() textWithInfo(loc("wallposter/place"), wallPostersMaxCount.value - wallPostersCurCount.value))
  disabledtext = loc("pieMenu/actionUnavailable")
  available = canUseWallposter
  isBlocked = isUnavailableWallposter
  closeOnClick = true
})

let baseCmds = [
  cmdFollowMe
  cmdBringAmmo
  cmdHeal
  cmdSquadFormation
  cmdSquadBehaviour
]

let specialCmdsPlaces = 1
let curCmds = keepref(Computed(function() {
  let res = []
  if (!noBotsModeHud.value)
    res.extend(baseCmds)

  res.append(cmdArtillery)

  res.append(cmdWallPoster)

  if (!disableQuickChat && !forcedMinimalHud.value) //temporary, until our quickchat has no voice
    res.append(cmdQuickChat.value)

  if (res.len() < specialCmdsPlaces)
    res.resize(specialCmdsPlaces)

  return res
}, FRP_DONT_CHECK_NESTED))

pieMenuItems(curCmds.value)
curCmds.subscribe(function(v) {
  pieMenuItems(v)
  if (v.len() == 0)
    showPieMenu(false)
})
