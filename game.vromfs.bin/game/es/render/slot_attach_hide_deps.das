require ecs
require AnimV20
require enlisted.events_enlisted

def enable_node_by_name(node_name : string; enable : bool; var animchar_render : AnimcharRendComponent&)
  let nodeId = ronamemapex_get_name_id((*(*animchar_render.sceneInstance).lodsResource).names.node, node_name)
  animchar_render.sceneInstance |> scene_instance_show_node(nodeId, enable)

[es(tag=render)]
def init_attach_slot_deps_es(evt : EventResolveSlotAttachDeps;
                             slot_attach__attachedTo : EntityId;
                             attach__slotsDeps : Object;
                             var animchar_render : AnimcharRendComponent&)
  if slot_attach__attachedTo != evt.attachTo
    return

  var foundSlots : table<string; bool>
  query(slot_attach__attachedTo) <| $ [es] (attaches_list : EidList)
    for eid in attaches_list
      query(eid) <| $ [es] (slot_attach__slotName : string)
        foundSlots[slot_attach__slotName] = true
  for slot in attach__slotsDeps
    let itemExist = key_exists(foundSlots, slot.key)
    let slotDepsInfo = get_ecs_object(slot.value)
    if slotDepsInfo != null
      let enableNodes = get_ecs_StringList(*slotDepsInfo, "enableNodes")
      let disableNodes = get_ecs_StringList(*slotDepsInfo, "disableNodes")
      if enableNodes != null
        for node in *enableNodes
          enable_node_by_name(string(node), itemExist, animchar_render)
      if disableNodes != null
        for node in *disableNodes
          enable_node_by_name(string(node), !itemExist, animchar_render)

[es(tag=render, on_appear, track=slot_attach__attachedTo)]
def init_attachments_visible_nodes_on_attach_create(evt : Event;
                                                    slot_attach__attachedTo : EntityId)
  broadcastEvent([[EventResolveSlotAttachDeps attachTo=slot_attach__attachedTo]])