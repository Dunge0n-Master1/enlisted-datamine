require ecs
require game.es.events

[es(tag=server)]
def heal_and_revive_item_state(evt : EventOnItemStartUse;
                               var item__isCurrentlyUsedForReviveTarget : bool&)
  query(evt.target) <| $ [es] (isDowned : bool)
    item__isCurrentlyUsedForReviveTarget = isDowned