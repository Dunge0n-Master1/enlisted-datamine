require ecs
require game.es.vehicle.vehicle_events
require dm

def on_damage_effect(eid : EntityId; is_exploded : bool; effects : int; offender : EntityId; gun_props_id : int; shell_id : int)
  if !is_exploded && (effects & (1 << int(DamageEffectType DM_EFFECT_EXPL))) != 0
    sendEvent(eid, [[CmdExplosionFatal offender=offender, gunPropsId=gun_props_id, shellId=shell_id]])

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_kill_explosion(evt : EventOnPartKillEffects; eid : EntityId; isExploded : bool; vehicle__isExplosionFatal : bool = true)
  if vehicle__isExplosionFatal
    on_damage_effect(eid, isExploded, evt.effects, evt.offender, evt.gunPropsId, evt.shellId)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_damage_explosion(evt : EventOnPartDamageEffects; eid : EntityId; isExploded : bool; vehicle__isExplosionFatal : bool = true)
  if vehicle__isExplosionFatal
    on_damage_effect(eid, isExploded, evt.effects, evt.offender, evt.gunPropsId, evt.shellId)
