import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { Point3 } = require("dagor.math")
let {
  sendNetEvent,
  RequestSquadMateOrder, RequestOpenArtilleryMap, CmdShowArtilleryCooldownHint, RqCancelContextCommand, CmdHeroLogEvent
} = require("dasevents")
let { pieMenuItems } = require("%ui/hud/state/pie_menu_state.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
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
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { get_controlled_hero } = require("%dngscripts/common_queries.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { quickChatCommands } = require("quickchat_menu.nut")
let colorize = require("%ui/components/colorize.nut")
let { SquadMateOrder } = require("%enlSqGlob/dasenums.nut")

let pieMenuTextItemCtor = require("components/pieMenuTextItemCtor.nut")

let noMembersColor = 0xFFFF6060

let hasActive = Computed(@() localPlayerSquadMembers.value
  .findvalue(@(m) m.eid != controlledHeroEid.value && m.isAlive) != null)
let available = Computed(@() hasActive.value && !inVehicle.value)
let notAvailable = Computed(@() !available.value)
let noMembersText = Computed(@() hasActive.value ? null
  : colorize(noMembersColor, loc("msg/noAliveMembersToOrder")))

let sendCmd = @(orderType)
  sendNetEvent(ecs.obsolete_dbg_get_comp_val(controlledHeroEid.value, "squad_member__squad", ecs.INVALID_ENTITY_ID),
    RequestSquadMateOrder({orderType, orderPosition=Point3(), orderUseEntity=ecs.INVALID_ENTITY_ID}))

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
  action = @() sendCmd(SquadMateOrder.ESMO_BRING_AMMO)
  disabledAction = @() showMsg(requestAmmoReason.value)
  text = Computed(@() "\n".concat(loc("squad_orders/bring_ammo"), cantRequestAmmoText.value ?? ""))
  disabledtext = Computed(@() noMembersText.value ?? cantRequestAmmoText.value ?? loc("pieMenu/actionUnavailable"))
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
    ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdHeroLogEvent({event="artillery", text="artillery/team_limit_reached", sound="", ttl=0}))
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
  action = @() sendCmd(SquadMateOrder.ESMO_HEAL)
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
})

pieMenuItems([
  [],
  [
    cmdFollowMe
    cmdBringAmmo
    cmdHeal
    cmdArtillery
  ],
  quickChatCommands
])
