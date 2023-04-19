require ecs
require DngWalkerai

def check_squad_alive_members(squad_eid : EntityId)
  if squad_eid != ecs::INVALID_ENTITY_ID
    setOptional(squad_eid, "squad__checkMembersTimer", 0.0f)

[es(on_appear, REQUIRE=walker_agent)]
def squad_member_init_es(evt : Event; squad_member__squad : EntityId)
  if squad_member__squad != ecs::INVALID_ENTITY_ID
    check_squad_alive_members(squad_member__squad)

[es(track=squad_member__squad, REQUIRE=walker_agent, REQUIRE=isAlive)]
def squad_member_changed_squad_es(evt : Event; squad_member__squad : EntityId)
  if squad_member__squad != ecs::INVALID_ENTITY_ID
    check_squad_alive_members(squad_member__squad)

[es(track=isAlive, REQUIRE=isAlive)]
def squad_member_check_alive_es(evt : Event; squad_member__squad : EntityId)
  check_squad_alive_members(squad_member__squad)
