require ecs
require app
require net
require enlisted.events_enlisted
require game.es.events
require EnlistedHuman
require HumanPhys
require DagorSystem
require game.events_game

def private get_item_use_time(item : EntityId; is_downed : bool; is_self_targeting : bool)
  var useTime = -1f
  var hasUseTime = false
  if is_self_targeting
    query(item) <| $ [es] (item__useTime : float; item__downedTimeMultiplier : float = 1f)
      useTime = item__useTime  * (is_downed ? item__downedTimeMultiplier : 1f)
      hasUseTime = true
  else
    query(item) <| $ [es] (item__useTimeToTarget : float; item__downedTimeMultiplier : float = 1f)
      useTime = item__useTimeToTarget * (is_downed ? item__downedTimeMultiplier : 1.f)
      hasUseTime = true
  if hasUseTime && useTime < 0f
    let compName = is_self_targeting ? "useTime" : "useTimeToTarget"
    logerr("item.{compName} < 0 {getEntityTemplateName(item)}")
  return useTime

[es(tag=server, REQUIRE=human_inventory)]
def inventory_use_item_server_es(evt : EventUseItem;
                                 eid : EntityId;
                                 isAlive : bool;
                                 var human_net_phys : HumanActor&;
                                 var human_inventory__targetToUse : EntityId&;
                                 var human_inventory__entityUseStart : float&;
                                 var human_inventory__entityUseEnd : float&;
                                 fortification_repair__active : bool;
                                 entity_mods__itemUseTimeMult : float = 1f;
                                 entity_mods__targetUseTimeMult : float = 1f;
                                 human_inventory__canUseItems : bool = true;
                                 hitpoints__canSelfReviveByHealing : bool = false;
                                 hitpoints__canSelfReviveByPerk : bool = false;
                                 isDowned : bool = false;
                                 var human_inventory__entityToUse : EntityId&)// todo: optional
  let item = evt.item
  if !item
    return

  if item == human_inventory__entityToUse || fortification_repair__active
    sendEventImmediate(eid, [[EventInterruptItemUse]])
    return

  if !isAlive
    return

  if !doesEntityExist(item)
    sendEventImmediate(eid, [[EventInterruptItemUse]])
    return

  if !human_inventory__canUseItems || (isDowned && !hitpoints__canSelfReviveByHealing && !hitpoints__canSelfReviveByPerk)
    sendEvent(eid, [[EventOnActionDisabled action="use_locked"]])
    return

  if human_inventory__entityToUse == item
    return

  if human_inventory__entityToUse != INVALID_ENTITY_ID
    sendEventImmediate(eid, [[EventInterruptItemUse]])

  let target = evt.target
  let isSelfTargeting = target == INVALID_ENTITY_ID || target == eid
  var useTime = get_item_use_time(item, isDowned, isSelfTargeting)
  if useTime <= 0f
    return
  human_net_phys.phys.currentState |> human_phys_state_set_stoppedSprint(true)
  useTime = max(0.1f, useTime * (isSelfTargeting ? entity_mods__itemUseTimeMult : entity_mods__targetUseTimeMult))
  let curTime = get_sync_time()
  human_inventory__entityUseEnd = curTime + useTime
  human_inventory__entityUseStart = curTime
  human_inventory__entityToUse = item
  human_inventory__targetToUse = target == INVALID_ENTITY_ID ? eid : target
  sendEventImmediate(human_inventory__entityToUse, [[EventOnItemStartUse target=human_inventory__targetToUse]])
  query(human_inventory__targetToUse) <| $ [es] (var hitpoints__revivingCount : int&; isDowned : bool)
    if isDowned
      hitpoints__revivingCount = max(0, hitpoints__revivingCount) + 1

[es(tag=netClient, REQUIRE=human_inventory)]
def inventory_use_item_client_es(evt : EventUseItem;
                                 eid : EntityId;
                                 hitpoints__canSelfReviveByPerk : bool = false;
                                 human_inventory__canUseItems : bool = true;
                                 human_inventory__entityToUse : EntityId) // todo: optional
  let item = evt.item
  if !item
    return

  if item == human_inventory__entityToUse
    sendEventImmediate(eid, [[EventInterruptItemUse]])
    return

  if human_inventory__canUseItems || hitpoints__canSelfReviveByPerk
    send_net_event(eid, [[HumanUseItemRequest item=item, target=evt.target]])
    return
  sendEvent(eid, [[EventOnActionDisabled action="use_locked"]])

[es(tag=server, REQUIRE=human_inventory)]
def inventory_use_item_request_es(evt : HumanUseItemRequest; eid : EntityId)
  sendEvent(eid, [[EventUseItem item=evt.item, target=evt.target]])
