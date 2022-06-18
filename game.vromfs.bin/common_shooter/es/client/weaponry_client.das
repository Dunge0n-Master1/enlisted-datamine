require ecs
require common_shooter.events_common_shooter
require game.events_game
require EnlistedWeaponRender
require DaWeapons
require BallisticsProps


[es(tag=gameClient)]
def projectile_bullet_hole_client_es(evt : CmdRendinstBulletHole;
                                     projectile_ballistics_props : ProjectileProps)
  add_projectile_bullet_hole(evt.handle, evt.pos, evt.norm, evt.pmid, projectile_ballistics_props.caliber)


[es(tag=gameClient)]
def projectile_hit_scene_es(evt : EventProjectileHitScene;
                            launch_desc : LaunchDesc)
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    let vel = float3()
    on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), evt.matId, evt.pos, vel, evt.norm)
