require ecs

[es(tag=gameClient, track=human_attached_gun__attachedGunEid, REQUIRE=hero)]
def player_visibility_on_stationary_gun_es(evt : Event;
                                           human_attached_gun__attachedGunEid : EntityId;
                                           var human__visible : bool&)
  human__visible = human_attached_gun__attachedGunEid == INVALID_ENTITY_ID || !has(human_attached_gun__attachedGunEid, "stationary_gun")

[es(tag=gameClient, on_disappear, REQUIRE=(hero, human_attached_gun__attachedGunEid))]
def player_visibility_on_stationary_gun_on_disappear(evt : Event; var human__visible : bool&)
  human__visible = true
