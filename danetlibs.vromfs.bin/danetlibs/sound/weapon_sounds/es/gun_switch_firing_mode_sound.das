require ecs
require soundEvent
require DagorMath

def get_pos(animchar_bbox : bbox3f)
  return (animchar_bbox.bmin.xyz + animchar_bbox.bmax.xyz) * 0.5

[es(tag=sound, track=gun__firingModeIndex, REQUIRE=gun__firingModeIndex)]
def gun_switch_firing_mode_sound(evt : Event;
                                 animchar_bbox : bbox3f;
                                 gun_sound__isEnabled : bool;
                                 gun_switch_firing_mode_sound__path : string;
                                 sound_bank_preset_state__isValid : bool;
                                 gun_sound__isWatched : bool)
  if gun_sound__isEnabled && sound_bank_preset_state__isValid && gun_sound__isWatched
    oneshot(gun_switch_firing_mode_sound__path, get_pos(animchar_bbox))
