require ecs
require math.base
require strings
require DagorMath
require DagorSystem
require AnimV20
require %danetlibs/motion_matching/es/mm_events
require %danetlibs/motion_matching/es/tags_common


[es(tag=gameClient, track=(human_net_phys__isSwimming, human_net_phys__isUnderwater))]
def motion_matching_watch_swim(event : Event;
                               var motion_matching__goalTags : StringList;
                               var motion_matching__optionalTags : StringList;
                               human_net_phys__isSwimming : bool;
                               human_net_phys__isUnderwater : bool;
                               var motion_matching__enabled : bool&)

  motion_matching__enabled = human_net_phys__isSwimming
  set_tag(motion_matching__goalTags, human_net_phys__isSwimming, "swim")
  set_tag(motion_matching__optionalTags, human_net_phys__isUnderwater, "swim_underwater")

