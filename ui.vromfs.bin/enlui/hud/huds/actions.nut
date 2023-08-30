import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
/*
  attention - this is very poor code, as it coupling different games
*/

let {pickupItemName, pickupItemEid, useActionEid, lookAtEid, lookAtVehicle, useActionAvailable, customUsePrompt} = require("%ui/hud/state/actions_state.nut")
let {inVehicle, inPlane, isSafeToExit, isPlayerCanEnter, isPlayerCanExit, isVehicleAlive} = require("%ui/hud/state/vehicle_state.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {teammatesAliveNum} = require("%ui/hud/state/human_teammates.nut")
let {sendItemHint} = require("%ui/hud/huds/send_quick_chat_msg.nut")
let {isDowned} = require("%ui/hud/state/health_state.nut")
let isMachinegunner = require("%ui/hud/state/machinegunner_state.nut")
let {localPlayerEid, localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {round_by_value} = require("%sqstd/math.nut")
let {sound_play} = require("%dngscripts/sound_system.nut")
let { is_fast_pickup_item } = require("das.inventory")
let {CmdSetMarkMain} = require("dasevents")
let {
  ACTION_USE, ACTION_REQUEST_AMMO, ACTION_RECOVER, ACTION_PICK_UP, ACTION_SWITCH_WEAPONS,
  ACTION_OPEN_DOOR, ACTION_CLOSE_DOOR, ACTION_REMOVE_SPRAY, ACTION_DENIED_TOO_MUCH_WEIGHT,
  ACTION_LOOT_BODY, ACTION_OPEN_WINDOW, ACTION_CLOSE_WINDOW, ACTION_REVIVE_TEAMMATE } =  require("hud_actions")
let {localTeamEnemyHint} = require("%ui/hud/huds/enemy_hint.nut")
let { isInHatch } = require("%ui/hud/state/hero_in_vehicle_state.nut")

let showTeamQuickHint = Watched(true)
let teamHintsQuery = ecs.SqQuery("teamHintsQuery", {comps_ro =[["team__id", ecs.TYPE_INT],["team__showQuickHint", ecs.TYPE_BOOL, true]]})
let findPromptQuery = ecs.SqQuery("findPromptQuery", {comps_ro = [["item__customUsePrompt", ecs.TYPE_STRING]]})

localPlayerEid.subscribe(function(v) {
  if ( v != ecs.INVALID_ENTITY_ID ) {
    teamHintsQuery.perform(function (_eid, comp) {
        showTeamQuickHint(comp["team__showQuickHint"])
      },
      $"eq(team__id, {localPlayerTeam.value})"
    )
  }
})

let function getItemPrice(entity_eid) {
    let price = ecs.obsolete_dbg_get_comp_val(entity_eid, "coinPricePerGame")
    if (price) {
      let discount = ecs.obsolete_dbg_get_comp_val(localPlayerEid.value, "coinsGameMult") ?? 1.0;
      return round_by_value(price * discount, 1).tointeger()
    }
    return price
}


let pickupkeyId = "Inventory.Pickup"
let forcedPickupkeyId = "Inventory.ForcedPickup"
let usekeyId = "Human.Use"

let actionsMap = {
  [ACTION_USE] = {
                    textf = function (item) {
                              if (item.usePrompt && item.usePrompt.len() > 0)
                                return loc(item.usePrompt, "Press to use")

                              let objectPrompt = ecs.obsolete_dbg_get_comp_val(item.useEid, "item__customUsePrompt", "")
                              if (objectPrompt && objectPrompt.len() > 0)
                                return loc(objectPrompt, "Press to use")

                              return loc("hud/use", "Press to use")
                            }
                    key = usekeyId
  },
  [ACTION_REQUEST_AMMO] = {text = loc("hud/request_ammo", "Request ammo") key = usekeyId},
  [ACTION_PICK_UP] = {
                        keyf = @(item) is_fast_pickup_item(item.eid) ? pickupkeyId : forcedPickupkeyId ,
                        textf = function (item) {
                          let count = ecs.obsolete_dbg_get_comp_val(item.eid, "item__count")
                          let altText = loc($"{item.itemName}/pickup", {count = count, price = getItemPrice(item.eid), nickname = loc("teammate")}, "")
                          if (altText && altText.len() > 0)
                            return altText
                          return is_fast_pickup_item(item.eid)
                            ? loc("hud/pickup", "Pickup {item}", item)
                            : loc("hud/replaceItem", "Switch to {item}", item)
                        }
                      },
  [ACTION_RECOVER] = {text = loc("hud/recover", "Recover"), key = usekeyId},
  [ACTION_SWITCH_WEAPONS] = {
                              keyf = @(item) is_fast_pickup_item(item.eid) ? pickupkeyId : forcedPickupkeyId ,
                              textf = @(params) loc("hud/switch_weapons", "Switch weapon to {item}", params)
                             },
  [ACTION_OPEN_DOOR] = {text = loc("hud/open_door", "Open door"), key=usekeyId},
  [ACTION_CLOSE_DOOR] = {text = loc("hud/close_door", "Close door"), key=usekeyId},
  [ACTION_REMOVE_SPRAY] = {text = loc("hud/remove_spray", "Remove spray"), key=usekeyId},
  [ACTION_DENIED_TOO_MUCH_WEIGHT] = {
    textf = function(params) {
      params.item = params.item.subst({ nickname = loc("teammate") })
      return loc("hud/too_much_weight_pickip", "Can't pickup {item} - too much weight", params)
    }
    textColor = Color(120, 120, 120, 120)
  },
  [ACTION_LOOT_BODY] = {text = loc("hud/loot_body", "Loot body") key = usekeyId},
  [ACTION_OPEN_WINDOW] = {text = loc("hud/open_window", "Open window"), key=usekeyId},
  [ACTION_CLOSE_WINDOW] = {text = loc("hud/close_window", "Close window"), key=usekeyId},
  [ACTION_REVIVE_TEAMMATE] = {text = loc("hud/revive_teammate", "Revive teammate"), key=usekeyId},
}

let triggerBlinkAnimations = {}
let listnerForPickupAction = {
  eventHandlers = {["Inventory.Pickup"] = @(...) anim_start(triggerBlinkAnimations),}
}
let blinkAnimations = [
  { prop=AnimProp.translate, from=[0,0], to=[hdpx(20),0], duration=0.7, trigger = triggerBlinkAnimations, easing=Shake4, onEnter = @() sound_play("ui/enlist/login_fail")}
]

let showExitAction = Computed(
  @()(!inPlane.value || isSafeToExit.value ) && isPlayerCanExit.value && isVehicleAlive.value && !isInHatch.value
)

let function mainAction() {
  let res = {
    size = SIZE_TO_CONTENT
    watch = [isDowned, pickupItemEid, pickupItemName, useActionAvailable, inVehicle, showExitAction, useActionEid, customUsePrompt, isPlayerCanEnter, isPlayerCanExit]
  }
  if (isDowned.value)
    return res

  local children = []
  let curAction = useActionAvailable.value
  let actScheme = actionsMap?[curAction]
  local text = actScheme?.text
  local isVisible = true
  if (text == null && "textf" in actScheme) {
    text = actScheme.textf({ eid=pickupItemEid.value,
                             item=loc(pickupItemName.value),
                             itemName=pickupItemName.value,
                             useEid=useActionEid.value,
                             usePrompt = customUsePrompt.value})
  }
  local key = actScheme?.key
  if (key == null && "keyf" in actScheme) {
    key = actScheme.keyf({ eid=pickupItemEid.value,
                           useEid=useActionEid.value })
  }
  if (curAction == ACTION_USE && inVehicle.value) {
    text = loc("hud/leaveVehicle")
    isVisible = showExitAction.value
  }
  if (curAction == ACTION_USE && lookAtVehicle.value && !isPlayerCanEnter.value && !inVehicle.value) {
    let customUsePromt = ecs.obsolete_dbg_get_comp_val(useActionEid.value, "vehicle__brokenUsePrompt")
    isVisible = customUsePromt && customUsePromt.len() > 0
    text = loc(customUsePromt)
    key = null
  }
  if (curAction == ACTION_USE) {
    findPromptQuery(useActionEid.value, function(_, comp){
      let customUsePromt = comp["item__customUsePrompt"]
      isVisible = customUsePromt.len() > 0
      text = loc(customUsePromt)
    })
  }

  children = !isVisible ? [] : [tipCmp({
    text = text
    inputId = key
    textColor = actScheme?.textColor ?? DEFAULT_TEXT_COLOR
    extraAnimations = blinkAnimations
  })]

  if (curAction == ACTION_SWITCH_WEAPONS || key == forcedPickupkeyId)
    children.append(listnerForPickupAction)
  return res.__update({ children  })
}

let function getUseActionEntityName(entity_eid) {
  let vehicleTag = ecs.obsolete_dbg_get_comp_val(entity_eid, "vehicle", null)
  if (vehicleTag != null)
    return !inVehicle.value ? "hud/teammates_vehicle_hint" : null

  let stationaryGunTag = ecs.obsolete_dbg_get_comp_val(entity_eid, "stationary_gun", null)
  if (stationaryGunTag != null)
    return !isMachinegunner.value ? "hud/stationary_gun_hint" : null
  let interactableName = ecs.obsolete_dbg_get_comp_val(entity_eid, "interactable__name", null)
  if (interactableName != null)
    return $"hud/interactable_hint/{interactableName}"
  return null
}

let function sendTeamHint(useHintEid, _event){
  if (pickupItemEid.value != ecs.INVALID_ENTITY_ID) {
    sendItemHint(pickupItemName.value, pickupItemEid.value,
      ecs.obsolete_dbg_get_comp_val(pickupItemEid.value, "item__count"), loc("teammate"))
    return
  }
  if (useHintEid != ecs.INVALID_ENTITY_ID) {
    let name = getUseActionEntityName(useHintEid)
    if (name != null) {
      sendItemHint(name, useHintEid, 1, "")
      return
    }
  }
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdSetMarkMain())
}

let function localTeamHint(){
  local children = {}
  local useHintEid = ecs.INVALID_ENTITY_ID;
  if ((pickupItemName.value ?? "") != "" && teammatesAliveNum.value > 0) {
    children = tipCmp({
      text = loc("squad/send_item_hint", {item = loc(pickupItemName.value),
                                            count=ecs.obsolete_dbg_get_comp_val(pickupItemEid.value, "item__count"),
                                            nickname=loc("teammate")})
      inputId = "HUD.QuickHint"
      textColor = DEFAULT_TEXT_COLOR
    })
  } else {
    useHintEid = useActionEid.value != ecs.INVALID_ENTITY_ID ? useActionEid.value : lookAtEid.value;
    if (useHintEid && teammatesAliveNum.value > 0) {
      let name = getUseActionEntityName(useHintEid)
      if (name != null) {
        children = tipCmp({
          text = loc("squad/send_item_hint", {item = loc(name), count=1, nickname = loc("teammate")})
          inputId = "HUD.QuickHint"
          textColor = DEFAULT_TEXT_COLOR
        })
      }
    }
  }
  children.__update({eventHandlers = {["HUD.QuickHint"] = curry(sendTeamHint)(useHintEid)}})
  return {
    children = showTeamQuickHint.value ? children : null
    watch = [showTeamQuickHint, teammatesAliveNum, pickupItemName, pickupItemEid, useActionEid, lookAtEid, inVehicle, isMachinegunner]
    size = SIZE_TO_CONTENT
  }
}


let mkActionsRoot = @(actions) @() {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM

  children = {
    size=SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = actions
  }
}

return {
  mkActionsRoot
  mainAction
  localTeamHint
  localTeamEnemyHint

  allActions = mkActionsRoot([mainAction, localTeamHint, localTeamEnemyHint])
}