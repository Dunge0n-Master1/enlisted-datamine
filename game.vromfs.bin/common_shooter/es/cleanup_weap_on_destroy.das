require ecs
require DngWeapon

[es(on_disappear, tag=server)]
def destroy_ammo_holder_in_real_gun_es(evt : Event; gun__ammoHolderEid : ecs::EntityId)
  if gun__ammoHolderEid != INVALID_ENTITY_ID
    destroyEntity(gun__ammoHolderEid)

[es(on_disappear, tag=server, REQUIRE=item__weapTemplate)]
def destroy_ammo_holder_on_ground_es(evt : Event; var customProps : Object)
  human_gun_custom_props_cleanup(customProps)
