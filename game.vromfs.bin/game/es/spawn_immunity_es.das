require ecs
require app
require math
require math.base
require enlisted.events_enlisted

[es]
def spawn_immunity_es(info : ParallelUpdateFrameDelayed;
                      var hitpoints__dmgMult : float&;
                      var spawn_immunity__timer : float&;
                      transform : float3x4;
                      spawn_immunity__initialPos : float3 const&;
                      spawn_immunity__immuneDistance : float = 5.0f)
  if spawn_immunity__timer < 0.0f
    return

  spawn_immunity__timer -= info.dt

  if spawn_immunity__timer < 0.0f
    hitpoints__dmgMult = 1.0f
    return

  let distSq = distance_sq(spawn_immunity__initialPos, transform[3])
  if distSq < square(spawn_immunity__immuneDistance)
    hitpoints__dmgMult = 0.0f
  else
    hitpoints__dmgMult = 1.0f
    spawn_immunity__timer = -1.f

[es(on_appear)]
def spawn_immunity_init_es(evt : Event;
                           var spawn_immunity__initialPos : float3&;
                           transform : float3x4)
  spawn_immunity__initialPos = transform[3];

[es(tag=server, on_appear, REQUIRE=vehicle)]
def apply_vehicle_immunity_on_spawn(evt : Event;
                                    hitpoints__invulnerabiltyTime : float;
                                    var hitpoints__invulnerableTimeTo : float&)
  hitpoints__invulnerableTimeTo = get_sync_time() + hitpoints__invulnerabiltyTime
