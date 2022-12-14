require ecs
require soundEvent
require soundSystem
require Ballistics
require BallisticsProps
require game.utils.hero
require math.base
require DagorMath


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=update_projectile_es)]
def projectile_wiz_sound(evt : Event;
                         ownerEid : EntityId;
                         projectile__prevPos : float3;
                         projectile_ballistics : ProjectileBallistics;
                         projectile_ballistics_props : ProjectileProps;
                         projectile_sound__wizSound : das_string const?;
                         projectile_sound__caliberToDist = float4(0.005, 0.1, 2., 20.);
                         projectile__stopped : bool = false)

  let path = projectile_sound__wizSound != null ? string(*projectile_sound__wizSound) : "impact/wiz"
  if path == "" || projectile__stopped || has(ownerEid, "hero")
    return
  let listener = get_listener_pos()
  let dirToPos = normalize(projectile_ballistics.state.pos - projectile__prevPos)
  let closestPointOnDir = projectile_ballistics.state.pos + dirToPos * dot(listener - projectile_ballistics.state.pos, dirToPos)
  let maxWizDistanceSq = cvt(projectile_ballistics_props.caliber, projectile_sound__caliberToDist.x, projectile_sound__caliberToDist.y, square(projectile_sound__caliberToDist.z), square(projectile_sound__caliberToDist.w))
  if length_sq(closestPointOnDir - listener) > maxWizDistanceSq
    return
  if dot(projectile__prevPos - closestPointOnDir, dirToPos) <= 0. && dot(projectile_ballistics.state.pos - closestPointOnDir, dirToPos) > 0.
    var event = play(path, closestPointOnDir)
    set_var(event, "cal", projectile_ballistics_props.caliber)
    abandon(event)
