require danetlibs.wounds.render.burning_common
require ecs
require DngDm

enum BurningState : int
  BURNING_UNBURNED = 0
  BURNING_DAMAGED = 1
  BURNING_DEAD = 2

[es(tag=render, track=burning__isBurning)]
def fire_damage_material_change_es(evt : Event; burning__isBurning : bool; attaches_list : EidList)
  if burning__isBurning
    set_burning_params(attaches_list, int(BurningState BURNING_DAMAGED))

[es(tag=render, REQUIRE=deadEntity, on_appear)]
def fire_death_material_change_es(evt : Event; burning__isBurning : bool; attaches_list : EidList)
  if burning__isBurning
    set_burning_params(attaches_list, int(BurningState BURNING_DEAD))

