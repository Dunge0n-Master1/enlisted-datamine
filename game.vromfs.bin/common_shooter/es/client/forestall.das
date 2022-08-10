require ecs
require math
require math.base
require math.ang
require dm
require game.utils.hero
require game.utils.team
require DaWeaponProps
require BallisticsProps
require Plane
require EnlistedPlane
require EnlistedCamera
require DagorSystem
require DagorMath
require DaWeapons
require common_shooter.es.forestall_common

struct ShellPropsData
  shellId : int
  ballisticsId : int

def get_first_turret_shell_props(turret_control__gunEids : EidList) : ShellPropsData
  var ballisticsId = -1
  var shellId = -1
  var found = false
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=firstTurretInput, REQUIRE_NOT=gun__isLauncher)] (gun__curShellId : ShellPropIds;
                                                                                       isForestall : bool)
      if isForestall
        ballisticsId = int(gun__curShellId.ballisticsId)
        shellId = int(gun__curShellId.shellId)
        found = true
    if found
      break
  return <- [[ShellPropsData shellId=shellId, ballisticsId=ballisticsId]]

def get_angle_and_dist_to_target(target_pos, forestall_pos, camera_pos, selector_dir : float3;
                                 var out_angle : float&; var out_dist : float&)
  var targetDir = target_pos - camera_pos
  out_dist = length(targetDir)
  targetDir *= safeinv(out_dist)
  let forestallDir = normalize(forestall_pos - camera_pos)

  let curAngleToForestall = safe_acos(dot(forestallDir, selector_dir))
  let curAngleToUnit = safe_acos(dot(targetDir, selector_dir))
  out_angle = min(curAngleToForestall, curAngleToUnit)

[es(tag=gameClient, REQUIRE=heroVehicle, no_order)]
def plane_target_forestall(info : UpdateStageInfoAct;
                           eid : EntityId;
                           transform : float3x4;
                           turret_control__gunEids : EidList;
                           turretAimPos : float3;
                           plane_net_phys : PlaneActor?;
                           plane_input__mouseAimEnabled : bool = false;
                           forestallMaxDist : float;
                           forestallCutoffAngle : float;
                           forestallDt : float = 0.02f;
                           forestallIterMax : int = 5;
                           forestallMaxTime : float = 60.0;
                           var forestallOpacity : float&;
                           var forestallPos : float3&;
                           var target_lock__selectedEntity : EntityId&)
  forestallOpacity = 0.0
  let heroPlaneEid = eid
  var heroTeam = TEAM_UNASSIGNED
  var maxDist = forestallMaxDist
  var gForceBlackout = 0.
  let hero = get_controlled_hero()
  query(hero) <| $ [es] (team : int = TEAM_UNASSIGNED;
                         entity_mods__aircraftDetectAndIdentifyRangeMult : float = 1.0;
                         g_force__forestallThreshold : float = 0.3;
                         g_force__visual : float = 0.)
    heroTeam = team
    maxDist *= entity_mods__aircraftDetectAndIdentifyRangeMult
    gForceBlackout = cvt(abs(g_force__visual), 0., g_force__forestallThreshold, 0., 1.)

  target_lock__selectedEntity = INVALID_ENTITY_ID

  let firstTurretShellProps = get_first_turret_shell_props(turret_control__gunEids)
  if firstTurretShellProps.ballisticsId >= 0
    projectile_get_props(firstTurretShellProps.ballisticsId) <| $(ballisticsProps : ProjectileProps)
      shell_start_get_props(firstTurretShellProps.shellId) <| $(shellStartProps : ShellStartProps)

        let muzzleVelocity = shellStartProps.speed

        let shooterPos = plane_net_phys != null ? float3((*plane_net_phys).phys.visualLocation.P) : transform[3]
        let shooterVel = plane_net_phys != null ? float3((*plane_net_phys).phys.vel) : float3(0.0)

        let camItm = get_TMatrix(get_cur_cam_entity(), "transform")
        if camItm == null
          return
        let cameraPos = (*camItm)[3]

        let forestallSelectorDir = plane_input__mouseAimEnabled ? normalize(turretAimPos - cameraPos) : (*camItm)[2]
        var minForestallAngle = forestallCutoffAngle

        query() <| $ [es(REQUIRE=airplane)] (eid : EntityId;
                                             transform : float3x4;
                                             isAlive : bool;
                                             team : int;
                                             damage_model : DamageModel;
                                             plane_net_phys : PlaneActor)
          if !isAlive || eid == heroPlaneEid || team == TEAM_UNASSIGNED || is_teams_friendly(heroTeam, team)
            return

          let precisionSq = square(2.0 * damage_model.collisionData.boundingSphere.r)

          let targetPos = float3(plane_net_phys.phys.visualLocation.P)
          let targetVel = float3(plane_net_phys.phys.vel)
          let targetAcc = float3(plane_net_phys.phys.accel)

          let forestallParams = [[ForestallParam dt=forestallDt, iterMax=forestallIterMax, maxTime=forestallMaxTime]]
          let forestall = get_forestall_pos(shooterPos, shooterVel, ballisticsProps, muzzleVelocity, targetPos, targetVel, targetAcc, forestallParams, precisionSq)
          if !forestall.valid
            return
          let pos = forestall.pos

          var angleToTarget, distToTarget : float
          get_angle_and_dist_to_target(transform[3], pos, cameraPos, forestallSelectorDir, angleToTarget, distToTarget)
          if angleToTarget >= 0.0 && angleToTarget <= minForestallAngle && distToTarget <= maxDist
            minForestallAngle = angleToTarget
            target_lock__selectedEntity = eid
            forestallOpacity = min(1.0 - safediv(angleToTarget, forestallCutoffAngle), 1.0 - gForceBlackout)
            forestallPos = pos