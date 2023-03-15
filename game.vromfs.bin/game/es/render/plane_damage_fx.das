require ecs
require fx
require EnlistedPlane


[es(tag=render, no_order)]
def plane_effect_update_emitter_pos(info : UpdateStageInfoAct;
                                    plane_effect__planeEid : EntityId;
                                    plane_effect__emitterLocalPos : float3;
                                    plane_effect__minDistSqToUpdateEmitterTm : float;
                                    var plane_effect__emitterPos : float3&;
                                    var effect__velocity : float3&)
  query(plane_effect__planeEid) <| $ [es] (transform : float3x4; animchar__updatable : bool; plane_net_phys : PlaneActor)
    if animchar__updatable
      let emitterPos = transform * plane_effect__emitterLocalPos
      if length_sq(emitterPos - plane_effect__emitterPos) > plane_effect__minDistSqToUpdateEmitterTm
        assume vel = plane_net_phys.phys.currentState.velocity
        effect__velocity = float3(vel.x, vel.y, vel.z)
        plane_effect__emitterPos = emitterPos


[es(tag=render, on_appear, track=plane_effect__emitterPos)]
def plane_effect_update_emitter_tm(evt : Event; plane_effect__planeEid : EntityId; plane_effect__emitterPos : float3; var effect : TheEffect)
  query(plane_effect__planeEid) <| $ [es] (transform : float3x4)
    var emitterTm = transform
    emitterTm[3] = plane_effect__emitterPos
    effect_set_emitter_tm(effect, emitterTm)
