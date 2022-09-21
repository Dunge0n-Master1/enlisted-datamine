require ecs

[es(on_appear, track=gun__ammo, REQUIRE=gun__isLauncher, tag=render, after=(slot_attach_on_load_es, turret_gun_es))]
def launcher_animchar_es(evt : Event;
                         turret__owner : EntityId;
                         gun__ammo : int;
                         var slot_attach__slotId : int&;
                         var slot_attach__attachedTo : EntityId&;
                         var animchar_render__enabled : bool&)
  if gun__ammo > 0
    slot_attach__attachedTo = turret__owner
    animchar_render__enabled = true
  else
    slot_attach__attachedTo = INVALID_ENTITY_ID
    slot_attach__slotId = -1
    animchar_render__enabled = false