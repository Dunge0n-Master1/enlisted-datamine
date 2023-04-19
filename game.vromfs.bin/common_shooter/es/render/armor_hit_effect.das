require ecs
require ecs.common
require game.es.events
require math
require math.base
require DngDm
require fx
require common_shooter.events_common_shooter

[es(tag=render)]
def on_armor_hit_fx_effect(evt : EventOnEntityHit)
  query(evt.victim) <| $ [es] ([[shared_comp]] visual_armor_hit__fxEffects : Array)
    let armorMult : float = evt.armorMult
    if evt.deltaHp > 0.0 && evt.damageType == int(DamageType DM_PROJECTILE) && armorMult < 1.0
      for it in visual_armor_hit__fxEffects
        let obj = get_ecs_object(it)
        let name = get_string(obj, "fxName", "")
        if name != "" && get_float(obj, "armorAmount") ?? 0.0 <= 1.0 - armorMult
          var tm : float3x4
          let hitDir = normalize(-evt.hitDir)
          tm[1] = hitDir
          tm[2] = cross(hitDir, float3(0., 1., 0.))
          tm[0] = cross(hitDir, tm[2])
          tm[3] = evt.hitPos + hitDir * 0.05
          createEntity(name) <| $(init)
            set(init, "transform", tm)
          break
