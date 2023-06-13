require ecs
require app
require soundEvent
require DagorMath
require common_shooter.es.sound.gun_sound_common


[es(tag=sound, on_event=EventShotDry)]
def gun_shot_dry_sound(evt : Event;
                       gun_sound__isEnabled : bool;
                       gun_shot_dry_sound__path : string;
                       var gun_shot_dry_sound__nextTime : float&;
                       gun_shot_dry_sound__cooldown : float;
                       sound_banks_state__isPresetLoaded : bool;
                       gun__owner : EntityId;
                       animchar_bbox : bbox3f)
  if gun_sound__isEnabled && sound_banks_state__isPresetLoaded && get_sync_time() >= gun_shot_dry_sound__nextTime && is_watched_gun_sound(gun__owner)
    oneshot(gun_shot_dry_sound__path, get_gun_sound_pos(animchar_bbox))
  gun_shot_dry_sound__nextTime = get_sync_time() + gun_shot_dry_sound__cooldown
