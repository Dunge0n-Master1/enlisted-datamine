require ecs

[es(tag=server, REQUIRE=(squad_member__squad), on_appear, track=possessedByPlr)]
def switch_ai_on_possess_unpossess(evt : Event;
                                   possessedByPlr : EntityId;
                                   var beh_tree__enabled : bool&;
                                   var human_weap__infiniteAmmoHolders : bool&)
  let isAiEnabled = !possessedByPlr || has(possessedByPlr, "botAiEnabler")
  beh_tree__enabled = isAiEnabled
  human_weap__infiniteAmmoHolders = isAiEnabled