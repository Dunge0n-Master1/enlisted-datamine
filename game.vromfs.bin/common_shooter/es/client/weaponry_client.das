require ecs
require common_shooter.events_common_shooter
require game.events_game
require EnlistedWeaponRender
require DaWeapons
require BallisticsProps


[es(tag=gameClient, REQUIRE_NOT=disableRIBulletHole)]
def projectile_bullet_hole_client_es(evt : CmdRendinstBulletHole;
                                     projectile_ballistics_props : ProjectileProps)
  add_projectile_bullet_hole(evt.handle, evt.pos, evt.norm, evt.pmid, projectile_ballistics_props.caliber)
