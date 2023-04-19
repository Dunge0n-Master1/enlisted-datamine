require ecs
require soundEvent
require strings


[es(tag=sound, track=parachute__deployed)]
def parachute_item_deploy_sound(evt : Event;
                                parachute__deployed : bool;
                                parachute_item_deploy_sound__deployedPath : string;
                                parachute_item_deploy_sound__undeployedPath : string;
                                item__ownerEid : EntityId)
  let path = parachute__deployed ? parachute_item_deploy_sound__deployedPath : parachute_item_deploy_sound__undeployedPath
  if !empty(path)
    query(item__ownerEid) <| $ [es] (transform : float3x4)
      oneshot(path, transform[3])
