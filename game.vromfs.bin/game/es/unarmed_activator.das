require ecs

[es(on_appear, REQUIRE=game_effect__activateUnarmed)]
def unarmed_activator_set_es(evt : Event; game_effect__attachedTo : EntityId)
  ecs::query(game_effect__attachedTo) <| $ [es] (var human_unarmed__active : bool&)
    human_unarmed__active = true

[es(on_disappear, REQUIRE=game_effect__activateUnarmed)]
def unarmed_activator_unset_es(evt : Event; game_effect__attachedTo : EntityId)
  ecs::query(game_effect__attachedTo) <| $ [es] (var human_unarmed__active : bool&)
    human_unarmed__active = false

