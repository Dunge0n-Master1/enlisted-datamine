require ecs
require ecs.common
require app
require AnimV20
require GeomNodeTree
require game.es.node_attach_common

def init_nodes(animchar : AnimcharBaseComponent; node_names : Array; var out_node_ids : IntList&)
  for nodeNameObj in node_names
    let nodeName = get_string(nodeNameObj, "")
    if nodeName == ""
      continue
    let nodeId = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
    if nodeId < 0
      continue
    out_node_ids |> push(nodeId)

[es(tag=server, on_appear)]
def init_fatal_fire_external_fire_node_ids(evt : Event;
                                           animchar : AnimcharBaseComponent;
                                           [[shared_comp]] fatal_fire_external_fire__nodeNames : Array;
                                           var fatal_fire_external_fire__nodeIds : IntList&)
  init_nodes(animchar, fatal_fire_external_fire__nodeNames, fatal_fire_external_fire__nodeIds)


[es(tag=server, on_appear)]
def init_fatal_explosion_external_fire_node_ids(evt : Event;
                                                animchar : AnimcharBaseComponent;
                                                [[shared_comp]] fatal_explosion_external_fire__nodeNames : Array;
                                                var fatal_explosion_external_fire__nodeIds : IntList&)
  init_nodes(animchar, fatal_explosion_external_fire__nodeNames, fatal_explosion_external_fire__nodeIds)

[es(tag=server, on_event=EventExplosionFatal)]
def fatal_explosion_create_external_fire(evt : Event;
                                         eid : EntityId;
                                         fatal_explosion_fire__ttl : float;
                                         fatal_explosion_external_fire__nodeIds : IntList;
                                         fatal_explosion_external_fire__template : string;
                                         var fatal_explosion_external_fire__eids : EidList&)
  for nodeId in fatal_explosion_external_fire__nodeIds
    let endTime = get_sync_time() + fatal_explosion_fire__ttl
    let fireEid = createEntity(fatal_explosion_external_fire__template) <| $(var init : ComponentsInitializer)
      init |> set("fatal_explosion_external_fire__endTime", endTime)
      var tm : float3x4
      get_node_wpos(eid, nodeId, tm)
      init |> set("transform", tm) // without offset
    fatal_explosion_external_fire__eids |> push(fireEid)
    attach_to_node_pos(fireEid, eid, nodeId, float3(0))

[es(tag=server, on_event=EventFireFatal)]
def fatal_fire_create_external_fire(evt : Event;
                                    eid : EntityId;
                                    fatal_fire_external_fire__nodeIds : IntList;
                                    fatal_fire_external_fire__template : string;
                                    var fatal_fire_external_fire__eids : EidList&)
  for nodeId in fatal_fire_external_fire__nodeIds
    let fireEid = createEntity(fatal_fire_external_fire__template) <| $(init)
      var tm : float3x4
      get_node_wpos(eid, nodeId, tm)
      init |> set("transform", tm) // without offset
    fatal_fire_external_fire__eids |> push(fireEid)
    attach_to_node_pos(fireEid, eid, nodeId, float3(0))

[es(tag=server, track=(isExploded, fire_damage__isBurn))]
def stop_fatal_fire_external_fire(evt : Event; isExploded, fire_damage__isBurn : bool; var fatal_fire_external_fire__eids : EidList&)
  if isExploded || !fire_damage__isBurn
    for eid in fatal_fire_external_fire__eids
      destroyEntity(eid)
    clear(fatal_fire_external_fire__eids)

[es(tag=server, on_disappear)]
def destroy_fatal_explosion_external_fire(evt : Event; fatal_explosion_external_fire__eids : EidList)
  for eid in fatal_explosion_external_fire__eids
    destroyEntity(eid)

[es(tag=server, on_disappear)]
def destroy_fatal_fire_external_fire(evt : Event; fatal_fire_external_fire__eids : EidList)
  for eid in fatal_fire_external_fire__eids
    destroyEntity(eid)

[es(tag=server, no_order)]
def fatal_explosion_external_fire_destruction_timer(info : UpdateStageInfoAct; eid : EntityId; fatal_explosion_external_fire__endTime : float)
  if info.curTime >= fatal_explosion_external_fire__endTime
    destroyEntity(eid)
