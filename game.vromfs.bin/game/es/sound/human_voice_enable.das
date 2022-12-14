require ecs

[es(tag=sound, on_appear, on_disappear, track=(isAlive, isDowned, human_breath__isUnderWater, human_net_phys__isHoldBreath))]
def human_voice_enable(evt : Event;
                       var human_voice_enable : bool&;
                       isAlive : bool;
                       isDowned : bool = false;
                       human_breath__isUnderWater : bool = false;
                       human_net_phys__isHoldBreath : bool = false)
  human_voice_enable = isAlive && !isDowned && !human_breath__isUnderWater && !human_net_phys__isHoldBreath
