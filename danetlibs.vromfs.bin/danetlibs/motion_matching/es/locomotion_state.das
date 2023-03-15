require ecs
require MotionMatching
require %danetlibs/motion_matching/es/tags_common


[es(tag=(gameClient, dev), track=(human_net_phys__isCrawl, human_net_phys__isCrouch, human_net_phys__isAiming))]
def motion_matching_locomotion_state(event : Event;
                                     var motion_matching__goalTags : StringList;
                                     //var motion_matching__optionalTags : StringList;
                                     human_net_phys__isCrawl : bool;
                                     human_net_phys__isCrouch : bool;
                                     human_net_phys__isAiming : bool)
  set_tag(motion_matching__goalTags, human_net_phys__isCrawl, "crawl")
  set_tag(motion_matching__goalTags, human_net_phys__isCrouch, "crouch")
  set_tag(motion_matching__goalTags, human_net_phys__isAiming, "aiming")