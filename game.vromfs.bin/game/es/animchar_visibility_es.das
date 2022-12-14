require ecs

// One and only place that defines final visibility of a human.
def calc_human_visibility(isInVehicleHidden : bool; isInVehicleHiddenLocal : bool; human__visible : bool)
  return !isInVehicleHidden && !isInVehicleHiddenLocal && human__visible

// One and only place that defines final visibility of an attachable item (such as a gun, hat, grenade, etc.)
def calc_attachable_visibility(slot_attach__attachedTo : ecs::EntityId; slot_attach__visible : bool;
                               gun__visible : bool; has_gun__visible : bool)
  // Attachable is visible if it's human inventory visible or it's a weapon that's visible (i.e. not holstered)
  var res = slot_attach__visible || gun__visible
  if has_gun__visible && !gun__visible
    // If gun.visible component is present and it's false this means holstering logic
    // wants to detach this gun, but it may not necessarily destroy it (it may "cache" it),
    // so we need to hide it.
    res = false
  ecs::query(slot_attach__attachedTo) <| $ [es] (animchar_render__enabled : bool)
    // If it's attached to invisible animchar, then the item is also invisible.
    res &&= animchar_render__enabled

  ecs::query(slot_attach__attachedTo) <| $ [es] (gun__visible : bool;
                                                 slot_attach__attachedTo : ecs::EntityId;
                                                 slot_attach__visible : bool)

    let tmpRes = calc_attachable_visibility(slot_attach__attachedTo, slot_attach__visible,
                                            gun__visible, true)
    // If it's attached to a weapon, then it's a weapon mod.
    if has_gun__visible
      // Weapon attached to weapon, respect original gun__visible.
      res &&= tmpRes
    else
      // Override visibility with weapon's visibility.
      res = tmpRes
  return res

// Recursively update visibilities of all attached stuff.
def update_attached_visibility(parentEid : ecs::EntityId)
  ecs::query() <| $ [es] (eid : ecs::EntityId; slot_attach__attachedTo : ecs::EntityId; var animchar_render__enabled : bool&;
                          slot_attach__visible : bool; gun__visible : bool = false)
    if slot_attach__attachedTo == parentEid
      animchar_render__enabled = calc_attachable_visibility(slot_attach__attachedTo, slot_attach__visible,
        gun__visible, has(eid, "gun__visible"))

      if parentEid != eid
        update_attached_visibility(eid)

[es(track=(isInVehicleHidden, human__visible, isInVehicleHiddenLocal), on_appear)]
def animchar_human_visibility_es(evt : Event;
                                 eid : EntityId;
                                 human__visible : bool;
                                 isInVehicleHidden : bool;
                                 isInVehicleHiddenLocal : bool;
                                 var animchar_render__enabled : bool&)
  animchar_render__enabled = calc_human_visibility(isInVehicleHidden, isInVehicleHiddenLocal, human__visible)

  update_attached_visibility(eid)
  ecs::query() <| $ [es] (skeleton_attach__attachedTo : ecs::EntityId; var animchar_render__enabled : bool&;
                          slot_attach__visible : bool)
    if skeleton_attach__attachedTo == eid
      animchar_render__enabled = calc_human_visibility(isInVehicleHidden, isInVehicleHiddenLocal, human__visible) && slot_attach__visible

[es(on_appear, track=slot_attach__visible, track=slot_attach__attachedTo, track=gun__visible)]
def animchar_attachable_visibility_es(evt : Event; eid : ecs::EntityId; slot_attach__attachedTo : ecs::EntityId;
                                      var animchar_render__enabled : bool&; slot_attach__visible : bool;
                                      gun__visible : bool = false)
  animchar_render__enabled = calc_attachable_visibility(slot_attach__attachedTo, slot_attach__visible,
    gun__visible, has(eid, "gun__visible"))

  update_attached_visibility(eid)

[es(on_appear, track=skeleton_attach__attachedTo, track=slot_attach__visible)]
def animchar_skeleton_visibility_es(evt : Event; skeleton_attach__attachedTo : ecs::EntityId;
                                    var animchar_render__enabled : bool&; slot_attach__visible : bool)
  query(skeleton_attach__attachedTo) <| $ [es] (isInVehicleHidden : bool; human__visible : bool; isInVehicleHiddenLocal : bool)
    animchar_render__enabled = calc_human_visibility(isInVehicleHidden, isInVehicleHiddenLocal, human__visible) && slot_attach__visible