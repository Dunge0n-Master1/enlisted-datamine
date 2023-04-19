require ecs
require MotionMatching
require %danetlibs/motion_matching/es/tags_common


[es(tag=(gameClient, dev), track=(human_net_phys__isCrawl, human_net_phys__isCrouch, human_net_phys__isInAir))]
def motion_matching_locomotion_state(event : Event;
                                     human_net_phys__isCrawl : bool;
                                     human_net_phys__isCrouch : bool;
                                     human_net_phys__isInAir : bool;
                                     var motion_matching__enabled : bool&)
  if human_net_phys__isCrawl || human_net_phys__isCrouch || human_net_phys__isInAir
    motion_matching__enabled = false
  else
    motion_matching__enabled = true