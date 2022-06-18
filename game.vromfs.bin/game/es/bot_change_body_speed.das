require ecs

[es(tag=server, REQUIRE=(squad_member__squad), on_appear)]
def ai_change_body_speed_position_on_init(evt : Event;
                                          possessedByPlr : EntityId;
                                          ai__newFasterChangePoseMult : float;
                                          var ai__initialFasterChangePoseMult : float&;
                                          var entity_mods__fasterChangePoseMult : float&)
  ai__initialFasterChangePoseMult = entity_mods__fasterChangePoseMult

  if !possessedByPlr || has(possessedByPlr, "botAiEnabler")
    entity_mods__fasterChangePoseMult = ai__newFasterChangePoseMult

[es(tag=server, after=ai_change_body_speed_position_on_init, REQUIRE=(squad_member__squad), track=possessedByPlr)]
def ai_change_body_speed_position_on_possess_unpossess(evt : Event;
                                                       possessedByPlr : EntityId;
                                                       ai__newFasterChangePoseMult : float;
                                                       ai__initialFasterChangePoseMult : float;
                                                       var entity_mods__fasterChangePoseMult : float&)
  if !possessedByPlr || has(possessedByPlr, "botAiEnabler")
    entity_mods__fasterChangePoseMult = ai__newFasterChangePoseMult
  else
    entity_mods__fasterChangePoseMult = ai__initialFasterChangePoseMult