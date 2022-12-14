require ecs
require math
require math.base
require DagorSystem
require DagorRandom
require DagorMath
require smokeTracers
require daslib/assert_once

[es(tag=render, no_order)]
def background_tracer_es(info : ecs::UpdateStageInfoAct;
                         eid : ecs::EntityId;
                         var background_tracer__pos : float3&;
                         background_tracer__vel : float3;
                         background_tracer__id : int;
                         var background_tracer__ttl : float&)
  assert_once(background_tracer__id >= 0)
  if background_tracer__id < 0
    return
  if (background_tracer__ttl > 0.0)
    background_tracer__pos += background_tracer__vel * info.dt
    background_tracer__ttl -= info.dt
    update_smoke_tracer_pos(uint(background_tracer__id), background_tracer__pos)
  else
    leave_smoke_tracer(uint(background_tracer__id))
    destroyEntity(eid)

[es(tag=render, no_order)]
def tracer_launcher_es(info : ecs::UpdateStageInfoAct;
                       tracer_launcher__short_cooldown : float;
                       tracer_launcher__long_cooldown_probability : float;
                       tracer_launcher__long_cooldown_min_max : float2;
                       tracer_launcher__bullet_size : float;
                       tracer_launcher__bullet_speed : float;
                       tracer_launcher__bullet_ttl : float;
                       tracer_launcher__bullet_color : float3;
                       tracer_launcher__shoot_direction : float2; //angles in spherical coordinates
                       tracer_launcher__rotate_range : float2;
                       tracer_launcher__rotate_speed : float;
                       var tracer_launcher__time_to_fire : float&;
                       transform : float3x4)
  tracer_launcher__time_to_fire -= info.dt;
  if tracer_launcher__time_to_fire > 0.0
    return
  if rnd_float(0.0, 1.0) < tracer_launcher__long_cooldown_probability
    tracer_launcher__time_to_fire += rnd_float(tracer_launcher__long_cooldown_min_max.x,
                                                  tracer_launcher__long_cooldown_min_max.y)
  else
    tracer_launcher__time_to_fire += tracer_launcher__short_cooldown
  let pos = transform[3]
  let t = info.curTime * tracer_launcher__rotate_speed;
  let theta = DEG_TO_RAD * (tracer_launcher__shoot_direction.x +
                            tracer_launcher__rotate_range.x * sin(t))
  let phi = DEG_TO_RAD * (tracer_launcher__shoot_direction.y +
                          tracer_launcher__rotate_range.y * cos(1.25 * t))
  var sinTheta, cosTheta, sinPhi, cosPhi : float
  sincos(theta, sinTheta, cosTheta)
  sincos(phi, sinPhi, cosPhi)
  let dir = float3(cosTheta * cosPhi, sinTheta, cosTheta * sinPhi)
  let colorTtl = float4(tracer_launcher__bullet_color.x, tracer_launcher__bullet_color.y,
                        tracer_launcher__bullet_color.z, tracer_launcher__bullet_ttl)
  let smoke = float4(0, 0, 0, 0)
  let id = create_smoke_tracer(pos, dir, tracer_launcher__bullet_size, Color4(smoke), Color4(colorTtl), 0.0001)
  if id < 0
    return
  createEntity("background_tracer") <| $(var init : ComponentsInitializer)
    set(init, "background_tracer__pos", pos)
    set(init, "background_tracer__vel", dir * tracer_launcher__bullet_speed)
    set(init, "background_tracer__id", id)
    set(init, "background_tracer__ttl", tracer_launcher__bullet_ttl)
