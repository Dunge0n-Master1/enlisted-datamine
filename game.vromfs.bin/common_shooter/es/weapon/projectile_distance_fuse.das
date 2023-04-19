require ecs
require math.base
require DaWeapons
require Ballistics
require DngWeapon
require enlisted.events_enlisted

[es(tag=server, no_order, REQUIRE_NOT=projectile__inactive)]
def projectile_distance_fuse(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             ownerEid : EntityId;
                             launch_desc : LaunchDesc;
                             projectile_ballistics : ProjectileBallistics;
                             projectile__prevPos : float3;
                             projectile__maxDistanceFromStartSq : float;
                             var projectile__exploded : bool&)
  assume startPos = launch_desc.tm[3]
  assume currentPos = projectile_ballistics.state.pos
  let norm : float3
  if projectile__maxDistanceFromStartSq > 0.0 && distance_sq(startPos, currentPos) > projectile__maxDistanceFromStartSq
    sendEvent(eid, [[CmdDetonateShellServer pos = projectile_ballistics.state.pos,
                                              offender = ownerEid,
                                              prev_pos = projectile__prevPos,
                                              vel = projectile_ballistics.state.vel,
                                              ignore_entity = INVALID_ENTITY_ID,
                                              normal = norm,
                                              alternative_offender = INVALID_ENTITY_ID]])
    projectile__exploded = true


[es(tag=server, on_appear)]
def projectile_distance_fuse_init_on_launch(evt : Event;
                                            gunEid : EntityId;
                                            projectile__timeFuseDistanceError : float;
                                            var projectile__maxDistanceFromStartSq : float&)
  let distance = get_float(gunEid, "gun__fuzeDistance") ?? 0.0
  if distance > 0.0
    assume error = projectile__timeFuseDistanceError
    let roughDistance = error > 0.0 ? error * floor((distance + error * 0.5) / error) : distance
    projectile__maxDistanceFromStartSq = square(roughDistance)
