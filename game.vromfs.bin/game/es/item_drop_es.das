require ecs
require DagorSystem

[es(on_event=EventOnItemGenerated, tag=server)]
def drop_item_es(evt : Event; var transform : float3x4; dropTm : float3x4; item__isOnGround : bool)
  if item__isOnGround
    transform = transform * dropTm

[es(on_appear, tag=server)]
def drop_item_created_es(evt : Event; var transform : float3x4; dropTm : float3x4; item__alreadyLooted : bool)
  if item__alreadyLooted
    transform = transform * dropTm
