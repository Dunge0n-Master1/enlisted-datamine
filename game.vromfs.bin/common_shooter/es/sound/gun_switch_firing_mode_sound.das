require ecs
require soundEvent
require DagorMath
require common_shooter.es.sound.gun_sound_common


[es(tag=sound, track=gun__firingModeIndex, REQUIRE=gun__firingModeIndex)]
def gun_switch_firing_mode_sound(evt : Event;
                                 gun__owner : EntityId;
                                 animchar_bbox : bbox3f;
                                 gun_sound__isEnabled : bool;
                                 gun_switch_firing_mode_sound__path : string;
                                 sound_banks_state__isPresetLoaded : bool)
  if gun_sound__isEnabled && sound_banks_state__isPresetLoaded && is_watched_gun_sound(gun__owner)
    oneshot(gun_switch_firing_mode_sound__path, get_gun_sound_pos(animchar_bbox))
