require ecs
require enlisted.game.es.enlisted_squad_common

[es(tag=server, on_appear)]
def squad_members_list_fill_es(evt : Event; eid : EntityId; squad_member__squad : EntityId)
  query(squad_member__squad) <| $ [es] (var squad__allMembers : EidList&)
    push(squad__allMembers, eid)

[es(tag=server, on_appear, REQUIRE=squad_member__squad)]
def squad_members_init_behavior(evt : Event; eid : EntityId)
  reset_squad_mate_behaviour(eid)
