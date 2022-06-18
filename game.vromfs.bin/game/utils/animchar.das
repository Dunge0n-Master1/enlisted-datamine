module animchar shared
require ecs

def anim_attach(var slot_attach__slotId : int&;
                eid : EntityId;
                slot_id : int;
                attach_eid : EntityId)
  query(attach_eid) <| $ [es] (var slot_attach__attachedTo : EntityId&)
    slot_attach__attachedTo = eid
  slot_attach__slotId = slot_id


def anim_detach(var slot_attach__slotId : int&;
                attach_eid : EntityId)
  query(attach_eid) <| $ [es] (var slot_attach__attachedTo : EntityId&)
    slot_attach__attachedTo = INVALID_ENTITY_ID
  slot_attach__slotId = -1;