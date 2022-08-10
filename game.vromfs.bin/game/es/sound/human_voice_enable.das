require ecs

[es(tag=sound, no_order)]
def human_voice_enable(info : UpdateStageInfoAct;
                       var human_voice_enable : bool&;
                       human_breath__isUnderWater : bool = false;
                       human_net_phys__isHoldBreath : bool = false;
                       isAlive : bool;
                       isDowned : bool = false)
  human_voice_enable = isAlive && !isDowned && !human_breath__isUnderWater && !human_net_phys__isHoldBreath
