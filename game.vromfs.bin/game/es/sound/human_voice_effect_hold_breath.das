require ecs
require human_sounds.modules.human_voice_effect_common


[es(tag=sound, on_appear, before=human_voice_effect_on_change, track=human_net_phys__isHoldBreath)]
def human_voice_effect_hold_breath(evt : Event;
                                   human_net_phys__isHoldBreath : bool;
                                   var human_voice_effect__activeEffects : Object&)
  set_human_voice_effect("holdBreath", human_net_phys__isHoldBreath, human_voice_effect__activeEffects)
