require ecs


[es(tag=input, on_appear, track=(human_net_phys__isZooming, human_net_phys__isHctAim, human_input__isGyroOnlyInAimOrZoom))]
def gyroscope_update_aim_enabled_state(evt : Event;
                                       human_net_phys__isZooming : bool;
                                       human_net_phys__isHctAim : bool;
                                       human_input__isGyroOnlyInAimOrZoom : bool;
                                       var human_input__isGyroAimEnabled : bool&)
  human_input__isGyroAimEnabled = human_net_phys__isZooming || human_net_phys__isHctAim || !human_input__isGyroOnlyInAimOrZoom
