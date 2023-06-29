require ecs
require ecs.safe
require ecs.common
require game.es.events
require game.es.inventory_common
require game.es.weapon_refill_ammo_common
require enlisted.events_enlisted
require DngNet
require HumanPhys


def resupply_vehicle_passenger(requester : EntityId)
  var resupplied = false
  query(requester) <| $ [es] (human_weap__gunEids : ecs::EidList;
                              team aka requester_team : int;
                              var itemContainer : EidList&)
    for slotId in [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY; HUWeaponSlots EWS_TERTIARY]]
      let gunEid = human_weap__gunEids[int(slotId)]
      query(gunEid) <| $ [es(REQUIRE_NOT=itemInWeaponSlot)] (gun__ammoHolders : Array;
                                                             gun__curAmmoHolderIndex : int;
                                                             item__ownedByTeam : int;
                                                             gun__ammo : int;
                                                             gun__numReserveAmmo : int;
                                                             gun__reserveAmmoTemplate : string;
                                                             gun__additionalReserveAmmoTemplates : StringList;
                                                             gun__additionalNumReserveAmmos : IntList)
        if item__ownedByTeam != requester_team
          return

        var ammoHolders : array<string>
        for ammoHolder in gun__ammoHolders
          push(ammoHolders, ammoHolder ?? "")

        if gun__numReserveAmmo > 0
          let ammoHolderIdx = find_index(ammoHolders, gun__reserveAmmoTemplate)
          let ammoInGun = (ammoHolderIdx == gun__curAmmoHolderIndex) ? gun__ammo : 0

          resupplied ||= refill_ammo_for_gun(requester, gunEid,
                                             ammoInGun,
                                             gun__reserveAmmoTemplate,
                                             gun__numReserveAmmo,
                                             itemContainer) <| $(itemTemplate)
            return is_ammo_for_gun(itemTemplate, gun__ammoHolders) && find_index(gun__additionalReserveAmmoTemplates, itemTemplate) < 0

        for ammoTemplateStr, ammoNum in gun__additionalReserveAmmoTemplates, gun__additionalNumReserveAmmos
          if ammoNum <= 0
            continue


          peek(ammoTemplateStr) <| $(ammoTemplate)
            let ammoHolderIdx = find_index(ammoHolders, string(ammoTemplateStr))
            let ammoInGun = (ammoHolderIdx == gun__curAmmoHolderIndex) ? gun__ammo : 0

            resupplied ||= refill_ammo_for_gun(requester, gunEid, ammoInGun, ammoTemplate, ammoNum, itemContainer) <| $(itemTemplate)
              return itemTemplate == ammoTemplate
  return resupplied


def resupply_passengers_ammo(vehicle_eid : EntityId;
                             vehicle_seats__seatEids : EidList;
                             condition : block<(soldierKind : string) : bool>)
  for seat in vehicle_seats__seatEids
    let soldier = get_Eid(seat, "seat__ownerEid") ?? INVALID_ENTITY_ID
    query(soldier) <| $ [es] (soldier__sKind : string)
      if invoke(condition, soldier__sKind)
        if resupply_vehicle_passenger(soldier)
          send_net_event(soldier, [[CmdResupplyPassengersFinished vehicle=vehicle_eid]])


[es(tag=server, on_event=CmdResupplyPassengers, REQUIRE=isTank)]
def resupply_tankist_ammo_on_server(evt : Event;
                                    eid aka vehicle_eid : EntityId;
                                    vehicle_seats__seatEids : EidList)
  resupply_passengers_ammo(vehicle_eid, vehicle_seats__seatEids) <| $(soldierKind : string)
    return soldierKind == "tanker"


[es(tag=server, on_event=CmdResupplyPassengers, REQUIRE=bike)]
def resupply_bikers_ammo_on_server(evt : Event;
                                   eid aka vehicle_eid : EntityId;
                                   vehicle_seats__seatEids : EidList)
  resupply_passengers_ammo(vehicle_eid, vehicle_seats__seatEids) <| $(soldierKind : string)
    return soldierKind == "biker" || soldierKind == "engineer"
