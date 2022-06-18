require ecs
require game.events_game
require EnlistedWeapon

[es(tag=server)]
def human_inventory_fill_guns_custom_props_on_death(evt : EventEntityDied; eid : EntityId; human_weap__gunEids : EidList)
  for slot, gunEid in iter_range(human_weap__gunEids), human_weap__gunEids
    query(gunEid) <| $ [es] (var customProps : Object?; var item__lastOwner : EntityId&)
      if customProps != null
        item__lastOwner = eid
        human_gun_to_custom_props(gunEid, *customProps)
        human_gun_mod_to_custom_props(eid, slot, "", customProps)