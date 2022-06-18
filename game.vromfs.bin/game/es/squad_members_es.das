require ecs

[es(tag=server, on_appear)]
def squad_members_list_fill_es(evt : Event; eid : EntityId; squad_member__squad : EntityId)
  query(squad_member__squad) <| $ [es] (var squad__allMembers : EidList&)
    push(squad__allMembers, eid)