require ecs

[es(tag=server, on_appear, track=repair__active)]
def vehicle_repair_anim_track_active(evt : Event;
                                     eid : EntityId;
                                     repair__active : bool;
                                     repair__animationTemplate : string;
                                     var repair__animationEntity : EntityId&)
  if !repair__active
    destroyEntity(repair__animationEntity)
    repair__animationEntity = INVALID_ENTITY_ID
    return

  if !!repair__animationEntity
    destroyEntity(repair__animationEntity)
  repair__animationEntity = createEntity(repair__animationTemplate) <| $(var init : ComponentsInitializer)
    set(init, "game_effect__attachedTo", eid)

[es(tag=server, on_disappear)]
def repair_anim_on_destroy(evt : Event; var repair__animationEntity : EntityId&)
  destroyEntity(repair__animationEntity)
  repair__animationEntity = INVALID_ENTITY_ID
