require ecs
require ecs.common
require game.es.events
require game.es.inventory_common
require game.utils.team
require math.base
require DagorMath
require HumanPhys
require DagorSystem

struct MagazinesCount
  current : int
  partial : int

struct ResupplyMagazinePrice
  count : int
  price : int

def is_ammo_for_gun(ammo_template; ammo_holders_templates)
  for ammo_holder_template in ammo_holders_templates
    let holder = get_string(ammo_holder_template, "")
    if holder != "" && ammo_template == holder
      return true
  return false


def refill_ammo(requester; count; ammoTemplate)
  for i in range(0, count)
    push_item_in_cont(requester, ammoTemplate)
  return count > 0

def private get_magazines_count(ammo_holders; ammo_in_gun; max_ammo_in_magazine; item_container)
  var magazines = [[MagazinesCount
    current=(ammo_in_gun <= 0 ? 0 : 1),
    partial=0
  ]]

  for itemEid in item_container
    query(itemEid) <| $ [es] (item__template : das_string; ammo_holder__ammoCount : int)
      if !is_ammo_for_gun(string(item__template), ammo_holders)
        return
      magazines.current++
      if ammo_holder__ammoCount < max_ammo_in_magazine
        magazines.partial++

  return magazines

def private ammo_resupply_price(max_magazines; requires_refill_count; refill_count; max_refill_count)
  let relativeRequiredResupplies = float(requires_refill_count) * float(refill_count) / float(max_magazines)
  let require_price = ceili(relativeRequiredResupplies)
  if max_refill_count < require_price
    return [[ResupplyMagazinePrice
      count=ceili(float(refill_count) * (float(refill_count) / float(requires_refill_count))),
      price=require_price
    ]]

  return [[ResupplyMagazinePrice
    count=refill_count,
    price=require_price
  ]]

def resupply_magazines(requester;
                       var itemContainer &;
                       box_use_count;
                       requires_refill_count;
                       holder_ammo_count;
                       gun__ammo_holders : Array;
                       gun__ammo : int;
                       gun__num_reserve_ammo : int;
                       gun__reserve_ammo_template : string)
  var requiredResupplies = 0
  let magazines = get_magazines_count(gun__ammo_holders, gun__ammo, holder_ammo_count, itemContainer)
  var possibleResupply = ammo_resupply_price(gun__num_reserve_ammo, requires_refill_count, max(gun__num_reserve_ammo - magazines.current, 0), box_use_count)
  if possibleResupply.count > 0
    requiredResupplies += possibleResupply.price
    refill_ammo(requester, possibleResupply.count, gun__reserve_ammo_template)

  // Refill partial magazines(not full)
  possibleResupply = ammo_resupply_price(gun__num_reserve_ammo, requires_refill_count, magazines.partial, box_use_count)
  if possibleResupply.count > 0
    requiredResupplies += possibleResupply.price
    refill_ammo(requester, possibleResupply.count, gun__reserve_ammo_template)
    // remove magazines from inventory
    var i = length(itemContainer) - 1
    while i >= 0
      if possibleResupply.count <= 0
        break
      query(itemContainer[i]) <| $ [es] (item__template : das_string; ammo_holder__ammoCount : int)
        if !is_ammo_for_gun(string(item__template), gun__ammo_holders) || ammo_holder__ammoCount >= holder_ammo_count
          return
        destroyEntity(itemContainer[i])
        itemContainer |> erase(i)
        --possibleResupply.count
      --i
  return requiredResupplies

def has_grenade(itemContainer)
  for item in itemContainer
    if has(item, "item__grenadeType")
      return true
  return false


def try_to_refill_grenades(requester, grenadeTemplate)
  if grenadeTemplate == ""
    return false
  var isAmmoRefilled = true
  ecs::query(requester) <| $ [es] (itemContainer : EidList)
    isAmmoRefilled &&= !has_grenade(itemContainer)
    isAmmoRefilled &&= refill_ammo(requester, 1, grenadeTemplate)
  return isAmmoRefilled


def has_ammo_holder(gun_eid; item_template)
  var hasHolder = false
  query(gun_eid) <| $ [es] (gun__ammoHolders : Array)
    if is_ammo_for_gun(item_template, gun__ammoHolders) // item id and ammo holder is same
      hasHolder = true
      return

  return hasHolder


def try_to_refill_ammo(requester; box_use_count; box_team)
  var hasStoledWeapon = false
  var spentResources = 0
  var isFriendlyBox = false
  query(requester) <| $ [es] (var itemContainer : EidList&; human_weap__gunEids : ecs::EidList; team : int)
    isFriendlyBox = is_teams_friendly(team, box_team)
    for slotId in [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY; HUWeaponSlots EWS_TERTIARY]]
      query(human_weap__gunEids[int(slotId)]) <| $ [es(REQUIRE_NOT=itemInWeaponSlot)] (gun__ammoHolders : Array;
                                                                                       item__ownedByTeam : int;
                                                                                       gun__ammo : int;
                                                                                       gun__numReserveAmmo : int;
                                                                                       gun__reserveAmmoTemplate : string)
        if item__ownedByTeam != box_team
          hasStoledWeapon = true
          return

        if gun__numReserveAmmo <= 0
          return

        let ammoTplComp = gun__reserveAmmoTemplate |> getTemplateByName
        if ammoTplComp == null
          logerr("Template '{gun__reserveAmmoTemplate}' not exist in entity '{getEntityTemplateName(human_weap__gunEids[int(slotId)])}'")
          return

        let holderAmmoCount = *ammoTplComp |> getTemplateComponent("ammo_holder__ammoCount") |> get_int ?? 0
        if holderAmmoCount <= 0
          logerr("<{requester}> ammo_holder.ammoCount is less than or equal to 0 in template: {gun__reserveAmmoTemplate}")
          return

        let ammoRefillsCount = max(1, get_int(getTemplateComponent(*ammoTplComp, "requiresAmmoRefillsCount")) ?? 1)
        spentResources += resupply_magazines(requester, itemContainer, box_use_count, ammoRefillsCount, holderAmmoCount,
          gun__ammoHolders, gun__ammo, gun__numReserveAmmo, gun__reserveAmmoTemplate)

  if hasStoledWeapon
    let text = isFriendlyBox ? "resupply/cant_refill_picked_weapon" : "resupply/cant_refill_friendly_weapon_from_enemy_box"
    sendEvent(requester, [[CmdHeroLogEvent event="cant_refill_picked_weapon", text=text]])
  elif spentResources <= 0
    sendEvent(requester, [[CmdHeroLogEvent event="ammo_full", text="resupply/ammo_full"]])

  return spentResources

[es(tag=server, track=useful_box__useCount, REQUIRE=ammunitionBox)]
def ammo_box_on_refill_es(evt : Event;
                          useful_box__maxUseCount : int;
                          useful_box__useCount : int;
                          maxCostReturnedOnDestructionMul : float;
                          var costReturnedOnDestructionMul : float&)
  let ammoFullness = safediv(float(useful_box__useCount), float(useful_box__maxUseCount))
  costReturnedOnDestructionMul = maxCostReturnedOnDestructionMul * ammoFullness

[es(tag=server, before=useful_box_use_finish_es, REQUIRE=ammunitionBox)]
def ammo_box_resupply_ammo_es(evt : CmdUseUsefulBox;
                              useful_box__useCount : int;
                              team : int;
                              var useful_box__requiredUseCount : int&;
                              var useful_box__successUse : bool&)
  useful_box__requiredUseCount = try_to_refill_ammo(evt.requesterEid, useful_box__useCount, team)
  useful_box__successUse ||= useful_box__requiredUseCount > 0

[es(tag=server, before=useful_box_use_finish_es, REQUIRE=ammunitionBox)]
def ammo_box_resupply_grenade_es(evt : CmdUseUsefulBox;
                                 var useful_box__successUse : bool&;
                                 var useful_box__requiredUseCount : int&;
                                 grenadeResupplyItem : string)
  useful_box__requiredUseCount = 1
  let success = try_to_refill_grenades(evt.requesterEid, grenadeResupplyItem)
  useful_box__successUse ||= success

[es(tag=server, on_appear, track=human_weap__gunEids)]
def human_weapon_set_gun_info_es(evt : Event; team : int; human_weap__gunEids : EidList; human_weap__weapInfo : Array)
  let gunCount = min(length(human_weap__gunEids), length(human_weap__weapInfo))
  for i in range(gunCount)
    query(human_weap__gunEids[i]) <| $ [es] (var gun__initialComponents : Object&;
                                             var item__ownedByTeam : int&;
                                             var gun__reserveAmmoTemplate : das_string&;
                                             var gun__numReserveAmmo : int&)
      if item__ownedByTeam != TEAM_UNASSIGNED
        return

      let weapInfo = get_ecs_object(human_weap__weapInfo[i])
      item__ownedByTeam = team
      gun__reserveAmmoTemplate := get_string(weapInfo, "reserveAmmoTemplate", "")
      gun__numReserveAmmo = get_int(weapInfo, "numReserveAmmo") ?? 0
      gun__initialComponents |> set("item__ownedByTeam", item__ownedByTeam)
      gun__initialComponents |> set("gun__numReserveAmmo", gun__numReserveAmmo)
      gun__initialComponents |> set("gun__reserveAmmoTemplate", gun__reserveAmmoTemplate)

[es(tag=server, on_appear, track=gun__owner)]
def weapon_set_initial_gun_info_es(evt : Event;
                                   eid : EntityId;
                                   gun__owner : EntityId;
                                   var gun__initialComponents : Object&;
                                   var item__ownedByTeam : int&;
                                   var gun__reserveAmmoTemplate : das_string&;
                                   var gun__numReserveAmmo : int&)
  if item__ownedByTeam != TEAM_UNASSIGNED
    return

  query(gun__owner) <| $ [es] (team : int; human_weap__gunEids : EidList; human_weap__weapInfo : Array)
    let weapIndex = find_index(human_weap__gunEids, eid)
    if weapIndex <= -1 || weapIndex >= length(human_weap__weapInfo)
      return

    let weapInfo = get_ecs_object(human_weap__weapInfo[weapIndex])
    item__ownedByTeam = team
    gun__reserveAmmoTemplate := get_string(weapInfo, "reserveAmmoTemplate", "")
    gun__numReserveAmmo = get_int(weapInfo, "numReserveAmmo") ?? 0
    gun__initialComponents |> set("item__ownedByTeam", item__ownedByTeam)
    gun__initialComponents |> set("gun__numReserveAmmo", gun__numReserveAmmo)
    gun__initialComponents |> set("gun__reserveAmmoTemplate", gun__reserveAmmoTemplate)
