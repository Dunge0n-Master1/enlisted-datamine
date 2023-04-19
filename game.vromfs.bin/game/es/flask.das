require ecs
require app
require DngHuman
require game.es.events

[es(tag=gameClient, track=itemContainer, on_appear)]
def soldier_has_flask(evt : Event;
                      itemContainer : EidList;
                      var hasFlask : bool&)
  hasFlask = false
  for itemEid in itemContainer
    if has(itemEid, "flask")
      hasFlask = true


[es(tag=server)]
def apply_flask_affect_on_use(evt : EventOnLootItemUsed;
                              flask__affectTemplate : string)
  query(evt.target) <| $ [es] (var flask__affectEid : EntityId&)
    if !flask__affectEid
      // create new affect if there was not one
      flask__affectEid = createEntity(flask__affectTemplate) <| $(init)
        init |> set("game_effect__attachedTo", evt.target)
    else
      // extend existing affect lifetime
      query(flask__affectEid) <| $ [es] (game_effect__timeToDestroy : float;
                                         var game_effect__destroyAt : float&)
        game_effect__destroyAt = get_sync_time() + game_effect__timeToDestroy


[es(tag=server, on_disappear, REQUIRE=flaskAffect)]
def remove_flask_affect_from_human_on_affect_end(evt : Event;
                                                 game_effect__attachedTo : EntityId)
  query(game_effect__attachedTo) <| $ [es] (var flask__affectEid : EntityId&)
    flask__affectEid = INVALID_ENTITY_ID


[es(tag=server, on_disappear)]
def remove_flask_affect_on_human_disappear(evt : Event;
                                           flask__affectEid : EntityId)
  if flask__affectEid != INVALID_ENTITY_ID
    destroyEntity(flask__affectEid)
