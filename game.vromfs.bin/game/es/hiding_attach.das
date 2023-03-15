require ecs
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

[es(tag=server, on_appear, track=(slot_attach__attachedTo, base_vis_item__hideNodesInEntity))]
def hiding_attach_track_es_event_handler(evt : Event;
                                         slot_attach__attachedTo : EntityId;
                                         base_vis_item__hideFromNode : StringList;
                                         var base_vis_item__hideNodesInEntity : EntityId&)
  if slot_attach__attachedTo == base_vis_item__hideNodesInEntity
    return

  if doesEntityExist(base_vis_item__hideNodesInEntity)
    for node in base_vis_item__hideFromNode
      sendEvent(base_vis_item__hideNodesInEntity, [[CmdClearHiddenNode nodeName=string(node)]])

  if doesEntityExist(slot_attach__attachedTo)
    for node in base_vis_item__hideFromNode
      sendEvent(slot_attach__attachedTo, [[CmdSetHideNode nodeName=string(node)]])

  base_vis_item__hideNodesInEntity = slot_attach__attachedTo


[es(tag=server, on_disappear, REQUIRE=slot_attach__attachedTo)]
def disappear_attach_track_es_event_handler(evt : Event;
                                            base_vis_item__hideFromNode : StringList;
                                            var base_vis_item__hideNodesInEntity : EntityId&)
  if doesEntityExist(base_vis_item__hideNodesInEntity)
    for node in base_vis_item__hideFromNode
      sendEvent(base_vis_item__hideNodesInEntity, [[CmdClearHiddenNode nodeName=string(node)]])

  base_vis_item__hideNodesInEntity = INVALID_ENTITY_ID
