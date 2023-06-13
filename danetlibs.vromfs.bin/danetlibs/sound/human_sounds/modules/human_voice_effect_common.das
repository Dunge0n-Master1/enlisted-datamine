module human_voice_effect_common shared

require ecs
require ecs.safe


def set_human_voice_effect(name : string; enable : bool; var active_effects : Object&)
  if enable != (active_effects[name] ?? false)
    active_effects |> set(name, enable)


def raise_human_voice_effect(name : string; var active_effects : Object&)
  set_human_voice_effect(name, true, active_effects)

def clear_human_voice_effect(name : string; var active_effects : Object&)
  set_human_voice_effect(name, false, active_effects)
