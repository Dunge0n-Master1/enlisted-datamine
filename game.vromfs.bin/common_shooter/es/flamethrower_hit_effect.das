require ecs
require math.base
require game.es.events
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

[es(tag=gameClient, no_order)]
def flamethrower_update_hit_effect(evt : ParallelUpdateFrameDelayed;
                                   animchar : AnimcharBaseComponent;
                                   flamethrower__active : bool;
                                   flamethrower__hitAnything : bool;
                                   flamethrower__flameCurrentLength : float;
                                   flamethrower__hitEffectTemplate : string;
                                   flamethrower__streamEffectNodeIdx : int;
                                   var flamethrower__hitEffectEid : EntityId&)
  if !flamethrower__active || !flamethrower__hitAnything
    if flamethrower__hitEffectEid != INVALID_ENTITY_ID
      destroyEntity(flamethrower__hitEffectEid)
      flamethrower__hitEffectEid = INVALID_ENTITY_ID
  else
    var newTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, flamethrower__streamEffectNodeIdx, newTm)
    let endPos = newTm[3] + newTm[1] * flamethrower__flameCurrentLength
    newTm[0] = newTm[0]
    newTm[1] = -newTm[1] // we want top of the effect to face the gun
    newTm[2] = normalize(cross(newTm[0], newTm[1]))
    newTm[3] = endPos
    if flamethrower__hitEffectEid == INVALID_ENTITY_ID
      flamethrower__hitEffectEid = createEntity(flamethrower__hitEffectTemplate) <| $(init)
        init |> set("transform", newTm)
    query(flamethrower__hitEffectEid) <| $ [es] (var transform : float3x4)
      transform = newTm

[es(tag=gameClient, on_disappear)]
def flamethrower_destroy_hit_effect_on_death(evt : Event;
                                             flamethrower__hitEffectEid : EntityId)
  destroyEntity(flamethrower__hitEffectEid)
