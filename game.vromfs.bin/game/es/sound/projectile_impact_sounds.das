require ecs
require BallisticsProps
require common_shooter.events_common_shooter
require sound_utils.modules.sound_physmat_common
require soundEvent
require strings


let LARGE_CALIBER_THRESHOLD = 0.025
def play_sound(hit_or_explode_path : string;
               caliber : float;
               ricochet : float;
               pmid : int;
               pos : float3)
  var path = hit_or_explode_path
  if path == "autoSelect"
    let isBullet = caliber < LARGE_CALIBER_THRESHOLD
    path = isBullet ? "bullet" : "shell"

  if !empty(path)
    let smid = int(get_projectile_sound_material_id(pmid))
    oneshot(path == "bullet" ? "[rico={ricochet};cal={caliber};mat={smid}]impact/{path}" : "[cal={caliber};mat={smid}]impact/{path}", pos)


[es(tag=sound)]
def projectile_impact_sounds_on_hit_scene(evt : EventProjectileHitScene;
                                          projectile_ballistics_props : ProjectileProps;
                                          projectile__exploded : bool;
                                          projectile_sound__hit : string;
                                          projectile_sound__explode : string)
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    play_sound(projectile__exploded ? projectile_sound__explode : projectile_sound__hit,
                projectile_ballistics_props.caliber,
                0.,
                evt.matId,
                evt.pos)


[es(tag=sound)]
def projectile_impact_sounds_on_shell_explosion(evt : CmdShellExplosionFx;
                                                scene_hit_place__matId : int;
                                                scene_hit_place__pos : float3;
                                                projectile_ballistics_props : ProjectileProps;
                                                projectile_sound__explode : string)
  play_sound(projectile_sound__explode,
             projectile_ballistics_props.caliber,
             0.,
             scene_hit_place__matId,
             scene_hit_place__pos)
