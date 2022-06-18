require danetlibs.wounds.render.burning_common
require danetlibs.wounds.render.wounds_events
require ecs
require EnlistedDm

enum BurningState : int
  BURNING_UNBURNED = 0
  BURNING_DAMAGED = 1
  BURNING_DEAD = 2

[es(tag=render)]
def fire_death_material_change_es(evt : EventEntityDied; var burning__burnedEffectState : int&; attaches_list : EidList)

  if evt.damageType == int(DamageType DM_FIRE)
    set_burning_params(burning__burnedEffectState, attaches_list, int(BurningState BURNING_DEAD))

[es(tag=render)]
def fire_damage_material_change_es(evt : EventOnEntityHit; eid : EntityId; var burning__burnedEffectState : int&; attaches_list : EidList)

  if burning__burnedEffectState == int(BurningState BURNING_UNBURNED) && evt.victim == eid && evt.damageDesc.damageType == DamageType DM_FIRE
    set_burning_params(burning__burnedEffectState, attaches_list, int(BurningState BURNING_DAMAGED))
