require ecs


[es(on_appear, REQUIRE=locked_weapon__grenadeThrowing)]
def locked_weap_grenade_throwing_set_es(evt : Event; game_effect__attachedTo : EntityId)
  ecs::query(game_effect__attachedTo) <| $ [es] (var human_weap__lockedGrenadeThrowingCounter : int&)
    human_weap__lockedGrenadeThrowingCounter++

[es(on_disappear, REQUIRE=locked_weapon__grenadeThrowing)]
def locked_weap_grenade_throwing_unset_es(evt : Event; game_effect__attachedTo : EntityId)
  ecs::query(game_effect__attachedTo) <| $ [es] (var human_weap__lockedGrenadeThrowingCounter : int&)
    if human_weap__lockedGrenadeThrowingCounter > 0
      human_weap__lockedGrenadeThrowingCounter--
