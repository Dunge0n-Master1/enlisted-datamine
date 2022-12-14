options no_global_variables = false
require ecs
require app
require math.base
require math.random
require walkerai
require EnlistedWalkerai
require BehNodes
require game.es.events
require game.es.ai.walker_common
require game.utils.team
require Dacoll
require DagorDataBlock
require EnlistedDm
require DagorMath
require common_shooter.events_common_shooter
require CollRes

var // these variables keep constant values that don't change at runtime (after set), variables for non constant values are prohibited
  ER_REGULAR_CHECK : int
  TRACEABLE_DANGER_REACTION_ID : int
  BLINDNESS_REACTION_ID : int


[register_beh_nodes]
def register_nodes()
  ER_REGULAR_CHECK = register_reaction("regularCheck")
  TRACEABLE_DANGER_REACTION_ID = walkerai::register_reaction("onTraceableDanger")
  BLINDNESS_REACTION_ID = walkerai::register_reaction("onBlindness")


[es(on_appear)]
def beh_tree_reaction_init_es(evt : Event; beh_tree__regularCheckRange : float2; var beh_tree__regularCheckAt : float&)
  beh_tree__regularCheckAt = get_sync_time() + rnd_float(beh_tree__regularCheckRange)


[es(REQUIRE_NOT=deadEntity, before=beh_tree_update_es, after=walker_agent_es)]
def beh_tree_reaction_es(info : UpdateStageInfoAct;
                         beh_tree__enabled : bool;
                         beh_tree__regularCheckRange : float2;
                         var beh_tree__regularCheckAt : float&;
                         var beh_tree : BehaviourTree)
  if !beh_tree__enabled || beh_tree__regularCheckAt >= info.curTime
    return
  beh_tree |> beh_tree_react(ER_REGULAR_CHECK, info.dt)
  beh_tree__regularCheckAt = info.curTime + rnd_float(beh_tree__regularCheckRange)


def has_traceable_danger(dangers; threshold : float)
  for danger in dangers
    if danger.traceable && danger.dangerMeter >= threshold
      return true
  return false


[es(tag=server, no_order)]
def update_traceable_dangers(act : UpdateStageInfoAct; agent_dangers : AgentDangers; var beh_tree : BehaviourTree;
                             var agent_dangers__hasTraceableDangers : bool&; agent_dangers__hasTraceableDangerThreshold = 1f)
  if length(agent_dangers.dangers) == 0
    agent_dangers__hasTraceableDangers = false
    return
  let hasTraceableDangers = has_traceable_danger(agent_dangers.dangers, agent_dangers__hasTraceableDangerThreshold)
  if hasTraceableDangers && hasTraceableDangers != agent_dangers__hasTraceableDangers && TRACEABLE_DANGER_REACTION_ID > -1
    beh_tree |> beh_tree_react(TRACEABLE_DANGER_REACTION_ID, 0f)
  agent_dangers__hasTraceableDangers = hasTraceableDangers

[es(tag=server)]
def flash_exploded(evt : CmdShellExplode; eid : EntityId;
                   disorientated__flashRad = float2(0.f, 0.f);
                   disorientated__flashPower = float2(0.f, 0.f);
                   disorientated__flashDistExp = 1.f
                   //  disorientated__tinnitusRad: float2;
                   //  disorientated__tinnitusPower: float2;
                   //  disorientated__tinnitusDistExp = 1.f
                   )
  if disorientated__flashPower.x <= 0f || BLINDNESS_REACTION_ID < 0
    return
  let explPos = evt.position
  query() <| $ [es] (agent_dangers__standShootPos, agent_dangers__standShootDir : float3; gun__aimRayMatId : int;
                     var beh_tree : BehaviourTree;
                     var agent_dangers__lastBlindnessReactionTime : float?;
                     var agent_dangers__lastBlindnessReactionShellEid : EntityId?)
    let lookDir = agent_dangers__standShootDir
    let lookPos = agent_dangers__standShootPos
    var dirToHead = lookPos - explPos
    let distToHead = length(dirToHead)

    if distToHead > disorientated__flashRad.y
      return

    dirToHead *= safeinv(distToHead)
    let penetration = float2()
    let flashPow = -dot(lookDir, dirToHead) * calc_dist_damage(distToHead, 0f, disorientated__flashDistExp, penetration, disorientated__flashRad, disorientated__flashPower)
    if flashPow <= 0f
      return

    if rayhit_normalized(explPos, dirToHead, distToHead, ETF_DEFAULT, gun__aimRayMatId)
      return

    var blindnessTime = flashPow
    find_query() <| $ [es] (blindness__timeMult : float)
      blindnessTime *= blindness__timeMult
      return true
    beh_tree.blackBoard |> set("blindness.timeEnd", get_sync_time() + blindnessTime)
    if agent_dangers__lastBlindnessReactionShellEid != null && agent_dangers__lastBlindnessReactionTime != null
      *agent_dangers__lastBlindnessReactionTime = get_sync_time()
      *agent_dangers__lastBlindnessReactionShellEid = eid
    beh_tree |> beh_tree_react(BLINDNESS_REACTION_ID, 0f)
