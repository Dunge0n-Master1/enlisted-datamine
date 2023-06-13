require ecs
require soundEvent
require soundSystem
require Ballistics
require BallisticsProps
require math.base
require DagorMath
require strings


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=trace_scene_after_update_projectile_es)]
def projectile_wiz_sound(evt : Event)

  let listener = get_listener_pos()
  find_query() <| $ [es] (ownerEid : EntityId;
                          projectile__prevPos : float3;
                          projectile_ballistics : ProjectileBallistics;
                          projectile_ballistics_props : ProjectileProps;
                          projectile_trace_info__dir : float3;
                          projectile_sound__wizSound = "impact/wiz";
                          projectile_sound__caliberToDist = float4(0.005, 0.1, 2., 20.);
                          projectile__stopped : bool = false)

    if !projectile__stopped && !empty(projectile_sound__wizSound) && !has(ownerEid, "hero")
      assume dir = projectile_trace_info__dir
      assume pos = projectile_ballistics.state.pos
      assume prevPos = projectile__prevPos
      let closestPointOnDir = pos + dir * dot(listener - pos, dir)
      if dot(prevPos - closestPointOnDir, dir) <= 0. && dot(pos - closestPointOnDir, dir) > 0.
        if length_sq(closestPointOnDir - listener) < square(cvt(projectile_ballistics_props.caliber, projectile_sound__caliberToDist.x, projectile_sound__caliberToDist.y, projectile_sound__caliberToDist.z, projectile_sound__caliberToDist.w))
          var event = play(projectile_sound__wizSound, closestPointOnDir)
          set_var(event, "cal", projectile_ballistics_props.caliber)
          abandon(event)
          return true
    return false
