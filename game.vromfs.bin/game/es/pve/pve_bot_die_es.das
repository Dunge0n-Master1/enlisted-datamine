require ecs

[es(tag=server, REQUIRE=pve_bot, on_event=EventEntityDestroyed, track=isAlive)]
def pve_bot_die_es(evt : Event; isAlive : bool; var squad_member__squad : EntityId&)
  if isAlive || !squad_member__squad
    return

  destroyEntity(squad_member__squad)
  squad_member__squad = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=pve__active)] (var pve_stage__enemyCount : int&)
    pve_stage__enemyCount -= 1
    return true
