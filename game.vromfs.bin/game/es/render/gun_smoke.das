require ecs
require AnimV20
require GeomNodeTree
require DagorSystem
require math.base
require enlisted.events_enlisted
require DagorMath
require DngCamera


def is_gun_too_far_from_camera(gun_pos : vec4f; threshold_dist_sq : float)
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTm == null
    return true
  let camPos = (*camTm)[3]
  return distance_sq(gun_pos.xyz, camPos) > threshold_dist_sq


[es(tag=render, on_appear)]
def gun_smoke_fx_init(evt : Event;
                      eid : EntityId;
                      animchar : AnimcharBaseComponent;
                      [[shared_comp]] gun_smoke_fx__nodes : StringList;
                      [[shared_comp]] gun_smoke_fx__template : StringList;
                      [[shared_comp]] gun_smoke_fx__scale : FloatList;
                      [[shared_comp]] gun_smoke_fx__opacityMult : FloatList;
                      [[shared_comp]] gun_smoke_fx__visibleAmountThreshold : FloatList;
                      var gun_smoke_fx__nodeIds : IntList&;
                      var gun_smoke_fx__fxEids : EidList&)
  let numFx = length(gun_smoke_fx__nodes)
  gun_smoke_fx__nodeIds |> resize(numFx)
  gun_smoke_fx__fxEids |> resize(numFx)

  if length(gun_smoke_fx__template) != numFx || length(gun_smoke_fx__scale) != numFx || length(gun_smoke_fx__opacityMult) != numFx || length(gun_smoke_fx__visibleAmountThreshold) != numFx
    logerr("[{eid}] {getEntityTemplateName(eid)}: gun_smoke_fx has wrong number of elements in lists")

  for id, node in gun_smoke_fx__nodeIds, gun_smoke_fx__nodes
    id = geomtree_findNodeIndex(*animchar.nodeTree, string(node))
    if id < 0
      logerr("[{eid}] {getEntityTemplateName(eid)}: gun_smoke_fx node {node} not found")


[es(tag=render, on_event=(CmdNetShot, EventShot))]
def gun_smoke_fx_on_shot(evt : Event;
                         eid : EntityId;
                         animchar_render__root_pos : vec4f;
                         animchar : AnimcharBaseComponent;
                         gun_smoke_fx__nodeIds : IntList;
                         gun_smoke_fx__incAmountPerShot : float;
                         gun_smoke_fx__thresholdDistSq : float;
                         [[shared_comp]] gun_smoke_fx__template : StringList;
                         [[shared_comp]] gun_smoke_fx__scale : FloatList;
                         [[shared_comp]] gun_smoke_fx__visibleAmountThreshold : FloatList;
                         var gun_smoke_fx__amount : float&;
                         var gun_smoke_fx__fxEids : EidList&;
                         animchar__visible : bool = true)
  if !animchar__visible || is_gun_too_far_from_camera(animchar_render__root_pos, gun_smoke_fx__thresholdDistSq)
    return

  gun_smoke_fx__amount = min(1.0, gun_smoke_fx__amount + gun_smoke_fx__incAmountPerShot)

  for nodeId, fxTemplate, scale, fxEid, threshold in gun_smoke_fx__nodeIds, gun_smoke_fx__template, gun_smoke_fx__scale, gun_smoke_fx__fxEids, gun_smoke_fx__visibleAmountThreshold
    if fxEid != INVALID_ENTITY_ID || gun_smoke_fx__amount < threshold || nodeId < 0
      continue

    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, tm)
    for i in 0..3
      tm[i] *= scale
    peek(fxTemplate) <| $(fxTemplateStr)
      fxEid = createEntity(fxTemplateStr) <| $(var init : ComponentsInitializer)
        init |> set("transform", tm)
        init |> set("gun_fx__gunEid", eid)
        init |> set("gun_fx__nodeId", nodeId)


[es(tag=render, after=after_animchar_update_sync, before=effect_attached_es)]
def gun_smoke_update(info : ParallelUpdateFrameDelayed;
                     animchar_render__root_pos : vec4f;
                     gun_smoke_fx__halfLife : float;
                     gun_smoke_fx__thresholdDistSq : float;
                     [[shared_comp]] gun_smoke_fx__opacityMult : FloatList;
                     [[shared_comp]] gun_smoke_fx__visibleAmountThreshold : FloatList;
                     var gun_smoke_fx__fxEids : EidList;
                     var gun_smoke_fx__amount : float&;
                     animchar__visible : bool = true)
  let visible = animchar__visible && !is_gun_too_far_from_camera(animchar_render__root_pos, gun_smoke_fx__thresholdDistSq)

  for fxEid, opacityMult, threshold in gun_smoke_fx__fxEids, gun_smoke_fx__opacityMult, gun_smoke_fx__visibleAmountThreshold
    if fxEid != INVALID_ENTITY_ID
      if !visible || gun_smoke_fx__amount < threshold
        destroyEntity(fxEid)
        fxEid = INVALID_ENTITY_ID
      else
        query(fxEid) <| $ [es] (var effect__colorMult : E3DCOLOR&)
          let opacity = uint(255.0 * min(1.0, opacityMult * gun_smoke_fx__amount))
          effect__colorMult = E3DCOLOR(uint4(opacity, opacity, opacity, 255u))

  if visible
    gun_smoke_fx__amount *= pow(0.5, safediv(info.dt, gun_smoke_fx__halfLife))
  else
    gun_smoke_fx__amount = 0.0
