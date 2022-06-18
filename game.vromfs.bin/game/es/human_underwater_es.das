require ecs
require game.es.events
require DagorSystem

[es(tag=server, REQUIRE_NOT=deadEntity, track=human_breath__isUnderWater, track=human_inventory__entityToUse)]
def human_cancel_healing_underwater_es(info : Event;
                                       eid : EntityId;
                                       isDowned : bool;
                                       human_breath__isUnderWater : bool;
                                       var human_inventory__entityToUse : EntityId&)
  if isDowned && !!human_inventory__entityToUse && human_breath__isUnderWater
    sendEvent(eid, [[EventInterruptItemUse]])
    human_inventory__entityToUse = INVALID_ENTITY_ID
