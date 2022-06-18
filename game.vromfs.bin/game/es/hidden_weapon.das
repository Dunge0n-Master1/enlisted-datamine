require ecs

[es(on_appear, REQUIRE=game_effect__hiddenWeapon)]
def hide_weapon_affect_es(evt : Event; game_effect__attachedTo : EntityId)
  ecs::query(game_effect__attachedTo) <| $ [es] (var human_unarmed__hiddenWeapon : bool&)
    human_unarmed__hiddenWeapon = true

[es(on_event=EventEntityDestroyed, REQUIRE=game_effect__hiddenWeapon)]
def unjide_weapon_affect_es(evt : Event; game_effect__attachedTo : EntityId)
  ecs::query(game_effect__attachedTo) <| $ [es] (var human_unarmed__hiddenWeapon : bool&)
    human_unarmed__hiddenWeapon = false

