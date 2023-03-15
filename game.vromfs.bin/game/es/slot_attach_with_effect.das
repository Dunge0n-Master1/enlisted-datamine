require ecs

[es(on_appear, track=game_effect__attachedTo, REQUIRE=slot_attach__followEffectAttach)]
def game_effect_with_slot_attach_es(evt : Event; var slot_attach__attachedTo : EntityId&; game_effect__attachedTo : EntityId)
  slot_attach__attachedTo = game_effect__attachedTo

[es(on_event=EventComponentsDisappear, REQUIRE=game_effect__attachedTo, REQUIRE=slot_attach__followEffectAttach)]
def game_effect_with_slot_attach_detached_es(evt : Event; var slot_attach__attachedTo : EntityId&)
  slot_attach__attachedTo = INVALID_ENTITY_ID
