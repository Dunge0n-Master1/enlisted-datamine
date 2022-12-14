require ecs
require soundEvent
require DagorMath
require common_shooter.es.sound.gun_sound_common


[es(tag=sound, on_event=EventShotDry)]
def gun_shot_dry_sound(evt : Event;
                       gun_sound__isEnabled : bool;
                       gun_shot_dry_sound__path : string;
                       sound_bank_preset_state__isValid : bool;
                       gun__owner : EntityId;
                       animchar_bbox : bbox3f)
  if gun_sound__isEnabled && sound_bank_preset_state__isValid && is_watched_gun_sound(gun__owner)
    oneshot(gun_shot_dry_sound__path, get_gun_sound_pos(animchar_bbox))
