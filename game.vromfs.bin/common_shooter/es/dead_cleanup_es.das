require ecs
require game.es.events
require game.events_game
require inventory


[es(tag=server)]
def human_inventory_died_es(evt : EventAnyEntityDied)
  if !evt.victim |> has("noLootDropOnDeath")
    drop_loot(evt.victim, true, true)


[es(tag=server, no_order)]
def dead_cleanup_es(evt : EventEntityDied;
                    eid : EntityId;
                    bodyCleanupTime : float)
  sendEvent(eid, [[CmdBodyCleanup time=bodyCleanupTime]])

[es(tag=server, on_disappear)]
def remove_possessed_on_dissapear_corpse(evt : Event; eid, possessedByPlr : EntityId)
  query(possessedByPlr) <| $ [es] (var possessed : EntityId&)
    if possessed == eid
      possessed = INVALID_ENTITY_ID
