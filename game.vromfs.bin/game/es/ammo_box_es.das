require ecs
require ecs.safe
require ecs.common
require game.es.events
require game.es.inventory_common
require game.utils.team
require math.base
require DagorMath
require HumanPhys
require DagorSystem
require danetlibs.native_dasevents.main.native_events


struct MagazinesCount
  current : int
  partial : int


struct ResupplyGunPrice
  magazines : int
  boxUses : int


struct ResupplyGunResult
  emptyMagazinesRefilled : int
  partialMagazinesRefilled : int
  boxUses : int


enum RefillAmmoStatus
  SUCCESS
  FAIL_INCOMPATIBLE_FRIENDLY_GUN
  FAIL_INCOMPATIBLE_ENEMY_GUN
  FAIL_AMMO_FULL
  FAIL_EMPTY_BOX


struct RefillAmmoResult
  boxUses : int
  status : RefillAmmoStatus


def is_ammo_for_gun(ammo_template; ammo_holders_templates)
  for ammo_holder_template in ammo_holders_templates
    let holder = get_string(ammo_holder_template, "")
    if holder != "" && ammo_template == holder
      return true
  return false


def refill_ammo(requester; count; ammoTemplate)
  for _i in range(0, count)
    push_item_in_cont(requester, ammoTemplate)
  return count > 0

def private get_magazines_count(ammo_in_gun : int;
                                max_ammo_in_magazine : int;
                                item_container : EidList;
                                is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  var magazines = [[MagazinesCount
    current=(ammo_in_gun <= 0 ? 0 : 1),
    partial=0
  ]]

  for itemEid in item_container
    query(itemEid) <| $ [es] (item__template : string; ammo_holder__ammoCount : int)
      if !invoke(is_suitable_ammo_cb, item__template)
        return
      magazines.current++
      if ammo_holder__ammoCount < max_ammo_in_magazine
        magazines.partial++

  return magazines


def private calculate_resupply_gun_price(max_magazines : int;
                                         requires_refill_count : int;
                                         wanted_magazines : int;
                                         box_use_count : int)
  let tolerance = 0.0001 //in ceili operations we want a number like 123.0000045 to turn into 123, not 124
  let boxUsesPerMag = safediv(float(requires_refill_count), float(max_magazines))
  var ret = [[ResupplyGunPrice
    magazines = wanted_magazines,
    boxUses   = ceili(boxUsesPerMag * float(wanted_magazines) - tolerance)
  ]]

  if box_use_count < ret.boxUses
    //if box_use_count is less than what we want, our weapon gets only partially resupplied
    let coeff = safediv(float(box_use_count), float(ret.boxUses))
    ret.magazines = ceili(coeff * float(ret.magazines) - tolerance)
    ret.boxUses   = box_use_count

  return ret


def resupply_gun_check(box_use_count : int;
                       requires_refill_count : int;
                       holder_ammo_count : int;
                       ammo_in_gun : int;
                       max_magazines : int;
                       item_container : EidList;
                       is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  let magazines = get_magazines_count(ammo_in_gun, holder_ammo_count, item_container, is_suitable_ammo_cb)

  if magazines.current > max_magazines
    return [[ResupplyGunResult
      partialMagazinesRefilled = 0,
      emptyMagazinesRefilled = 0,
      boxUses = 0
    ]]

  let emptyMagazines = max_magazines - magazines.current
  let price = calculate_resupply_gun_price(max_magazines, requires_refill_count, emptyMagazines + magazines.partial, box_use_count)
  let partialMagsRefilled = max(price.magazines - emptyMagazines, 0)

  return [[ResupplyGunResult
    partialMagazinesRefilled = partialMagsRefilled,
    emptyMagazinesRefilled = price.magazines - partialMagsRefilled,
    boxUses = price.boxUses
  ]]


def resupply_gun(resupply_result : ResupplyGunResult;
                 requester : EntityId;
                 holder_ammo_count : int;
                 reserve_ammo_template : string;
                 var item_container : EidList&;
                 is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  let magazinesRefilled = resupply_result.emptyMagazinesRefilled + resupply_result.partialMagazinesRefilled
  if magazinesRefilled <= 0
    return

  refill_ammo(requester, magazinesRefilled, reserve_ammo_template)

  // remove partial magazines from inventory which were replaced by full magazines from the box
  var i = length(item_container) - 1
  var numPartialMagsToBeRemoved = resupply_result.partialMagazinesRefilled

  while i >= 0
    if numPartialMagsToBeRemoved <= 0
      break
    query(item_container[i]) <| $ [es] (item__template : string; ammo_holder__ammoCount : int)
      if !invoke(is_suitable_ammo_cb, item__template) || ammo_holder__ammoCount >= holder_ammo_count
        return
      destroyEntity(item_container[i])
      item_container |> erase(i)
      --numPartialMagsToBeRemoved
    --i


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


def try_refill_ammoholder_for_gun(requester_eid : EntityId;
                                  gun_eid : EntityId;
                                  gun_ammo : int;
                                  ammo_template : string implicit;
                                  ammo_num : int;
                                  var new_box_use_count : int&;
                                  var item_container : EidList;
                                  is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  let ammoTplComp = ammo_template |> getTemplateByName
  if ammoTplComp == null
    logerr("Template '{ammo_template}' not exist in entity '{getEntityTemplateName(gun_eid)}'")
    return

  let holderAmmoCount = *ammoTplComp |> getTemplateComponent("ammo_holder__ammoCount") |> get_int ?? 0
  if holderAmmoCount <= 0
    logerr("<{requester_eid}> ammo_holder.ammoCount is less than or equal to 0 in template: {ammo_template}")
    return

  let ammoRefillsCount = max(1, get_int(getTemplateComponent(*ammoTplComp, "requiresAmmoRefillsCount")) ?? 1)

  let resupplyResult = resupply_gun_check(new_box_use_count,
                                          ammoRefillsCount,
                                          holderAmmoCount,
                                          gun_ammo,
                                          ammo_num,
                                          item_container,
                                          is_suitable_ammo_cb)

  new_box_use_count -= resupplyResult.boxUses

  resupply_gun(resupplyResult,
               requester_eid,
               holderAmmoCount,
               ammo_template,
               item_container,
               is_suitable_ammo_cb)


def try_to_refill_ammo(requester; box_use_count; box_team)
  var newBoxUseCount = box_use_count
  var isFriendlyBox = false
  var incompatibleGunFailed = false
  var ret = [[RefillAmmoResult
    boxUses = 0,
    status = RefillAmmoStatus SUCCESS
  ]]

  query(requester) <| $ [es] (var itemContainer : EidList&; human_weap__gunEids : ecs::EidList; team aka requester_team : int)
    isFriendlyBox = is_teams_friendly(requester_team, box_team)

    for slotId in [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY; HUWeaponSlots EWS_TERTIARY]]
      if newBoxUseCount <= 0
        break

      query(human_weap__gunEids[int(slotId)]) <| $ [es(REQUIRE_NOT=itemInWeaponSlot)] (gun__ammoHolders : Array;
                                                                                       gun__curAmmoHolderIndex : int;
                                                                                       item__ownedByTeam : int;
                                                                                       gun__ammo : int;
                                                                                       gun__numReserveAmmo : int;
                                                                                       gun__reserveAmmoTemplate : string;
                                                                                       gun__additionalReserveAmmoTemplates : StringList;
                                                                                       gun__additionalNumReserveAmmos : IntList)
        if item__ownedByTeam != box_team
          incompatibleGunFailed = true
          return

        var ammoHolders : array<string>
        for ammoHolder in gun__ammoHolders
          push(ammoHolders, ammoHolder ?? "")

        if gun__numReserveAmmo > 0
          let ammoHolderIdx = find_index(ammoHolders, gun__reserveAmmoTemplate)
          let ammoInGun = (ammoHolderIdx == gun__curAmmoHolderIndex) ? gun__ammo : 0
          try_refill_ammoholder_for_gun(requester,
                                        human_weap__gunEids[int(slotId)],
                                        ammoInGun,
                                        gun__reserveAmmoTemplate,
                                        gun__numReserveAmmo,
                                        newBoxUseCount,
                                        itemContainer) <| $(itemTemplate)
            return is_ammo_for_gun(itemTemplate, gun__ammoHolders) && find_index(gun__additionalReserveAmmoTemplates, itemTemplate) < 0

        for ammoTemplateStr, ammoNum in gun__additionalReserveAmmoTemplates, gun__additionalNumReserveAmmos
          if ammoNum <= 0
            continue

          peek(ammoTemplateStr) <| $(ammoTemplate)
            let ammoHolderIdx = find_index(ammoHolders, string(ammoTemplateStr))
            let ammoInGun = (ammoHolderIdx == gun__curAmmoHolderIndex) ? gun__ammo : 0
            try_refill_ammoholder_for_gun(requester,
                                          human_weap__gunEids[int(slotId)],
                                          ammoInGun,
                                          ammoTemplate,
                                          ammoNum,
                                          newBoxUseCount,
                                          itemContainer) <| $(itemTemplate)
              return itemTemplate == ammoTemplate

  ret.boxUses = box_use_count - newBoxUseCount

  if box_use_count <= 0
    ret.status = RefillAmmoStatus FAIL_EMPTY_BOX
  elif ret.boxUses <= 0
    if incompatibleGunFailed
      ret.status = isFriendlyBox ? RefillAmmoStatus FAIL_INCOMPATIBLE_ENEMY_GUN : RefillAmmoStatus FAIL_INCOMPATIBLE_FRIENDLY_GUN
    else
      ret.status = RefillAmmoStatus FAIL_AMMO_FULL

  return ret

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
                              team aka box_team : int;
                              var useful_box__requiredUseCount : int&;
                              var useful_box__successUse : bool&)
  let refillAmmoResult = try_to_refill_ammo(evt.requesterEid, useful_box__useCount, box_team)

  useful_box__requiredUseCount = refillAmmoResult.boxUses
  useful_box__successUse ||= refillAmmoResult.status == RefillAmmoStatus SUCCESS

  if refillAmmoResult.status == RefillAmmoStatus FAIL_AMMO_FULL
    sendEvent(evt.requesterEid, [[CmdHeroLogEvent event="ammo_full", text="resupply/ammo_full"]])
  elif refillAmmoResult.status == RefillAmmoStatus FAIL_INCOMPATIBLE_FRIENDLY_GUN
    sendEvent(evt.requesterEid, [[CmdHeroLogEvent event="cant_refill_picked_weapon", text="resupply/cant_refill_friendly_weapon_from_enemy_box"]])
  elif refillAmmoResult.status == RefillAmmoStatus FAIL_INCOMPATIBLE_ENEMY_GUN
    sendEvent(evt.requesterEid, [[CmdHeroLogEvent event="cant_refill_picked_weapon", text="resupply/cant_refill_picked_weapon"]])

[es(tag=server, before=useful_box_use_finish_es, REQUIRE=ammunitionBox)]
def ammo_box_resupply_grenade_es(evt : CmdUseUsefulBox;
                                 var useful_box__successUse : bool&;
                                 var useful_box__requiredUseCount : int&;
                                 grenadeResupplyItem : string)
  useful_box__requiredUseCount = 1
  let success = try_to_refill_grenades(evt.requesterEid, grenadeResupplyItem)
  useful_box__successUse ||= success


def try_fill_additional_ammo_templates(weap_info : Object const?; var additional_ammo_templates : StringList)
  clear(additional_ammo_templates)

  let additionalReserveAmmoTemplates = weap_info?.additionalReserveAmmoTemplates ?as Array
  if additionalReserveAmmoTemplates != null
    clear(additional_ammo_templates)
    for ammoTemplateItem in *additionalReserveAmmoTemplates
      push(additional_ammo_templates, ammoTemplateItem ?? "")


def try_fill_additional_ammo_nums(weap_info : Object const?; var additional_ammo_nums : IntList)
  clear(additional_ammo_nums)

  let additionalNumReserveAmmos = weap_info?.additionalNumReserveAmmos ?as Array
  if additionalNumReserveAmmos != null
    clear(additional_ammo_nums)
    for ammoNumItem in *additionalNumReserveAmmos
      push(additional_ammo_nums, ammoNumItem ?? 0)


[es(tag=server, on_appear, track=human_weap__gunEids)]
def human_weapon_set_gun_info_es(evt : Event; team : int; human_weap__gunEids : EidList; human_weap__weapInfo : Array)
  let gunCount = min(length(human_weap__gunEids), length(human_weap__weapInfo))
  for i in range(gunCount)
    query(human_weap__gunEids[i]) <| $ [es] (var gun__initialComponents : Object&;
                                             var item__ownedByTeam : int&;
                                             var gun__reserveAmmoTemplate : das_string&;
                                             var gun__numReserveAmmo : int&;
                                             var gun__additionalReserveAmmoTemplates : StringList;
                                             var gun__additionalNumReserveAmmos : IntList)
      if item__ownedByTeam != TEAM_UNASSIGNED
        return

      let weapInfo = get_ecs_object(human_weap__weapInfo[i])
      item__ownedByTeam = team
      gun__reserveAmmoTemplate := get_string(weapInfo, "reserveAmmoTemplate", "")
      gun__numReserveAmmo = get_int(weapInfo, "numReserveAmmo") ?? 0
      try_fill_additional_ammo_templates(weapInfo, gun__additionalReserveAmmoTemplates)
      try_fill_additional_ammo_nums(weapInfo, gun__additionalNumReserveAmmos)

      gun__initialComponents |> set("item__ownedByTeam", item__ownedByTeam)
      gun__initialComponents |> set("gun__numReserveAmmo", gun__numReserveAmmo)
      gun__initialComponents |> set("gun__reserveAmmoTemplate", gun__reserveAmmoTemplate)
      gun__initialComponents |> set("gun__additionalReserveAmmoTemplates", gun__additionalReserveAmmoTemplates)
      gun__initialComponents |> set("gun__additionalNumReserveAmmos", gun__additionalNumReserveAmmos)

[es(tag=server, on_appear, track=gun__owner)]
def weapon_set_initial_gun_info_es(evt : Event;
                                   eid : EntityId;
                                   gun__owner : EntityId;
                                   var gun__initialComponents : Object&;
                                   var item__ownedByTeam : int&;
                                   var gun__reserveAmmoTemplate : das_string&;
                                   var gun__numReserveAmmo : int&;
                                   var gun__additionalReserveAmmoTemplates : StringList;
                                   var gun__additionalNumReserveAmmos : IntList)
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
    try_fill_additional_ammo_templates(weapInfo, gun__additionalReserveAmmoTemplates)
    try_fill_additional_ammo_nums(weapInfo, gun__additionalNumReserveAmmos)

    gun__initialComponents |> set("item__ownedByTeam", item__ownedByTeam)
    gun__initialComponents |> set("gun__numReserveAmmo", gun__numReserveAmmo)
    gun__initialComponents |> set("gun__reserveAmmoTemplate", gun__reserveAmmoTemplate)
    gun__initialComponents |> set("gun__additionalReserveAmmoTemplates", gun__additionalReserveAmmoTemplates)
    gun__initialComponents |> set("gun__additionalNumReserveAmmos", gun__additionalNumReserveAmmos)
