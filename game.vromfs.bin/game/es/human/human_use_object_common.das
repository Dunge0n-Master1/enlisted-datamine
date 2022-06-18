module human_use_object_common shared
require ecs
require EnlistedNet
require math.base
require game.es.events



def human_try_use_object(user_eid : EntityId;
                         user_position : float3;
                         use_distance_threshold : float;
                         used_object_eid : EntityId)
  query(used_object_eid) <| $ [es] (transform : float3x4)
    if length_sq(user_position - transform[3]) <= square(use_distance_threshold)
      if !is_server()
        sendEvent(user_eid, [[HumanUseObjectRequest objectEid=used_object_eid]])
      else
        sendEvent(used_object_eid, [[CmdUse requesterEid=user_eid]])