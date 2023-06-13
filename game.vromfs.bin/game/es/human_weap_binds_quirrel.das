require common_shooter.es.human_weap_common
require ecs.ecs_quirrel
require game.utils.hero


[quirrel_bind(module_name="das.human_weap")]
def swap_weapons_in_slots(from_slot_name, to_slot_name : string)
  human_weap_common::swap_weapons_in_slots2(get_controlled_hero(), from_slot_name, to_slot_name)


[quirrel_bind(module_name="das.human_weap")]
def remove_item_from_weap_to_inventory(weapon_slot_name, weapon_mod_slot_name : string)
  human_weap_common::remove_item_from_weap2(get_controlled_hero(), weapon_slot_name, weapon_mod_slot_name, false)


[quirrel_bind(module_name="das.human_weap")]
def remove_item_from_weap_to_ground(weapon_slot_name, weapon_mod_slot_name : string)
  human_weap_common::remove_item_from_weap2(get_controlled_hero(), weapon_slot_name, weapon_mod_slot_name, true)


[quirrel_bind(module_name="das.human_weap")]
def swap_weapon_mods(from_slot, from_weap_mod_slot, to_slot, to_weap_mod_slot : string)
  human_weap_common::swap_weapon_mods2(get_controlled_hero(), from_slot, from_weap_mod_slot, to_slot, to_weap_mod_slot)
