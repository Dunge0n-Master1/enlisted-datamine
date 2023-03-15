require ecs
require AnimV20
require GeomNodeTree
require DagorSystem
require math.base
require enlisted.events_enlisted

[es(tag=render, on_appear)]
def gun_flash_fx_init(evt : Event;
                      eid : EntityId;
                      animchar : AnimcharBaseComponent;
                      [[shared_comp]] gun_flash_fx__nodes : StringList;
                      [[shared_comp]] gun_flash_fx__template : StringList;
                      [[shared_comp]] gun_flash_fx__scale : FloatList;
                      var gun_flash_fx__nodeIds : IntList&)
  let numFx = length(gun_flash_fx__nodes)
  gun_flash_fx__nodeIds |> resize(numFx)
  if length(gun_flash_fx__template) != numFx || length(gun_flash_fx__scale) != numFx
    logerr("[{eid}] {getEntityTemplateName(eid)}: gun_flash_fx has wrong number of elements in lists")
  for id, node in gun_flash_fx__nodeIds, gun_flash_fx__nodes
    id = geomtree_findNodeIndex(*animchar.nodeTree, string(node))
    if id < 0
      logerr("[{eid}] {getEntityTemplateName(eid)}: gun_flash_fx node {node} not found")

[es(tag=render, on_event=(CmdNetShot, EventShot))]
def gun_flash_fx_on_shot(evt : Event;
                         eid : EntityId;
                         animchar : AnimcharBaseComponent;
                         animchar__visible : bool = true;
                         [[shared_comp]] gun_flash_fx__template : StringList;
                         [[shared_comp]] gun_flash_fx__scale : FloatList;
                         gun_flash_fx__nodeIds : IntList)
  if !animchar__visible
    return
  for nodeId, fxTemplate, scale in gun_flash_fx__nodeIds, gun_flash_fx__template, gun_flash_fx__scale
    if nodeId < 0
      continue
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, tm)
    for i in 0..3
      tm[i] *= scale
    createEntity(string(fxTemplate)) <| $(var init : ComponentsInitializer)
      init |> set("transform", tm)
      init |> set("gun_flash_fx__gunEid", eid)
      init |> set("gun_flash_fx__nodeId", nodeId)

[es(on_appear, tag=render, REQUIRE=effect__name)]
def gun_flash_fx_init_es(evt : Event;
                         var transform : float3x4&;
                         gun_flash_fx__scaleMultiplier : float)
  transform = transform * scale_tm(gun_flash_fx__scaleMultiplier)

[es(tag=render, after=after_animchar_update_sync, before=effect_attached_es)]
def gun_flash_fx_update(info : ParallelUpdateFrameDelayed;
                        gun_flash_fx__gunEid : EntityId;
                        gun_flash_fx__nodeId : int;
                        var transform : float3x4&)
  query(gun_flash_fx__gunEid) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, gun_flash_fx__nodeId, tm)
    transform[3] = tm[3]

[es(tag=render, no_order)]
def gun_flash_fx_check_destruction_time(info : ParallelUpdateFrameDelayed; eid : EntityId; var gun_flash_fx__timeToDestroy : float&)
  gun_flash_fx__timeToDestroy -= info.dt
  if gun_flash_fx__timeToDestroy <= 0.
    destroyEntity(eid)