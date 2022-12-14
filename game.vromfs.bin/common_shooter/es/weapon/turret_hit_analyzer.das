require ecs
require app
require dm
require debug.logerr_once
require game.utils.team
require game.utils.hero
require game.es.events
require EnlistedWeapon
require EnlistedDm
require DagorSystem
require DagorMath
require DaWeaponProps
require Dacoll
require Ballistics
require BallisticsProps
require BallisticsDm
require PhysMat
require GridCollision
require CollisionTraces
require GamePhys
require enlisted.events_enlisted
require SmokeOccluder


enum SimulateMode
  FULL
  FIND_HIT_POS_ONLY


def trace_shootable_objects(from, dir : float3; len : float; ignore_human, ignore_vehicle : EntityId; cb : block<(intersections : IntersectedEntities#) : void>)
  using() <| $(var intersections : IntersectedEntities#)
    var t1 = len; var t2 = len; var t3 = len
    trace_entities_in_grid(ecs_hash("humans"), from, dir, t1, ignore_human, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), from, dir, t2, ignore_vehicle, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("interactable"), from, dir, t3, INVALID_ENTITY_ID, intersections, SortIntersections YES)
    invoke(cb, intersections)


def simulate_shot(owner_eid : EntityId;
                  shell_prop_ids : ShellPropIds;
                  shoot_tm : float3x4;
                  mode : SimulateMode;
                  var out_hit_pos : float3&;
                  var out_hit_result : int&)
  out_hit_pos = float3()

  var hitResult = -1
  var quit = false

  projectile_get_props(int(shell_prop_ids.shellId)) <| $(projectileProps : ProjectileProps)
    shell_start_get_props(int(shell_prop_ids.shellId)) <| $(shellStartProps : ShellStartProps)
      using() <| $(var ballistics : ProjectileBallistics#)
        let shootPos = shoot_tm[3]
        let shootDir = shoot_tm[0]

        let smokeTraceEnd = shootPos + shootDir * projectileProps.maxDistance
        let isBlockedBySmoke = rayhit_smoke_occluders(shootPos, smokeTraceEnd)

        let inVel = shootDir * shellStartProps.speed
        let density = atmosphere_density(shootPos.y)
        ballistics |> projectile_ballistics_setupWithKV(projectileProps, shootPos, inVel, 1.0f, density)

        var distance = 0.0

        let dt = 1.0 / 24.0
        var atTime = 0.0
        while distance <= projectileProps.maxDistance
          let prevPos = ballistics.state.pos

          ballistics |> projectile_ballistics_move(ballistics.state.atTick + 1, dt)

          let curPos = ballistics.state.pos
          let toCurPos = curPos - prevPos
          var len = length(toCurPos)
          let dir = toCurPos * safeinv(len)

          distance += len

          var pmid = 0
          var norm = float3()
          using() <| $(var desc : RendInstDesc#)
            var sceneIntersected = traceray_normalized(prevPos, dir, len, pmid, norm, ETF_ALL, desc, -1)
            let curTime = get_sync_time()
            var waterLen = len
            let end = prevPos + dir * waterLen
            if traceray_water_at_time(prevPos, end, curTime, waterLen)
              if !sceneIntersected
                len += 10.0
                using() <| $(var desc2 : RendInstDesc#)
                  traceray_normalized(prevPos, dir, len, pmid, norm, ETF_ALL, desc2, -1)
              pmid = get_material_id("water3d")
              norm = float3(0.0, 1.0, 0.0)
              sceneIntersected = true

            var vehicleEid = INVALID_ENTITY_ID
            var projectileOwnerTeam = TEAM_UNASSIGNED
            query(owner_eid) <| $ [es] (human_anim__vehicleSelected : EntityId; team : int)
              vehicleEid = human_anim__vehicleSelected
              projectileOwnerTeam = team

            trace_shootable_objects(prevPos, dir, len, owner_eid, vehicleEid) <| $(sortedIntersectedList : IntersectedEntities#)
              var entitiesIntersected = false
              if length(sortedIntersectedList) > 0
                for isect in sortedIntersectedList
                  let eid = isect.eid
                  let newHitPos = prevPos + dir * isect.t
                  out_hit_pos = newHitPos

                  let invul = check_shell_invulnerability(eid, distance, dir, newHitPos, curTime)
                  if invul.isInvulnerable
                    sendEvent(isect.eid, [[ProjectileHitInvulnerableNotification hitPos=isect.pos, hitDir=dir]])
                    continue
                  if has(eid, "turretHitAlwaysEffective")
                    hitResult = int(TestResult EFFECTIVE)
                    return
                  if has(eid, "turretHitAlwaysIneffective")
                    hitResult = int(TestResult INEFFECTIVE)
                    return

                  var damageModel : DamageModel const?
                  var restrictToTeam = TEAM_UNASSIGNED
                  var team = TEAM_UNASSIGNED
                  var isExploded = false
                  query(eid) <| $ [es] (damage_model : DamageModel const?;
                                        vehicle_seats__restrictToTeam : int = TEAM_UNASSIGNED;
                                        team aka entity_team : int = TEAM_UNASSIGNED;
                                        isExploded aka entity_isExploded : bool = false)
                    damageModel = damage_model
                    restrictToTeam = vehicle_seats__restrictToTeam
                    team = entity_team
                    isExploded = entity_isExploded
                  let isTeamsFriendly = is_teams_friendly(projectileOwnerTeam, team)
                  let isTeamFireAllowed = (!isTeamsFriendly || is_friendly_fire_allowed())
                  let isCorrectRestrictToTeam = (restrictToTeam == TEAM_UNASSIGNED || restrictToTeam != projectileOwnerTeam)
                  if (damageModel != null && !isExploded && isTeamFireAllowed &&
                      isCorrectRestrictToTeam && !invul.haveDeflectedShell && !isBlockedBySmoke)
                    if mode == SimulateMode FULL
                      let t = damageModel.collisionData.boundingSphere.r
                      let velDir = normalize(ballistics.state.vel)

                      using() <| $(var criticalDamageTesterState : CriticalDamageTesterState#)
                        criticalDamageTesterState.damagePropsId = int(shell_prop_ids.damageId)
                        criticalDamageTesterState.ballisticsPropsId = int(shell_prop_ids.ballisticsId)
                        criticalDamageTesterState.projectileTypePropsId = -1
                        set_critical_damage_tester_state_ballistics_props(criticalDamageTesterState, projectileProps)
                        criticalDamageTesterState.mass = projectileProps.mass
                        criticalDamageTesterState.speed = length(ballistics.state.vel)
                        criticalDamageTesterState.distance = distance
                        criticalDamageTesterState.ray = Ray3(newHitPos - velDir * t, velDir, t * 4.0)
                        criticalDamageTesterState.testSecondaryShatters = false;
                        criticalDamageTesterState.testExplosion = false;
                        criticalDamageTesterState.volumetricShell = false;

                        critical_damage_test(
                          ObjectDescriptor(int(ObjectDescriptorType TYPE_COLLISION), int(uint(eid))),
                          get_damage_model_params(), /*combine_expl_damage*/ false, criticalDamageTesterState)

                        hitResult = int(criticalDamageTesterState.result)
                    quit = true
                    return
                  entitiesIntersected = true
                  hitResult = int(TestResult INEFFECTIVE)
                  return
              if hitResult != -1 || quit
                return
              if sceneIntersected && !entitiesIntersected
                out_hit_pos = prevPos + dir * waterLen
                hitResult = int(TestResult INEFFECTIVE)
                return
          if hitResult != -1 || quit
            break
          atTime += dt

        if quit && hitResult == -1
          return

        if hitResult != -1
          out_hit_result = hitResult
        else
          out_hit_pos = ballistics.state.pos
          out_hit_result = int(TestResult INEFFECTIVE)


[es(tag=gameClient, after=(turret_weap_updater_es, turret_update_visual_shoot_tm_es))]
def turret_hit_analyzer_es(info : ParallelUpdateFrameDelayed;
                           turret_control__gunEids : EidList;
                           turret_current_visual_shoot_tm : float3x4;
                           turretCheckHitInterval : float;
                           isAlive : bool;
                           isExploded : bool;
                           isSimpleTurretCrosshair : bool = false;
                           var turretCheckHitAtTime : float&;
                           var turretHitPosThreadCalc : float3&;
                           var turretCheckHitResultThreadCalc : int&)
  if isAlive && !isExploded && !isSimpleTurretCrosshair
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstTurretInput, gun))] (turret_aim__shootDirWithCorrection : float3;
                                                                                gun__curShellId : ShellPropIds)
        if int(gun__curShellId.shellId) < 0
          return

        let curTime = get_sync_time()
        let mode = turretCheckHitAtTime > curTime ? SimulateMode FIND_HIT_POS_ONLY : SimulateMode FULL
        if mode == SimulateMode FULL
          turretCheckHitAtTime = curTime + turretCheckHitInterval

        var shootTm = turret_current_visual_shoot_tm
        shootTm[0] = turret_aim__shootDirWithCorrection

        simulate_shot(get_controlled_hero(), gun__curShellId,
                      shootTm, mode, turretHitPosThreadCalc, turretCheckHitResultThreadCalc)

[es(tag=gameClient, no_order, REQUIRE=vehicleWithWatched)]
def turret_hit_analyzer_applyer_es(info : UpdateStageInfoAct;
                                   turretCheckHitResultThreadCalc : int;
                                   turretHitPosThreadCalc : float3;
                                   var turretHitPos : float3&;
                                   var turretCheckHitResult : int&)
  turretCheckHitResult = turretCheckHitResultThreadCalc
  turretHitPos = turretHitPosThreadCalc

[es(tag=gameClient, no_order, REQUIRE=hero)]
def gun_hit_analyzer_applyer_es(info : UpdateStageInfoAct;
                                gunCheckHitResultThreadCalc : int;
                                var gunCheckHitResult : int&)
  gunCheckHitResult = gunCheckHitResultThreadCalc;

[es(tag=gameClient, after=after_guns_update_sync)]
def gun_hit_analyzer_es(info : ParallelUpdateFrameDelayed;
                        gun__owner : EntityId;
                        gun__curShellId : ShellPropIds;
                        gunCheckHitInterval : float;
                        var gunCheckHitAtTime : float&;
                        var gunCheckHitResultThreadCalc : int&)
  let hero = get_controlled_hero()
  if gun__owner != hero
    return

  if int(gun__curShellId.shellId) >= 0
    query(hero) <| $ [es] (human__aimTm : float3x4)
      let curTime = get_sync_time()
      let mode = gunCheckHitAtTime > curTime ? SimulateMode FIND_HIT_POS_ONLY : SimulateMode FULL
      if mode == SimulateMode FULL
        gunCheckHitAtTime = curTime + gunCheckHitInterval

      var gunHitPos = float3()
      simulate_shot(hero, gun__curShellId, human__aimTm, mode, gunHitPos, gunCheckHitResultThreadCalc)
