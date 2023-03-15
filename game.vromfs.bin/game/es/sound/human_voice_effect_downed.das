require ecs
require human_sounds.modules.human_voice_effect_common


[es(tag=sound, on_appear, before=human_voice_effect_on_change, track=isDowned)]
def human_voice_effect_downed(evt : Event;
                              isDowned : bool;
                              var human_voice_effect__activeEffects : Object&)
  set_human_voice_effect("downed", isDowned, human_voice_effect__activeEffects)
