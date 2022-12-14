require ecs
require ecs.common
require app
require game.es.events
require GamePhys
require DaWeapons
require DagorMath
require DagorSystem
require Dacoll
require Ballistics
require BallisticsProps
require EnlistedDm
require enlisted.events_enlisted


[es(on_appear, before=projectile_phys_created_es)]
def bomb_phys_created_es(evt : Event;
                         launch_desc : LaunchDesc;
                         projectile__isBomb : bool = false;
                         var projectile__isUnderwater : bool&;
                         var bomb_ballistics_props : ShellProps;
                         var bomb_ballistics_curr : ShellState;
                         var bomb_ballistics_prev : ShellState;
                         var projectile_ballistics : ProjectileBallistics;
                         var projectile_ballistics_props : ProjectileProps;
                         var bomb__launcherVertical : float3&;
                         var transform : float3x4&)
  if !projectile__isBomb
    return

  shell_get_props(int(launch_desc.shellId.shellId)) <| $(shellProps : ShellProps)
    bomb_ballistics_props = shellProps

    let currTime = get_sync_time()

    let t = 0.0
    traceht_water_at_time(launch_desc.tm[3], t, currTime, projectile__isUnderwater)

    let orient = quat(launch_desc.tm)
    let omega = float3()
    ballistics_setup(bomb_ballistics_curr,
                    launch_desc.tm[3], orient, launch_desc.vel, omega,
                    currTime, 0.0, launch_desc.bombBayHeight, projectile__isUnderwater, true, 0.0)
    bomb_ballistics_prev = bomb_ballistics_curr

    projectile_ballistics_props = bomb_ballistics_props.ballisticProps

    let density = projectile__isUnderwater ? water_density() : atmosphere_density(launch_desc.tm[3].y)
    projectile_ballistics |> projectile_ballistics_setupWithKV(bomb_ballistics_props.ballisticProps,
                                                              launch_desc.tm[3], launch_desc.vel,
                                                              1.0f, density)

    make_tm(bomb_ballistics_curr.orientation, transform)
    transform[3] = bomb_ballistics_curr.position

    bomb__launcherVertical = launch_desc.tm[1]


def update_bomb_ballistics(bomb_ballistics_props : ShellProps;
                           current_time : float;
                           launcher_vertical : float3&;
                           owner_vel : float3&;
                           bomb__extForce : float3&;
                           bomb__extMoment : float3&;
                           bomb__lostMass : float;
                           var bomb_ballistics_curr : ShellState;
                           var bomb_ballistics_prev : ShellState;
                           var projectile_ballistics : ProjectileBallistics;
                           var projectile__ballisticsUpdated : bool&)
  projectile__ballisticsUpdated = false
  if bomb_ballistics_curr.updatedUpToTime + PHYSICS_UPDATE_FIXED_DT >= current_time
    return false
  projectile__ballisticsUpdated = true

  bomb_ballistics_prev = bomb_ballistics_curr

  let t = 0.0
  traceht_water_at_time(bomb_ballistics_curr.position,
                        t, current_time,
                        bomb_ballistics_curr.isUnderWater)

  while bomb_ballistics_curr.updatedUpToTime + PHYSICS_UPDATE_FIXED_DT < current_time
    using() <| $(var shellEnv : ShellEnv#)
      shellEnv.flow = float3()
      shellEnv.extForce = bomb__extForce
      shellEnv.extMoment = bomb__extMoment
      shellEnv.fins = float2(0.0, 0.0)
      shellEnv.lostMass = bomb__lostMass
      shellEnv.dispersion = 0.0
      shellEnv.ownerVel = owner_vel
      shellEnv.vertical = launcher_vertical
      shellEnv.immersionDepthMax = 0.0
      shellEnv.useGravity = true

      let currentTime = bomb_ballistics_curr.updatedUpToTime + PHYSICS_UPDATE_FIXED_DT
      ballistics_simulate(shellEnv,
                          bomb_ballistics_props,
                          bomb_ballistics_curr,
                          PHYSICS_UPDATE_FIXED_DT,
                          currentTime)
      projectile_ballistics.state.atTick++

  projectile_ballistics.state.pos = bomb_ballistics_curr.position
  projectile_ballistics.state.vel = bomb_ballistics_curr.velocity

  return true


[es(before=update_projectile_es)]
def update_bomb_phys_es(info : ParallelUpdateFrameDelayed;
                        ownerEid : EntityId;
                        bomb_ballistics_props : ShellProps;
                        bomb__launcherVertical : float3;
                        bomb__extForce : float3;
                        bomb__extMoment : float3;
                        bomb__lostMass : float;
                        projectile__isBomb : bool = false;
                        projectile__stopped : bool;
                        var transform : float3x4;
                        var bomb_ballistics_curr : ShellState;
                        var bomb_ballistics_prev : ShellState;
                        var projectile_ballistics : ProjectileBallistics;
                        var dm_projectile_state : ProjectileState;
                        var projectile__prevPos : float3&;
                        var projectile__ballisticsUpdated : bool&)
  if !projectile__isBomb || projectile__stopped
    return

  var ownerVel = float3()
  query(ownerEid) <| $ [es] (net_phys__currentStateVelocity : float3 = float3())
    ownerVel = net_phys__currentStateVelocity

  if update_bomb_ballistics(bomb_ballistics_props,
                            info.curTime,
                            bomb__launcherVertical,
                            ownerVel,
                            bomb__extForce,
                            bomb__extMoment,
                            bomb__lostMass,
                            bomb_ballistics_curr,
                            bomb_ballistics_prev,
                            projectile_ballistics,
                            projectile__ballisticsUpdated)
    projectile__prevPos = bomb_ballistics_prev.position
    dm_projectile_state.distance += length(bomb_ballistics_prev.position - bomb_ballistics_curr.position)

  let t = safediv(info.curTime - bomb_ballistics_prev.updatedUpToTime,
                  bomb_ballistics_curr.updatedUpToTime - bomb_ballistics_prev.updatedUpToTime)
  let orient = slerp(bomb_ballistics_prev.orientation, bomb_ballistics_curr.orientation, t)
  make_tm(orient, transform)
  transform[3] = lerp(bomb_ballistics_prev.position, bomb_ballistics_curr.position, float3(t))


[es(on_event=(EventProjectileHitScene, EventOnProjectileHit))]
def bomb_hit_es(evt : Event;
                projectile__isBomb : bool = false;
                projectile_ballistics : ProjectileBallistics;
                var bomb_ballistics_curr : ShellState;
                var bomb_ballistics_prev : ShellState;
                var transform : float3x4)
  if !projectile__isBomb
    return

  bomb_ballistics_curr.position = projectile_ballistics.state.pos
  bomb_ballistics_prev.position = projectile_ballistics.state.pos
  bomb_ballistics_curr.velocity = projectile_ballistics.state.vel
  bomb_ballistics_prev.velocity = projectile_ballistics.state.vel
  make_tm(bomb_ballistics_curr.orientation, transform)
  transform[3] = bomb_ballistics_curr.position
