require ecs
require AnimV20
require GeomNodeTree
require math.base
require DagorSystem

[es(on_appear)]
def flamethrower_init_effect(evt : Event;
                             eid : EntityId;
                             animchar : AnimcharBaseComponent;
                             flamethrower__streamEffectNodeName : string;
                             var flamethrower__streamEffectNodeIdx : int&)
  let nodeName = flamethrower__streamEffectNodeName
  flamethrower__streamEffectNodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, nodeName);
  if flamethrower__streamEffectNodeIdx == -1
    logerr("<{getEntityTemplateName(eid)}> does not have '{nodeName}' animchar node. Failed to assign flamethrower.streamEffectNodeIdx")

[es(tag=gameClient, track=flamethrower__active)]
def flamethrower_manage_stream_effect(evt : Event;
                                      eid : EntityId;
                                      animchar : AnimcharBaseComponent;
                                      flamethrower__active : bool;
                                      flamethrower__flameCurrentLength : float;
                                      flamethrower__maxFlameLength : float;
                                      flamethrower__streamEffectTemplate : string;
                                      flamethrower__streamEffectNodeIdx : int;
                                      flamethrower__stramEffectEps = 0.001;
                                      var flamethrower__streamEffectEid : EntityId&)
  if flamethrower__active
    if !flamethrower__streamEffectEid && flamethrower__streamEffectNodeIdx >= 0
      let streamTemplateName = add_sub_template_name(flamethrower__streamEffectTemplate, "node_attached_itm")
      flamethrower__streamEffectEid = createEntity(streamTemplateName) <| $(var init : ComponentsInitializer)
        var localTm = IDENT_TM
        localTm[1] *= max(flamethrower__stramEffectEps, flamethrower__flameCurrentLength / flamethrower__maxFlameLength)
        var tm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, flamethrower__streamEffectNodeIdx, tm)
        set(init, "transform", tm * localTm)
        set(init, "node_attached__entity", eid)
        set(init, "node_attached__nodeId", flamethrower__streamEffectNodeIdx)
        set(init, "node_attached__localTm", localTm)

  elif flamethrower__streamEffectEid != INVALID_ENTITY_ID
    destroyEntity(flamethrower__streamEffectEid)
    flamethrower__streamEffectEid = INVALID_ENTITY_ID

[es(tag=gameClient, track=flamethrower__flameCurrentLength)]
def flamethrower_stream_effect_distance(evt : Event;
                                        flamethrower__flameCurrentLength : float;
                                        flamethrower__maxFlameLength : float;
                                        flamethrower__streamEffectEid : EntityId;
                                        flamethrower__streamEffectLocalTm : float3x4 const?;
                                        flamethrower__stramEffectEps = 0.001)
  if !!flamethrower__streamEffectEid
    query(flamethrower__streamEffectEid) <| $ [es] (var node_attached__localTm : float3x4&)
      let lenMul = max(flamethrower__stramEffectEps, flamethrower__flameCurrentLength / flamethrower__maxFlameLength)
      node_attached__localTm[1] = (flamethrower__streamEffectLocalTm ?? IDENT_TM)[1] * lenMul

[es(tag=gameClient, track=flamethrower__active)]
def flamethrower_turret_manage_stream_effect(evt : Event;
                                             turret__flashNodeId : int;
                                             turret__owner : EntityId;
                                             flamethrower__active : bool;
                                             flamethrower__streamEffectTemplate : string;
                                             flamethrower__flameCurrentLength : float;
                                             flamethrower__maxFlameLength : float;
                                             flamethrower__streamEffectLocalTm : float3x4;
                                             flamethrower__stramEffectEps = 0.001;
                                             var flamethrower__streamEffectNodeIdx : int&;
                                             var flamethrower__streamEffectEid : EntityId&)
  flamethrower__streamEffectNodeIdx = turret__flashNodeId
  if flamethrower__active
    if !flamethrower__streamEffectEid && flamethrower__streamEffectNodeIdx >= 0
      query(turret__owner) <| $ [es] (eid : EntityId; animchar : AnimcharBaseComponent)
        let streamTemplateName = add_sub_template_name(flamethrower__streamEffectTemplate, "node_attached_itm")
        flamethrower__streamEffectEid = createEntity(streamTemplateName) <| $(var init : ComponentsInitializer)
          var localTm = flamethrower__streamEffectLocalTm
          localTm[1] *= max(flamethrower__stramEffectEps, flamethrower__flameCurrentLength / flamethrower__maxFlameLength)
          var tm : float3x4
          geomtree_getNodeWtmScalar(*animchar.nodeTree, flamethrower__streamEffectNodeIdx, tm)
          set(init, "transform", tm * localTm)
          set(init, "node_attached__entity", eid)
          set(init, "node_attached__nodeId", flamethrower__streamEffectNodeIdx)
          set(init, "node_attached__localTm", localTm)
  elif flamethrower__streamEffectEid != INVALID_ENTITY_ID
    destroyEntity(flamethrower__streamEffectEid)
    flamethrower__streamEffectEid = INVALID_ENTITY_ID

[es(tag=server, track=human_gun_attached)]
def flamethrower_disable_unattached(evt : Event;
                                    human_gun_attached : bool;
                                    var flamethrower__active : bool&)
  if !human_gun_attached
    flamethrower__active = false
