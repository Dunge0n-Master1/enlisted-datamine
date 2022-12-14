require ecs

[es(tag=gameClient, on_appear, track=is_local, REQUIRE=player, REQUIRE_NOT=localPlayer)]
def local_player_add_tag(evt : Event; eid : EntityId; is_local : bool)
  if is_local
    addSubTemplate(eid, "local_player")

[es(tag=gameClient, on_appear, track=is_local, REQUIRE=localPlayer)]
def local_player_remove_tag(evt : Event; eid : EntityId; is_local : bool)
  if !is_local
    removeSubTemplate(eid, "local_player")
