require ecs

[es(tag=server, no_order)]
def squad_cleanup_es(act : ecs::UpdateStageInfoAct; eid : ecs::EntityId;
                     squad__leader : ecs::EntityId; squad__numAliveMembers : int;
                     var squad__hasMembersBefore : bool&)
  if squad__numAliveMembers > 0
    squad__hasMembersBefore = true
  elif squad__hasMembersBefore
    if !doesEntityExist(squad__leader)
      destroyEntity(eid)
