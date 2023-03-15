require ecs
require math.base
require Gun
require PhysVars
require DagorRandom
require DagorMath
require Dacoll
require GamePhys
require DaWeapons
require DaWeaponProps
require walkerai
require game.utils.team
require common_shooter.events_common_shooter
require daslib/safe_addr
require enlisted.events_enlisted

[es(tag=server)]
def auto_gun_controller_es(info : ParallelUpdateFrameDelayed;
                           gun__curShellId : ShellPropIds;
                           auto_gun_controller__targetTeam : int;
                           auto_gun_controller__targetDist : float;
                           auto_gun_controller__enabled : bool;
                           isAlive : bool;
                           team : int;
                           auto_gun_controller__changeTargetTime = 10.f;
                           auto_gun_controller__traceTime : float = -1.f;
                           auto_gun_controller__targetOffset : float3 = float3();
                           var auto_gun_controller__lastTargetPos : float3?;
                           var mounted_gun : MountedGun;
                           var phys_vars : PhysVars;
                           var gun : Gun;
                           var auto_gun_controller__selectedTarget : EntityId&;
                           var auto_gun_controller__nextTraceTime : float&;
                           var auto_gun_controller__nextChangeTargetTime : float&)
  if !auto_gun_controller__enabled || !isAlive || mounted_gun.locked /* somebody is controlling us */
    return
  mounted_gun.wishShoot = false // allow to reload after shot
  let gunShootPos = gun.shootNodePos
  let aimDirClampVal = 0.95f
  let canShoot = info.curTime >= gun.nextShotAtTime
  if (!doesEntityExist(auto_gun_controller__selectedTarget) ||
      !(get_bool(auto_gun_controller__selectedTarget, "isAlive") ?? false) ||
      info.curTime > auto_gun_controller__nextChangeTargetTime)
    if info.curTime < auto_gun_controller__nextTraceTime || !canShoot
      return
    // Find new target
    var targetList : array<EntityId>
    let gunTeam = team
    query() <| $ [es] (eid : EntityId; ai_target : Target; team : int; isAlive : bool)
      if !isAlive
        return
      var dir = ai_target.targetPos - gunShootPos
      let distSq = length_sq(dir)
      var validTeam = auto_gun_controller__targetTeam == TEAM_UNASSIGNED
      validTeam &&= gunTeam != team
      validTeam ||= auto_gun_controller__targetTeam == team
      if !validTeam || distSq > square(auto_gun_controller__targetDist)
        return
      var dist = sqrt(distSq)
      dir *= safeinv(dist)
      let initialDir = mounted_gun.initialDir
      let clampedDir = mounted_gun |> mounted_gun_clampAimDir(dir, initialDir)
      // check trace
      var norm : float3
      if dot(clampedDir, dir) > aimDirClampVal && !traceray_normalized(gunShootPos, dir, dist, norm)
        targetList |> push(eid)
    if length(targetList) > 0
      auto_gun_controller__selectedTarget = targetList[grnd() % length(targetList)]
    auto_gun_controller__nextTraceTime = info.curTime + auto_gun_controller__traceTime * rnd_float(0.9f, 1.1f)
    auto_gun_controller__nextChangeTargetTime = info.curTime + auto_gun_controller__changeTargetTime * rnd_float(0.9f, 1.1f)
  if !doesEntityExist(auto_gun_controller__selectedTarget)
    return

  query(auto_gun_controller__selectedTarget) <| $ [es] (ai_target : Target)
    if auto_gun_controller__lastTargetPos != null
      if !canShoot && length_sq(*auto_gun_controller__lastTargetPos - ai_target.targetPos) < 1e-5f
        return
      *auto_gun_controller__lastTargetPos = ai_target.targetPos
    var dir = ai_target.targetPos + auto_gun_controller__targetOffset - gunShootPos
    var dist = length(dir)
    if info.curTime > auto_gun_controller__nextTraceTime && canShoot
      auto_gun_controller__nextTraceTime = info.curTime + auto_gun_controller__traceTime * rnd_float(0.9f, 1.1f)
      let initialDir = mounted_gun.initialDir
      let clampedDir = mounted_gun |> mounted_gun_clampAimDir(dir, initialDir)
      let normDir = dir * safeinv(dist)
      var norm : float3
      if dot(clampedDir, normDir) < aimDirClampVal || traceray_normalized(gunShootPos, normDir, dist, norm)
        // obscured, drop target
        auto_gun_controller__selectedTarget = INVALID_ENTITY_ID
        return
    dir.y += get_vertical_offset(gun__curShellId, dist)
    dist = length(dir)
    dir *= safeinv(dist)
    let additionalAngles = float2()
    mounted_gun |> mounted_gun_setControls(gun, dir, dir, canShoot, info.dt, info.curTime, phys_vars, additionalAngles)


def get_vertical_offset(gun__curShellId : ShellPropIds; dist : float)
  var timeToTarget = 0.0
  shell_start_get_props(int(gun__curShellId.shellId)) <| $(shellStartProps : ShellStartProps)
    timeToTarget = safediv(dist, shellStartProps.speed)
  return gravity() * square(timeToTarget) * 0.5


[es(REQUIRE=(autoShoot, auto_shoot__applyGravityOffset), before=auto_shoot_es)]
def auto_shoot_gravity_offset_es(info : ParallelUpdateFrameDelayed;
                                 gun__curShellId : ShellPropIds;
                                 auto_shoot__gunPos : float3;
                                 auto_shoot__targetPos : float3;
                                 var auto_shoot__gunDir : float3&)
  var dir = auto_shoot__targetPos - auto_shoot__gunPos
  dir.y += get_vertical_offset(gun__curShellId, length(dir))
  auto_shoot__gunDir = normalize(dir)


def auto_shoot_event_send(info : ParallelUpdateFrameDelayed;
                          eid : EntityId;
                          auto_shoot__gunDir : float3;
                          auto_shoot__gunPos : float3;
                          auto_shoot__canShoot : bool;
                          auto_shoot__shouldShoot : bool)
  let isForReal = true
  let rndSeed = grnd()
  let gctrl = [[GunControls() shoot=auto_shoot__canShoot && auto_shoot__shouldShoot, wishShoot=false, boltActionMult = 1.0, timeStep = info.dt]]
  let gloc = GunLocation(auto_shoot__gunDir, auto_shoot__gunDir, auto_shoot__gunPos)
  sendEventImmediate(eid, [[CmdGunUpdate atTime=info.curTime, isForReal=isForReal, seed=rndSeed, gctrl=gctrl, gloc=gloc]])


[es(REQUIRE=autoShoot, REQUIRE_NOT=auto_shoot__earlyBreak, before=after_guns_update_sync)]
def auto_shoot_es(info : ParallelUpdateFrameDelayed;
                  eid : EntityId;
                  auto_shoot__gunDir : float3;
                  auto_shoot__gunPos : float3;
                  gun : Gun;
                  auto_shoot__shouldShoot : bool;
                  var auto_shoot__canShoot : bool&)
  auto_shoot__canShoot = info.curTime >= gun.nextShotAtTime && gun.curState.loaded
  auto_shoot_event_send(info, eid, auto_shoot__gunDir, auto_shoot__gunPos, auto_shoot__canShoot, auto_shoot__shouldShoot)
