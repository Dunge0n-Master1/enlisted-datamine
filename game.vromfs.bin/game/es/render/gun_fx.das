require ecs
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

[es(tag=render, after=after_animchar_update_sync, before=effect_attached_es)]
def gun_fx_update(info : ParallelUpdateFrameDelayed;
                  gun_fx__gunEid : EntityId;
                  gun_fx__nodeId : int;
                  var transform : float3x4&;
                  gun_fx__nodeMultTm : float3x4 const?)
  query(gun_fx__gunEid) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, gun_fx__nodeId, tm)
    if gun_fx__nodeMultTm == null
      transform = tm
    else
      transform = tm * (*gun_fx__nodeMultTm)

[es(tag=render, no_order, REQUIRE=gun_fx__destroyIfGunDoesNotExist)]
def gun_fx_destroy_if_gun_does_not_exist(info : ParallelUpdateFrameDelayed; eid : EntityId; gun_fx__gunEid : EntityId)
  if !doesEntityExist(gun_fx__gunEid)
    destroyEntity(eid)
