require ecs
require AnimV20

[es(on_appear, track=turret_isVisible, REQUIRE=gun__isLauncher, tag=render, after=(slot_attach_on_load_es, turret_gun_es))]
def launcher_animchar_es(evt : Event;
                         turret__owner : EntityId;
                         turret_isVisible : bool;
                         slot_attach__slotName : string;
                         var slot_attach__slotId : int&;
                         var slot_attach__attachedTo : EntityId&;
                         var animchar_render__enabled : bool&)
  if turret_isVisible
    slot_attach__attachedTo = turret__owner
    animchar_render__enabled = true
    slot_attach__slotId = animchar_getSlotId(slot_attach__slotName)
  else
    slot_attach__attachedTo = INVALID_ENTITY_ID
    slot_attach__slotId = -1
    animchar_render__enabled = false

[es(tag=server, on_appear, track=(gun__ammo, turret__isCut), REQUIRE=gun__isLauncher)]
def launcher_animchar_determine_visibility(evt : Event;
                                           gun__ammo : int;
                                           turret__isCut : bool;
                                           var turret_isVisible : bool&)
  turret_isVisible = gun__ammo > 0 && !turret__isCut
