require ecs
require app
require DaWeapons
require Ballistics
require BallisticsProps
require DagorMath
require DagorSystem
require enlisted.events_enlisted


[es(on_appear, after=bomb_phys_created_es)]
def rocket_motor_phys_created_es(evt : Event;
                                 projectile__isBomb : bool = false;
                                 launch_desc : LaunchDesc;
                                 var rocket_motor_props : RocketMotorProps;
                                 var bomb_ballistics_curr : ShellState;
                                 var projectile_ballistics : ProjectileBallistics;
                                 var rocket__launchTime : float&)
  if projectile__isBomb
    rocket_motor_get_props(int(launch_desc.shellId.shellId)) <| $(rocketMotorProps : RocketMotorProps)
      rocket_motor_props = rocketMotorProps
      rocket__launchTime = get_sync_time()

      let seed = 0
      apply_rocket_start_speed(rocket_motor_props, bomb_ballistics_curr.orientation,
                              1.0, seed, bomb_ballistics_curr.velocity)
      projectile_ballistics.state.vel = bomb_ballistics_curr.velocity


[es(before=update_bomb_phys_es)]
def update_rocket_motor_phys_es(info : ParallelUpdateFrameDelayed;
                                projectile__isBomb : bool = false;
                                projectile__stopped : bool;
                                bomb_ballistics_props : ShellProps;
                                rocket_motor_props : RocketMotorProps;
                                rocket__launchTime : float;
                                var bomb_ballistics_curr : ShellState;
                                var projectile_ballistics : ProjectileBallistics;
                                var bomb__extForce : float3&;
                                var bomb__extMoment : float3&;
                                var bomb__lostMass : float&)
  if projectile__isBomb && !projectile__stopped
    let flightTime = get_sync_time() - rocket__launchTime

    var localForce : float3
    var localForceStable : float3
    var torque : float3
    let fins = float2()
    let rotate = float2()
    calc_rocket_motor_thrust_mass(rocket_motor_props, fins, rotate,
                                  flightTime, bomb_ballistics_curr.seed,
                                  localForce, localForceStable, torque, bomb__lostMass)

    bomb__extForce = bomb_ballistics_curr.orientation * localForce
    let localArm = float3(-0.5 * bomb_ballistics_props.length, 0.0, 0.0)
    bomb__extMoment = cross(localForceStable, localArm)

    apply_rocket_end_speed(rocket_motor_props, bomb_ballistics_curr.velocity)
    projectile_ballistics.state.vel = bomb_ballistics_curr.velocity