require ecs
require common_shooter.events_common_shooter
require weapon_sounds.modules.weapon_sounds_events
require BallisticsProps

[es(tag=sound)]
def projectile_hit_scene_sound(evt : EventProjectileHitScene;
                               eid : EntityId;
                               projectile__exploded : bool;
                               projectile_ballistics_props : ProjectileProps)
  sendEventImmediate(eid, [[CmdPlayProjectileHitSceneSound
                            pos=evt.pos,
                            pmid=evt.matId,
                            caliber=projectile_ballistics_props.caliber,
                            ricochet=evt.ricochetAngle,
                            exploded=projectile__exploded]])
