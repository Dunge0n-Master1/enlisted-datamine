require ecs
require EnlistedNet
require inventory
require DagorMath
require DagorSystem
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require game.events_game

struct HealingItem
  eid : EntityId
  healAmount : float


def get_fastest_heal_item(item_container : EidList; heal_amount_comp : array<uint>)
  var fastestTime = 1e+06f
  var fastestEid = ecs::INVALID_ENTITY_ID

  for itemEid in item_container
    query(itemEid) <| $ [es(REQUIRE_NOT=item__targetUseOnly)] (item__useTime : float)
      if item__useTime < fastestTime
        for comp in heal_amount_comp
          if has(itemEid, "", comp)
            fastestTime = item__useTime
            fastestEid = itemEid
  return fastestEid


def get_fastest_heal_item(item_container : ecs::Object; heal_amount_comp : array<uint>)
  var fastestTime = 1e+06f
  var fastestEid = ecs::INVALID_ENTITY_ID

  for itemAttr in item_container
    let item = get_ecs_object(itemAttr.value)
    if item == null
      continue
    let itemEid = get_Eid(item, "item") ?? ecs::INVALID_ENTITY_ID
    query(itemEid) <| $ [es(REQUIRE_NOT=item__targetUseOnly)] (item__useTime : float)
      if item__useTime < fastestTime
        for comp in heal_amount_comp
          if has(itemEid, "", comp)
            fastestTime = item__useTime
            fastestEid = itemEid
            break
  return fastestEid


def get_min_summary_wasted_heal_amount(heal_items : array<HealingItem>;
                                       start_index : int;
                                       var needed_heal_amount : float;
                                       max_waste_heal_amount_ratio : float) : float
  var bestWastedAmount = FLT_MAX
  for itemId in range(start_index, length(heal_items))
    let neededAfterUse = needed_heal_amount - heal_items[itemId].healAmount
    if neededAfterUse > 0.0
      needed_heal_amount = neededAfterUse
      continue
    let wastedHealAmount = -neededAfterUse
    if wastedHealAmount < heal_items[itemId].healAmount * max_waste_heal_amount_ratio
      return wastedHealAmount
    bestWastedAmount = min(bestWastedAmount, wastedHealAmount)
  return bestWastedAmount


def get_most_effective_heal_item(item_container : EidList;
                                 needed_heal_amount : float;
                                 max_waste_heal_amount_ratio : float;
                                 heal_amount_comp : array<uint>) : EntityId
  var healItems : array<HealingItem>
  reserve(healItems, length(item_container))

  for itemEid in item_container
    query(itemEid) <| $ [es(REQUIRE_NOT=item__targetUseOnly)] (item__useTime : float)
      if item__useTime <= 0.0
        return
      var healAmount = 0.0
      for comp in heal_amount_comp
        healAmount += get_float(itemEid, "", comp) ?? 0.0
      if healAmount > 0.0
        emplace(healItems, [[HealingItem eid=itemEid, healAmount=healAmount]])

  if length(healItems) == 0
    return INVALID_ENTITY_ID

  sort(healItems) <| $(lhs, rhs : HealingItem&)
    return lhs.healAmount > rhs.healAmount // descending

  for itemId in iter_range(healItems)
    assume item = healItems[itemId]
    let wastedHp = item.healAmount - needed_heal_amount
    if wastedHp <= item.healAmount * max_waste_heal_amount_ratio
      return item.eid

    let remainingChainSize = length(healItems) - (itemId + 1)
    if remainingChainSize == 0
      return item.eid

    let remainingChainWastedAmount = get_min_summary_wasted_heal_amount(healItems, itemId + 1, needed_heal_amount, max_waste_heal_amount_ratio)
    if wastedHp < remainingChainWastedAmount
      return item.eid

  logerr("get_most_effective_heal_item: can't find most effective item")
  return healItems[0].eid


[es]
def human_inventory_medkit_es(evt : CmdMedkitUse;
                              eid : ecs::EntityId;
                              itemContainer : EidList;
                              hitpoints__hp : float;
                              hitpoints__maxHp : float;
                              isAlive : bool;
                              human_inventory__entityToUse : EntityId;
                              maintenance__canMaintainVehicle : bool;
                              extinguisher__hasExtinguisher : bool;
                              repair__hasRepairKit : bool;
                              maintenance__targetNeedsExtinguishing : bool = false;
                              maintenance__targetNeedsRepair : bool = false;
                              isInVehicle : bool = false;
                              burning__isBurning : bool = false;
                              isDowned : bool = false;
                              hitpoints__criticalHpRatio : float = 0.1;
                              hitpoints__maxHealAmountWasteRatio : float = 0.2)
  let extinguishAvailable = maintenance__canMaintainVehicle && extinguisher__hasExtinguisher && maintenance__targetNeedsExtinguishing
  let repairAvailable = maintenance__canMaintainVehicle && repair__hasRepairKit && maintenance__targetNeedsRepair

  if extinguishAvailable || repairAvailable
    return

  if burning__isBurning
    if !isInVehicle
      send_net_event(eid, [[CmdPutOutFireStart]])
    return
  let needHp = hitpoints__maxHp - max(hitpoints__hp, 0.f)
  if !isAlive || (needHp < 1e-06f && hitpoints__hp > hitpoints__criticalHpRatio)
    return

  let healAmountComp <- isDowned ? [{auto[] ecs_hash("item__reviveAmount")}] : [{auto[] ecs_hash("item__healAmount")}]
  var bestItem : EntityId = INVALID_ENTITY_ID
  if length(itemContainer) != 0
    let criticalHpLevel = hitpoints__maxHp * hitpoints__criticalHpRatio
    if isDowned || hitpoints__hp < criticalHpLevel
      bestItem = get_fastest_heal_item(itemContainer, healAmountComp)
    else
      let neededHealAmount = hitpoints__maxHp - hitpoints__hp
      bestItem = get_most_effective_heal_item(itemContainer, neededHealAmount, hitpoints__maxHealAmountWasteRatio, healAmountComp)
  if bestItem != ecs::INVALID_ENTITY_ID && bestItem != human_inventory__entityToUse
    sendEvent(eid, [[EventUseItem item=bestItem, target=INVALID_ENTITY_ID]])


[es]
def human_inventory_medkit_cancel_es(evt : CmdMedkitUseCancel; eid : ecs::EntityId)
  send_net_event(eid, [[CmdPutOutFireStop]])
  inventory::stop_use_item(eid)

[es(tag=server, on_appear, track=item__ownerEid, REQUIRE_NOT=item__targetUseOnly)]
def apply_medkit_owner_perks(evt : Event;
                             item__ownerEid : EntityId;
                             var item__useTime : float&;
                             var item__healAmount : float&;
                             var item__reviveAmount : float&;
                             item__minUseTime : float = 0.1)
  query(item__ownerEid) <| $ [es] (entity_mods__healAmountMult : float = 1.0;
                                   entity_mods__medkitUseTimeMult : float = 1.0)
    item__useTime = max(item__useTime * entity_mods__medkitUseTimeMult, item__minUseTime)
    item__healAmount *= entity_mods__healAmountMult
    item__reviveAmount *= entity_mods__healAmountMult

[es(tag=server, on_appear, track=item__ownerEid, REQUIRE=item__targetUseOnly)]
def apply_medkit_target_heal_owner_perks(evt : Event;
                                         item__ownerEid : EntityId;
                                         var item__useTimeToTarget : float&;
                                         var item__healAmount : float&;
                                         var item__reviveAmount : float&;
                                         item__minUseTime : float = 0.1)
  query(item__ownerEid) <| $ [es] (entity_mods__healAmountTargetMult : float = 1.0;
                                   entity_mods__medkitUseTimeTargetMult : float = 1.0)
    item__useTimeToTarget = max(item__useTimeToTarget * entity_mods__medkitUseTimeTargetMult, item__minUseTime)
    item__healAmount *= entity_mods__healAmountTargetMult
    item__reviveAmount *= entity_mods__healAmountTargetMult

[es(tag=server, on_appear, track=item__ownerEid, REQUIRE=(item__healAmount, item__targetUseOnly))]
def apply_medic_more_medpack_uses_perk(evt : Event;
                                       item__ownerEid : EntityId;
                                       var item__useCount : int&)
  query(item__ownerEid) <| $ [es] (entity_mods__medicMedpacksMult : float)
    item__useCount = int(float(item__useCount) * entity_mods__medicMedpacksMult)
    sendEvent(item__ownerEid, [[EventUpdatedItemContainer]])
