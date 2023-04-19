require ecs
require DngActor

[es(on_appear)]
def save_phys_string(evt : Event; eid : EntityId; var phys__physTypeStr : das_string&)
  var physActor : BasePhysActor? = get_phys_actor(eid)
  if physActor != null
    phys__physTypeStr := physActor.physTypeStr