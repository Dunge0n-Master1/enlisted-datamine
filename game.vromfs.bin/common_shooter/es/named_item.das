require ecs


[es(on_appear, tag=server)]
def drop_named_item_es(evt : Event; item__lastOwner : EntityId; var playerItemOwner : EntityId&)
  playerItemOwner = get_Eid(item__lastOwner, "possessedByPlr") ?? INVALID_ENTITY_ID
