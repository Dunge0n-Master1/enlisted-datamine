require ecs
require fx
require math.base

[es(on_appear, tag=render)]
def on_creation_effect(evt : Event; effect__effectOnCreation : string; transform : float3x4)
  start_effect(effect__effectOnCreation, transform, IDENT_TM)

[es(on_disappear, tag=render)]
def on_destroy_effect(evt : Event; effect__effectOnDestroyed : string; transform : float3x4)
  start_effect(effect__effectOnDestroyed, transform, IDENT_TM)