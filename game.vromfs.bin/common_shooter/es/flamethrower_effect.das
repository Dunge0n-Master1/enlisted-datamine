require ecs
require AnimV20
require GeomNodeTree
require game.es.node_attach_common
require DagorSystem

[es(on_appear)]
def flamethrower_init_effect(evt : Event;
                             eid : EntityId;
                             animchar : AnimcharBaseComponent;
                             flamethrower__streamEffectNodeName : string;
                             var flamethrower__streamEffectNodeIdx : int&)
  let nodeName = flamethrower__streamEffectNodeName
  flamethrower__streamEffectNodeIdx = geomtree_findNodeIndex(animchar.nodeTree, nodeName);
  if flamethrower__streamEffectNodeIdx == -1
    logerr("<{getEntityTemplateName(eid)}> does not have '{nodeName}' animchar node. Failed to assign flamethrower.streamEffectNodeIdx")

[es(tag=gameClient, track=flamethrower__active)]
def flamethrower_manage_stream_effect(evt : Event;
                                      eid : EntityId;
                                      animchar : AnimcharBaseComponent;
                                      flamethrower__active : bool;
                                      flamethrower__streamEffectTemplate : string;
                                      flamethrower__streamEffectNodeIdx : int;
                                      var flamethrower__streamEffectEid : EntityId&)
  if flamethrower__active
    if !flamethrower__streamEffectEid && flamethrower__streamEffectNodeIdx >= 0
      flamethrower__streamEffectEid = createEntity(flamethrower__streamEffectTemplate) <| $(var init : ComponentsInitializer)
        var tm : float3x4
        geomtree_getNodeWtmScalar(animchar.nodeTree, flamethrower__streamEffectNodeIdx, tm)
        set(init, "transform", tm)
      attach_to_node(flamethrower__streamEffectEid, eid, flamethrower__streamEffectNodeIdx)
  elif flamethrower__streamEffectEid != INVALID_ENTITY_ID
    destroyEntity(flamethrower__streamEffectEid)
    flamethrower__streamEffectEid = INVALID_ENTITY_ID

[es(tag=gameClient, track=flamethrower__flameCurrentLength)]
def flamethrower_stream_effect_distance(evt : Event;
                                        flamethrower__flameCurrentLength : float;
                                        flamethrower__maxFlameLength : float;
                                        flamethrower__streamEffectEid : EntityId)

  if !!flamethrower__streamEffectEid
    query(flamethrower__streamEffectEid) <| $ [es] (var transform : float3x4&)
      transform[1] *= flamethrower__flameCurrentLength / flamethrower__maxFlameLength

[es(tag=gameClient, track=flamethrower__active)]
def flamethrower_turret_manage_stream_effect(evt : Event;
                                             turret__flashNodeId : int;
                                             turret__owner : EntityId;
                                             flamethrower__active : bool;
                                             flamethrower__streamEffectTemplate : string;
                                             flamethrower__flameCurrentLength : float;
                                             flamethrower__maxFlameLength : float;
                                             flamethrower__streamEffectLocalTm : float3x4;
                                             var flamethrower__streamEffectNodeIdx : int&;
                                             var flamethrower__streamEffectEid : EntityId&)
  flamethrower__streamEffectNodeIdx = turret__flashNodeId
  if flamethrower__active
    if !flamethrower__streamEffectEid && flamethrower__streamEffectNodeIdx >= 0
      query(turret__owner) <| $ [es] (eid : EntityId; animchar : AnimcharBaseComponent)
        flamethrower__streamEffectEid = createEntity(flamethrower__streamEffectTemplate) <| $(var init : ComponentsInitializer)
          var tm : float3x4
          geomtree_getNodeWtmScalar(animchar.nodeTree, flamethrower__streamEffectNodeIdx, tm)
          set(init, "transform", tm * flamethrower__streamEffectLocalTm)
          set(init, "effect__distance_scale", flamethrower__flameCurrentLength / flamethrower__maxFlameLength)
        attach_to_node(flamethrower__streamEffectEid, eid, flamethrower__streamEffectNodeIdx, flamethrower__streamEffectLocalTm)
  elif flamethrower__streamEffectEid != INVALID_ENTITY_ID
    destroyEntity(flamethrower__streamEffectEid)
    flamethrower__streamEffectEid = INVALID_ENTITY_ID

[es(tag=server, track=human_gun_attached)]
def flamethrower_disable_unattached(evt : Event;
                                    human_gun_attached : bool;
                                    var flamethrower__active : bool&)
  if !human_gun_attached
    flamethrower__active = false
