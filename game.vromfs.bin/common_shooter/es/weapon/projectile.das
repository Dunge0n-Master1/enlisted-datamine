require ecs
require app
require DaWeapons
require DaWeaponProps
require Dacoll
require Ballistics
require BallisticsProps
require DagorMath
require DagorSystem
require EnlistedDm
require EnlistedWeapon
require AnimV20
require GeomNodeTree
require GamePhys
require enlisted.events_enlisted
require ecs.safe


[es(on_appear, no_order)]
def projectile_init_created_es(evt : Event;
                               eid : EntityId;
                               launch_desc : LaunchDesc;
                               var projectile__prevPos : float3&)
  if int(launch_desc.gunPropsId) < 0
    logerr("Removed bad projectile entity {eid} created not by gun of template {getEntityTemplateName(eid)}")
    destroyEntity(eid)
    return
  if (length_sq(launch_desc.tm[3]) < 1e10)
    projectile__prevPos = launch_desc.tm[3]
  else
    logerr("invalid data in projectile info {eid} {getEntityTemplateName(eid)} {launch_desc.tm[3]}")
    destroyEntity(eid)


[es(on_appear, no_order)]
def projectile_phys_created_es(evt : Event;
                               launch_desc : LaunchDesc&;
                               projectile__isBomb : bool = false;
                               projectile__hasKv : bool = true;
                               var projectile__isUnderwater : bool&;
                               var projectile_ballistics_props : ProjectileProps;
                               var projectile__maxLifeTime : float&;
                               var projectile_ballistics : ProjectileBallistics)
  if projectile__isBomb
    return

  projectile_get_props(int(launch_desc.shellId.shellId)) <| $(bulletProps : ProjectileProps)
    projectile_ballistics_props = bulletProps

  projectile__maxLifeTime = projectile__maxLifeTime <= 0. ? safediv(projectile_ballistics_props.maxDistance, length(launch_desc.vel)) : projectile__maxLifeTime

  if projectile__hasKv
    let t = 0.0
    traceht_water_at_time(launch_desc.tm[3], t, get_sync_time(), projectile__isUnderwater)
    let density = projectile__isUnderwater ? water_density() : atmosphere_density(launch_desc.tm[3].y)
    projectile_ballistics |> projectile_ballistics_setupWithKV(projectile_ballistics_props,
                                                              launch_desc.tm[3],
                                                              launch_desc.vel,
                                                              1.0f, density)
  else
    projectile_ballistics |> projectile_ballistics_setup(launch_desc.tm[3], launch_desc.vel, 1.0f)


[es(on_appear)]
def projectile_created_es(evt : Event;
                          gunEid : EntityId;
                          launch_desc : LaunchDesc;
                          var projectile__visualPos : float3&;
                          var detonation__timer : float&;
                          var dm_projectile_state : ProjectileState&;
                          var projectile__hitEffectDescriptor : int&;
                          var projectile__explEffectDescriptor : int&)
  query(gunEid) <| $ [es] (gun_hit_fx__hitEffectDescriptor : int const?;
                           gun_hit_fx__explEffectDescriptor : int const?)
    if gun_hit_fx__hitEffectDescriptor != null
      projectile__hitEffectDescriptor = *gun_hit_fx__hitEffectDescriptor

    if gun_hit_fx__explEffectDescriptor != null
      projectile__explEffectDescriptor = *gun_hit_fx__explEffectDescriptor

  detonation_get_props(int(launch_desc.shellId.shellId)) <| $(detonationProps : DetonationProps)
    detonation__timer = detonationProps.timer

    projectile__visualPos = launch_desc.tm[3]

    dm_projectile_state.damagePropsId = int(launch_desc.shellId.damageId)
    dm_projectile_state.ballisticsPropsId = int(launch_desc.shellId.ballisticsId)
    dm_projectile_state.projectileTypePropsId = -1

    shell_entity_get_props(int(launch_desc.shellId.shellId)) <| $(entProps : ShellEntityTypeProps)
      let bulletType = entProps.bulletType
      if bulletType != ""
        dm_projectile_state.projectileTypePropsId = getBulletTypeId(get_damage_model_params(), bulletType)
      dm_projectile_state.startPos = launch_desc.tm[3]
      dm_projectile_state.startVel = launch_desc.vel


struct ProjectileUpdateResult
  prevPos : float3
  dirLen : float


def update_projectile_ballistics(var projectile_ballistics : ProjectileBallistics;
                                 dt : float)
  // Here we want to update projectile ballistics, the thing is that code is run both on server and client.
  // We want to make sure that having the same starting point and velocity the projectile will end up
  // in the same (more or less) spot both on server and client. The problem is that projectile_ballistics.move
  // has non-linear dependency from 'dt', thus, we can't just pass our 'dt' there, if 'dt' is high enough it can
  // accumulate velocity and positional errors. Thus, we quantize 'dt' with FIXED_DT and call 'move' as many
  // times as needed and then call 'move' with the rest of dt. Before that change we could have ended up with tens of meters of
  // error in projectile trajectory, now, the error is in order of centimeters.

  // The smaller FIXED_DT the better, luckily projectile_ballistics.move
  // is very simple and cheap and 90fps boundary is more than enough to minimize error.
  // Also, it's better to have the same quantization on server and client, so be sure to bump
  // net proto version if you ever change this.
  let FIXED_DT = 1.0 / 90.0

  var deltaTime = dt

  var ures : ProjectileUpdateResult
  let numSteps = floori(deltaTime / FIXED_DT)
  deltaTime -= float(numSteps) * FIXED_DT
  ures.prevPos = projectile_ballistics.state.pos
  for _i in range(numSteps)
    // Don't increment tick each step, this one tick alone moves the
    // projectile by deltaTime.
    let atTick = projectile_ballistics.state.atTick + 1
    projectile_ballistics |> projectile_ballistics_move(atTick, FIXED_DT)

  if deltaTime > 1e-5f // Don't use very small 'deltaTime' to avoid float errors.
    let atTick = projectile_ballistics.state.atTick + 1
    projectile_ballistics |> projectile_ballistics_move(atTick, deltaTime)
  ures.dirLen = length(projectile_ballistics.state.pos - ures.prevPos)
  return ures


[es(before=update_projectile_es)]
def update_projectile_phys_es(info : ParallelUpdateFrameDelayed;
                              launch_desc : LaunchDesc;
                              projectile__lifeTime : float;
                              projectile__isBomb : bool = false;
                              projectile__stopped : bool;
                              var projectile_ballistics : ProjectileBallistics;
                              var dm_projectile_state : ProjectileState;
                              var projectile__prevPos : float3&)
  if projectile__isBomb || projectile__stopped
    return

  let dt = (projectile__lifeTime == 0.0) ? (info.dt + launch_desc.initialLifeTime) : info.dt

  let ures = update_projectile_ballistics(projectile_ballistics, dt)
  projectile__prevPos = ures.prevPos
  dm_projectile_state.distance += ures.dirLen


[es(no_order, REQUIRE_NOT=projectile__inactive)]
def update_projectile_es(info : ParallelUpdateFrameDelayed;
                         eid : EntityId;
                         ownerEid : EntityId;
                         launch_desc : LaunchDesc;
                         detonation__timer : float;
                         projectile_ballistics : ProjectileBallistics;
                         projectile__prevPos : float3;
                         var projectile__visualPos : float3&;
                         var projectile__exploded : bool&;
                         var projectile__lifeTime : float&)
  let dt = (projectile__lifeTime == 0.0) ? (info.dt + launch_desc.initialLifeTime) : info.dt

  projectile__lifeTime += dt

  projectile__visualPos = projectile_ballistics.state.pos

  if detonation__timer >= 0.0 && projectile__lifeTime > detonation__timer
    sendEvent(eid, [[CmdDetonateShellServer pos = projectile_ballistics.state.pos,
                                              offender = ownerEid,
                                              prev_pos = projectile__prevPos,
                                              vel = projectile_ballistics.state.vel,
                                              ignore_entity = INVALID_ENTITY_ID,
                                              normal = float3(),
                                              alternative_offender = INVALID_ENTITY_ID]])
    projectile__exploded = true


[es(on_appear)]
def projectile_trajectory_init_es(evt : Event;
                                  eid : EntityId;
                                  animchar : AnimcharBaseComponent;
                                  trajectory__startNodeName : string = "Bip01 Spine1";
                                  var trajectory__startNodeIdx : int&)
  trajectory__startNodeIdx = *animchar.nodeTree |> geomtree_findNodeIndex(trajectory__startNodeName)
  if trajectory__startNodeIdx < 0
    logerr("{eid} <{getEntityTemplateName(eid)}>: Can't find startNodeName node <{trajectory__startNodeName}>")