require ecs
require soundEvent
require weapon_sounds.modules.weapon_sounds_events
require sound_utils.modules.sound_physmat_common

[es(tag=sound)]
def play_projectile_hit_scene_sound(evt : CmdPlayProjectileHitSceneSound;
                                    projectile_sound__hit : string;
                                    projectile_sound__explode : string;
                                    projectile_sound__smallCaliberThreshold = 0.02)
  var _type = evt.exploded ? projectile_sound__explode : projectile_sound__hit
  if _type == "auto_select"
    _type = evt.caliber < projectile_sound__smallCaliberThreshold ? "bullet" : "shell"
  if _type != ""
    let smid = int(get_projectile_sound_material_id(evt.pmid))
    let path = _type == "bullet" ? "[rico={evt.ricochet};cal={evt.caliber};mat={smid}]impact/{_type}" : "[cal={evt.caliber};mat={smid}]impact/{_type}"
    oneshot(path, evt.pos)
