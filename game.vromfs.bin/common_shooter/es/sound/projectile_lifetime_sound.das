require ecs
require soundEvent
require DagorMath


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(animchar_render_es, shell_fly_sound_with_transform, shell_fly_sound_with_ballistics))]
def projectile_lifetime_sound(evt : Event;
                              projectile_lifetime_sound__path : string;
                              var projectile_lifetime_sound__event : SoundEvent&;
                              projectile__lifeTime : float;
                              projectile__minLifeTime : float;
                              projectile__exploded : bool;
                              projectile__stopped : bool;
                              transform : float3x4)
  let enable = !projectile__exploded && !projectile__stopped && projectile__lifeTime > 0. && projectile__lifeTime < projectile__minLifeTime
  if projectile_lifetime_sound__event.enabled != enable
    projectile_lifetime_sound__event.enabled = enable
    if enable
      projectile_lifetime_sound__event |> play(projectile_lifetime_sound__path, transform[3])
    else
      abandon(projectile_lifetime_sound__event.handle)
  if projectile_lifetime_sound__event.enabled
    set_pos(projectile_lifetime_sound__event.handle, transform[3])
    set_var(projectile_lifetime_sound__event.handle, "bomb_timer", cvt(projectile__lifeTime, 0., projectile__minLifeTime, 1., 0.))
