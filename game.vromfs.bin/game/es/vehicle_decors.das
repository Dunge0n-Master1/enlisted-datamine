require DagorSystem
require ecs.common
require ecs
require GeomNodeTree
require AnimV20
require EcsUtils
require enlisted.events_enlisted

def swap_yz(var tm : float3x4)
  let yTmVec = tm[1]
  tm[1] = tm[2]
  tm[2] = yTmVec

[es(tag=gameClient)]
def node_attached_init_es(evt : SetVehicleDecor;
                          eid : EntityId;
                          animchar : AnimcharBaseComponent;
                          var attach_decorators__entities : EidList&)
  let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, evt.nodeName)
  if nodeId <= -1
    logerr("Invalid node {evt.nodeName} on target {getEntityTemplateName(eid)}")
    return

  let decorEid = createEntity("{evt.templateName}+node_attached_itm") <| $(var init &)
    init |> set("node_attached__nodeId", nodeId)
    init |> set("node_attached__entity", eid)
    init |> set("node_attached__localTm", evt.relativeTm)
    init |> set("node_attached__nodeId", nodeId)
    init |> set("decor__id", evt.slotId)
  attach_decorators__entities |> push(decorEid)

[es(tag=gameClient, on_event=(EventEntityDestroyed, EventEntityDied), REQUIRE=attach_decorators__templates)]
def destroy_decors_for_vehicle_es(evt : Event; attach_decorators__entities : EidList)
  for decorEid in attach_decorators__entities
    query(decorEid) <| $ [es(REQUIRE=decor__id)] ()
      destroyEntity(decorEid)

[es(tag=gameClient, on_appear)]
def init_decors_for_vehicle_es(evt : Event;
                               eid : EntityId;
                               attach_decorators__templates : Array;
                               animchar : AnimcharBaseComponent;
                               var attach_decorators__entities : EidList&)
  assume entities = attach_decorators__entities
  resize(entities, length(attach_decorators__templates))
  for i in iter_range(attach_decorators__templates)
    let obj = get_ecs_object(attach_decorators__templates[i])
    if obj == null
      continue
    let decorTemplate = get_string(*obj, "template", "")
    let nodeName = get_string(*obj, "nodeName", "")
    let relativeTM = get_TMatrix(obj, "relativeTm")
    if decorTemplate == "" || relativeTM == null
      logerr("can't create all decor for {eid} and {getEntityTemplateName(eid)}, some of them hasn't template or tm")
      continue
    let attachNodeId = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
    if (attachNodeId == -1)
      logerr("Decor attach node '{nodeName}' was not found.")
      continue
    var testTm = *relativeTM
    let swapYZ = get_bool(*obj, "swapYZ") ?? true
    if swapYZ
      swap_yz(testTm)
    entities[i] = createEntity("{decorTemplate}+node_attached_itm") <| $(var init : ComponentsInitializer)
      set(init, "node_attached__entity", eid)
      set(init, "node_attached__nodeId", attachNodeId)
      set(init, "node_attached__localTm", testTm)
      set(init, "decor__id", i)
      set(init, "decor__swapYZ", swapYZ)

[es(tag=gameClient, before=node_attached_itm, REQUIRE=daeditor__selected)]
def debug_setup_for_decors(info : ParallelUpdateFrameDelayed;
                           node_attached__entity : EntityId;
                           node_attached__nodeId : int;
                           decor__id : int;
                           transform : float3x4;
                           decor__swapYZ : bool;
                           var node_attached__localTm : float3x4)
  if decor__id < 0
    return
  query(node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent;
                                          var attach_decorators__templates : Array)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, tm)
    var decorRelativeTm = inverse(tm) * transform
    node_attached__localTm = decorRelativeTm
    if decor__swapYZ
      swap_yz(decorRelativeTm)
    var obj = getRW_ecs_object(attach_decorators__templates[decor__id])
    *obj |> set("relativeTm", decorRelativeTm)


[es(tag=gameClient, track=isExploded, REQUIRE=vehicle)]
def vehicle_burn_decorators_es(evt : Event;
                               attach_decorators__entities : EidList;
                               isExploded aka vehicle_isExploded : bool)
  for decorEid in attach_decorators__entities
    query(decorEid) <| $ [es] (var isExploded : bool&)
      isExploded = vehicle_isExploded
