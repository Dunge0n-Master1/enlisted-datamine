require ecs
require soundEvent
require weapon_sounds.modules.weapon_sounds_events
require sound_utils.modules.sound_physmat_common
require strings


let CALIBER_THRESHOLD = 0.025


[es(tag=sound)]
def play_projectile_hit_scene_sound(evt : CmdPlayProjectileHitSceneSound;
                                    projectile_sound__hit : string;
                                    projectile_sound__explode : string)
  var typ = evt.exploded ? projectile_sound__explode : projectile_sound__hit
  if typ == "autoSelect"
    typ = evt.caliber < CALIBER_THRESHOLD ? "bullet" : "shell"
  if !empty(typ)
    let smid = int(get_projectile_sound_material_id(evt.pmid))
    let path = typ == "bullet" ? "[rico={evt.ricochet};cal={evt.caliber};mat={smid}]impact/{typ}" : "[cal={evt.caliber};mat={smid}]impact/{typ}"
    oneshot(path, evt.pos)
