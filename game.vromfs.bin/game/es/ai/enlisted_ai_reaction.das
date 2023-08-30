options no_global_variables = false
require ecs
require app
require math.base
require walkerai
require DngWalkerai
require BehNodes
require game.es.events
require game.es.ai.walker_common
require game.utils.team
require Dacoll
require DagorDataBlock
require DagorRandom
require DagorDataBlock
require DngDm
require DagorMath
require common_shooter.events_common_shooter
require CollRes

var // these variables keep constant values that don't change at runtime (after set), variables for non constant values are prohibited
  ENEMY_PLAYER_NEAR_REACTION_ID : int
  BOMB_CAN_BE_PLANTED_REACTION_ID : int
  BOMB_CAN_BE_DEFUSED_REACTION_ID : int
  AGENT_TRAIN_ZONE_ENTER_REACTION_ID : int
  AGENT_TRAIN_ZONE_LEAVE_REACTION_ID : int
  AGENT_ON_TRAIN_ENTER_REACTION_ID : int
  AGENT_ON_TRAIN_LEAVE_REACTION_ID : int
  AGENT_POSSESED_REACTION_ID : int
  AGENT_UNPOSSESED_REACTION_ID : int
  SQUAD_MEMBER_IN_TROUBLE_ID : int
  SQUAD_BEHAVIOUR_CHANGED_REACTION_ID : int

[register_beh_nodes]
def register_nodes()
  ENEMY_PLAYER_NEAR_REACTION_ID = walkerai::register_reaction("onEnemyPlayerNear")
  BOMB_CAN_BE_PLANTED_REACTION_ID = walkerai::register_reaction("onBombCanBePlanted")
  BOMB_CAN_BE_DEFUSED_REACTION_ID = walkerai::register_reaction("onBombCanBeDefused")
  AGENT_TRAIN_ZONE_ENTER_REACTION_ID = walkerai::register_reaction("onAgentTrainZoneEnter")
  AGENT_TRAIN_ZONE_LEAVE_REACTION_ID = walkerai::register_reaction("onAgentTrainZoneLeave")
  AGENT_ON_TRAIN_ENTER_REACTION_ID = walkerai::register_reaction("onAgentTrainEnter")
  AGENT_ON_TRAIN_LEAVE_REACTION_ID = walkerai::register_reaction("onAgentTrainLeave")
  AGENT_POSSESED_REACTION_ID = walkerai::register_reaction("onAgentPossesed")
  AGENT_UNPOSSESED_REACTION_ID = walkerai::register_reaction("onAgentUnpossesed")
  SQUAD_MEMBER_IN_TROUBLE_ID = walkerai::register_reaction("onSquadMateTrouble")
  SQUAD_BEHAVIOUR_CHANGED_REACTION_ID = walkerai::register_reaction("onSquadBehaviourChanged")

def has_traceable_danger(dangers; threshold : float)
  for danger in dangers
    if danger.traceable && danger.dangerMeter >= threshold
      return true
  return false


[es(tag=server, REQUIRE_NOT=deadEntity, no_order)]
def update_enemy_player_in_radius_reaction(act : UpdateStageInfoAct; agent_dangers : AgentDangers; var beh_tree : BehaviourTree;
                                           beh_tree__enemyPlayerInRadiusDist : float;
                                           var beh_tree__enemyPlayerInRadiusAt : float&;
                                           beh_tree__enemyPlayerInRadiusPeriod : float;
                                           beh_tree__enabled : bool = true)
  if !beh_tree__enabled || length(agent_dangers.dangers) == 0 || act.curTime < beh_tree__enemyPlayerInRadiusAt
    return

  beh_tree__enemyPlayerInRadiusAt = act.curTime + beh_tree__enemyPlayerInRadiusPeriod

  for danger in agent_dangers.dangers
    if danger.traceable && danger.distance < beh_tree__enemyPlayerInRadiusDist
      beh_tree |> beh_tree_react(ENEMY_PLAYER_NEAR_REACTION_ID, 0f)
      return


[es(tag=server, REQUIRE=human, track=(isAlive, isDowned))]
def on_squad_member_downed_or_dead(evt : Event;
                                   eid : EntityId;
                                   beh_tree__enabled : bool;
                                   isAlive : bool;
                                   isDowned : bool;
                                   isInVehicle : bool;
                                   squad_member__squad : EntityId;
                                   transform aka victim_transform : float3x4)
  if !beh_tree__enabled || isInVehicle
    return
  if isAlive && !isDowned
    return

  if rnd_float(0.0, 1.0) < 0.5
    return

  var memberEid = INVALID_ENTITY_ID
  var memberDistSq = -1.0
  query(squad_member__squad) <| $ [es] (squad__allMembers : EidList;
                                        squad__leader : EntityId)
    for squadMemberEid in squad__allMembers
      if squadMemberEid == eid || squadMemberEid == squad__leader
        continue
      query(squadMemberEid) <| $ [es] (beh_tree__enabled : bool;
                                       isAlive : bool;
                                       isDowned : bool;
                                       isInVehicle : bool;
                                       walker_agent__serverAiAction : int;
                                       walker_agent__serverAiActionTime : float;
                                       squad_member__isPersonalOrder : bool;
                                       transform : float3x4)
        if !beh_tree__enabled || !isAlive || isDowned || isInVehicle
          return
        if squad_member__isPersonalOrder
          return
        let stayWaitTime = 3.0
        if !(walker_agent__serverAiAction == int(AiAction AI_ACTION_IN_COVER) &&
             get_sync_time() < walker_agent__serverAiActionTime + stayWaitTime)
          let moveWaitTime = 2.0
          if !(walker_agent__serverAiAction == int(AiAction AI_ACTION_MOVE) &&
              get_sync_time() - walker_agent__serverAiActionTime < moveWaitTime)
            return
        let distSq = distance_sq(transform[3], victim_transform[3])
        if memberDistSq < 0.0 || distSq < memberDistSq
          memberEid = squadMemberEid
          memberDistSq = distSq

  if memberEid == INVALID_ENTITY_ID
    return

  var attractEid = eid
  var attractPos = victim_transform[3]
  query(attractEid) <| $ [es] (beh_tree : BehaviourTree;
                               transform aka attract_transform : float3x4 const?)
    if attract_transform != null
      attractPos = (*attract_transform)[3]
    let enemyEid = EntityId(uint(beh_tree.blackBoard |> datablock_getInt("rememberEnemy", 0)))
    if enemyEid != INVALID_ENTITY_ID && doesEntityExist(enemyEid) && rnd_float(0.0, 1.0) > 0.5
      attractEid = enemyEid
      query(attractEid) <| $ [es] (transform aka attract_transform : float3x4)
        attractPos = attract_transform[3]

  query(memberEid) <| $ [es] (var beh_tree : BehaviourTree)
    beh_tree.blackBoard |> set("rememberEnemy", int(uint(attractEid)))
    beh_tree.blackBoard |> set("rememberEnemyPos", attractPos)
    beh_tree.blackBoard |> set("rememberEnemyTime", get_sync_time())

    beh_tree.blackBoard |> set("forceMove", 1)
    beh_tree.blackBoard |> set("forceMovePos", attractPos)

    beh_tree |> beh_tree_react(SQUAD_MEMBER_IN_TROUBLE_ID, 0f)
