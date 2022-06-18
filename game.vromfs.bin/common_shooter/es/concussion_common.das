module concussion_common shared
require ecs
require app

def enable_concussion_affect(owner_eid : EntityId; duration : float)
  query(owner_eid) <| $ [es] (concussion__allowReapply : bool = true; var concussion__isActive : bool&; var concussion__endTime : float&)
    if !concussion__isActive || concussion__allowReapply
      concussion__endTime = get_sync_time() + duration
    concussion__isActive = true

def has_concussion_affect(owner_eid : EntityId) : bool
  var res = false
  query(owner_eid) <| $ [es] (concussion__isActive : bool)
    res = concussion__isActive
  return res