require ecs
require app
require walkerai
require game.es.ai.walker_common
require common_shooter.events_common_shooter
require pathfinder
require game.utils.team
require EnlistedWalkerai
require EnlistedHuman
require EnlistedWeapon
require DagorMath
require DagorSystem
require DaWeapons
require HumanPhys
require BehNodes


def interp_dir(prev : float3;
               cur : float3;
               interpK : float)
  return slerp(dir_to_quat(prev), dir_to_quat(cur), interpK) |> quat_get_forward()


def update_entity_agent(var ent : EntityAgent;
                        phys : HumanPhys;
                        cur_time : float;
                        tm : float3x4;
                        is_alive : bool;
                        reload_progress : float)
  ent.pos = tm[3]
  ent.isAlive = is_alive

  let interpK = get_phys_interpk_clamped(phys, cur_time)
  ent.reloading = reload_progress > 0.0
  ent.shootDir = interp_dir(phys.previousState.gunDir, phys.currentState.gunDir, interpK)
  let gunEid = get_human_gun_eid(ent.eid)
  ent.shootRayMat = get_int(gunEid, "gun__aimRayMatId") ?? -1


[es(on_appear, before=load_beh_tree_es)]
def walker_agent_finish_init_es(evt : Event;
                                var walker_agent : EntityAgent?;
                                var beh_tree : BehaviourTree)
  beh_tree |> beh_tree_set_user_ptr(walker_agent)


[es(after=human_phys_es, before=after_net_phys_sync)]
def walker_agent_es(info : UpdateStageInfoAct;
                    human_net_phys : HumanActor;
                    transform : float3x4;
                    reloadProgress : float;
                    isAlive : bool = true;
                    walker_agent__crawlShootLocalPos : float3 = float3(0.0, 0.3, 0.0);
                    walker_agent__crouchShootLocalPos : float3 = float3(0.0, 0.6, 0.0);
                    walker_agent__standShootLocalPos : float3 = float3(0.0, 1.4, 0.0);
                    beh_tree__enabled : bool;
                    team : int = TEAM_UNASSIGNED;
                    var walker_agent : EntityAgent;
                    var agent_dangers__standShootPos : float3&;
                    var agent_dangers__standShootDir : float3&)
  if !beh_tree__enabled
    return

  assume phys = human_net_phys.phys
  update_entity_agent(walker_agent, phys, info.curTime, transform, isAlive, reloadProgress)
  walker_agent.shootFrom[STANCE_CRAWL] = transform * walker_agent__crawlShootLocalPos
  if phys.precompWeaponPos != null && phys.precompWeaponPos.isLoaded
    assume curState = phys.currentState
    let crouchPos = phys |> human_phys_calcGunPos(PrecomputedPresetMode TPV, transform,
                                                  curState.gunAngles.y, curState.leanPosition, /*ht*/0.0)
    walker_agent.shootFrom[STANCE_CROUCH] = crouchPos
    let standPos = phys |> human_phys_calcGunPos(PrecomputedPresetMode TPV, transform,
                                                 curState.gunAngles.y, curState.leanPosition, /*ht*/1.0)
    walker_agent.shootFrom[STANCE_STAND] = standPos
  else
    walker_agent.shootFrom[STANCE_CROUCH] = transform * walker_agent__crouchShootLocalPos
    walker_agent.shootFrom[STANCE_STAND] = transform * walker_agent__standShootLocalPos
  agent_dangers__standShootPos = walker_agent.shootFrom[STANCE_STAND]
  agent_dangers__standShootDir = walker_agent.shootDir
  walker_agent.teamId = team


[es(tag=server, after=after_guns_update_sync, before=clear_gun_launch_events_es)]
def walker_agent_track_shots_es(info : UpdateStageInfoAct;
                                gun__owner : EntityId;
                                gun_launch_events : GunLaunchEvents)
  query(gun__owner) <| $ [es] (beh_tree__enabled : bool;
                               isAlive : bool;
                               var walker_agent : EntityAgent)
    if !beh_tree__enabled || !isAlive
      return

    // Assume that AI shoots only to some target
    if walker_agent.aiming.lastTarget.id >= 0
      walker_agent.aiming.lastTarget.shotsCount += (length(gun_launch_events.launchEvents) == 0) ? 0 : 1


[es]
def walker_agent_es_event_handler(evt : EventOnEntityHit;
                                  beh_tree__enabled : bool;
                                  var walker_agent : EntityAgent)
  if beh_tree__enabled && walker_agent.eid == evt.victim
    walker_agent.lastHitTime = get_sync_time()


[es(tag=(dev, render), after=beh_tree_update_es, REQUIRE=customNavDebug)]
def walker_agent_debug_custom_nav_es(info : UpdateStageInfoRenderDebug)
  query() <| $ [es] (walker_agent : EntityAgent)
    if walker_agent.customNav != null
      *walker_agent.customNav |> drawDebug()
