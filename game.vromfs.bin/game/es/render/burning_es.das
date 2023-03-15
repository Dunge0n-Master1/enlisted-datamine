require ecs
require ecs.common
require game.es.events
require CapsuleApproximation
require game.es.node_attach_common
require game.es.render.effect_animation_common
require DagorSystem
require GeomNodeTree
require AnimV20
require strings


[es(track=(burning__isBurning, animchar_render__enabled), tag=render, before=effect_animation_update_es)]
def burning_effects_state_es(evt : Event; eid aka human_eid : EntityId;
                             [[shared_comp]] capsule_approximation : CapsuleApproximation;
                             animchar : AnimcharBaseComponent;
                             animchar_render__enabled : bool;
                             burning__effectTemplate : string;
                             burning__isBurning : bool)
  if burning__isBurning && !empty(burning__effectTemplate) && animchar_render__enabled // start burning
    for data in capsule_approximation.capsuleDatas
      var ctm : float3x4
      ctm[3] = (data.a + data.b) * 0.5
      ctm[0][0] = length(data.a - data.b) + 2.f * data.rad
      ctm[1][1] = data.rad * 2.f
      ctm[2][2] = data.rad * 2.f

      let burningEffectEid = createEntity(burning__effectTemplate) <| $(var init : ComponentsInitializer)
        var tm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, int(data.nodeIndex), tm)
        tm = tm * ctm
        set(init, "transform", tm)
        set(init, "effect_animation__transform", tm)

      attach_to_node(burningEffectEid, eid, int(data.nodeIndex), ctm)
  else // end burning
    query() <| $ [es(REQUIRE=burning)] (eid : EntityId; node_attached__entity : EntityId)
      if node_attached__entity == human_eid
        destroyEntity(eid)



