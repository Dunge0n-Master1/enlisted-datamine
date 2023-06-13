require ecs
require game.events_game
require DngWeapon
require common_shooter.es.human_weap_common

[es(tag=server)]
def human_inventory_fill_guns_custom_props_on_death(evt : EventEntityDied; eid : EntityId; human_weap__gunEids : EidList)
  for slot, gunEid in iter_range(human_weap__gunEids), human_weap__gunEids
    query(gunEid) <| $ [es] (var customProps : Object; var item__lastOwner : EntityId&)
      item__lastOwner = eid
      human_gun_to_custom_props2(gunEid, customProps)
      human_gun_mod_to_custom_props2(eid, slot, "", customProps)