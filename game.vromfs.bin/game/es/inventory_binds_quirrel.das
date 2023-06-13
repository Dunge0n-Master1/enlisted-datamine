require game.es.inventory_common
require ecs.ecs_quirrel
require game.utils.hero


[quirrel_bind(module_name="das.inventory")]
def drop_weap_from_slot(slot_name : string)
  inventory_common::drop_weap_from_slot2(get_controlled_hero(), slot_name)


[quirrel_bind(module_name="das.inventory")]
def pickup_item_to_weap_slot(eid : EntityId; slot_name : string)
  inventory_common::pickup_item_to_weap_slot2(get_controlled_hero(), eid, slot_name)


[quirrel_bind(module_name="das.inventory")]
def pickup_and_install_item_on_weap(mod_eid : EntityId; weapon_slot_name, weap_mod_slot_name : string)
  inventory_common::pickup_and_install_item_on_weap2(get_controlled_hero(), mod_eid, weapon_slot_name, weap_mod_slot_name)
