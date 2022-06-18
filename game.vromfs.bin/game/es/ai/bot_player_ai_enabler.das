require ecs

[es(tag=server, track=possessed, REQUIRE=botAiEnabler)]
def bot_player_ai_enabler_es(evt : Event; possessed : ecs::EntityId)
  ecs::query(possessed) <| $ [es] (var beh_tree__enabled : bool&)
    beh_tree__enabled = true
