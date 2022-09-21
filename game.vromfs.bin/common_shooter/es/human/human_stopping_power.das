require ecs

[es(tag=server, on_appear, track=human_melee_charge__currentLessStoppingPower)]
def human_stopping_power(evt : Event;
                         human_melee_charge__currentLessStoppingPower : float;
                         entity_mods__lessStoppingPower : float;
                         var human_hit_tagging__mult : float&)
  human_hit_tagging__mult = saturate(1.0 - entity_mods__lessStoppingPower - human_melee_charge__currentLessStoppingPower)
