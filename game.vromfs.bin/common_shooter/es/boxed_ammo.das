require ecs
require ecs.common
require game.es.events
require DagorSystem
require DagorConsole


def refill_boxed_ammo_items(var item_container : EidList;
                            item_eid : EntityId;
                            ammo_holder_id : int;
                            var ammo_count : int&)
  var ammoAdded = false
  for i in iter_range(item_container)
    if item_container[i] == item_eid
      continue
    query(item_container[i]) <| $ [es] (ammo_holder__id : int;
                                        boxed_ammo__maxAmmoCount : int;
                                        var ammo_holder__ammoCount : int&)
      if ammo_holder_id == ammo_holder__id
        if ammo_holder__ammoCount < boxed_ammo__maxAmmoCount
          let ammoToFill = boxed_ammo__maxAmmoCount - ammo_count
          ammo_count += min(ammoToFill, ammo_holder__ammoCount)
          ammo_holder__ammoCount = max(0, ammo_holder__ammoCount - ammoToFill)
          if ammo_holder__ammoCount == 0
            destroyEntity(item_container[i])
            item_container |> erase(i)
          ammoAdded = true
    if ammoAdded
      break


[es(tag=server)]
def refill_boxed_ammo_in_inventory_on_loot_pickup(evt : EventOnLootPickup;
                                                  var itemContainer : EidList)
  query(evt.itemEid) <| $ [es(REQUIRE=ammo_holder__boxedAmmo)] (ammo_holder__id : int;
                                                                boxed_ammo__maxAmmoCount : int;
                                                                var ammo_holder__ammoCount : int&)
    if ammo_holder__ammoCount < boxed_ammo__maxAmmoCount
      refill_boxed_ammo_items(itemContainer, evt.itemEid, ammo_holder__id, ammo_holder__ammoCount)


[es(tag=server, on_appear, track=ammo_holder__ammoCount)]
def recalc_boxed_ammo_weight_and_volume(evt : Event;
                                        boxed_ammo__maxAmmoCount : int;
                                        ammo_holder__ammoCount : int;
                                        boxed_ammo__maxWeight : float;
                                        boxed_ammo__maxVolume : float;
                                        var item__weight : float&;
                                        var item__volume : float&)
  let curRelativeValue = float(ammo_holder__ammoCount) / float(boxed_ammo__maxAmmoCount)
  item__weight = floor(boxed_ammo__maxWeight * curRelativeValue * 10.0) / 10.0 // round to first decimal
  item__volume = floor(boxed_ammo__maxVolume * curRelativeValue * 10.0) / 10.0
