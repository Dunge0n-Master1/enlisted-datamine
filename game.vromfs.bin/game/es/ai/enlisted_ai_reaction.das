options no_global_variables = false
require ecs
require app
require math.base
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
  ENEMY_PLAYER_NEAR_REACTION_ID : int
  BOMB_CAN_BE_PLANTED_REACTION_ID : int
  BOMB_CAN_BE_DEFUSED_REACTION_ID : int
  AGENT_TRAIN_ZONE_ENTER_REACTION_ID : int
  AGENT_TRAIN_ZONE_LEAVE_REACTION_ID : int
  AGENT_ON_TRAIN_ENTER_REACTION_ID : int
  AGENT_ON_TRAIN_LEAVE_REACTION_ID : int
  AGENT_POSSESED_REACTION_ID : int
  AGENT_UNPOSSESED_REACTION_ID : int
  AGENT_DIED_REACTION_ID : int
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
  AGENT_DIED_REACTION_ID = walkerai::register_reaction("onAgentDied")
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

[es(tag=server, on_event=EventEntityDied, REQUIRE=human)]
def update_agent_died_reaction(evt : Event;
                               var beh_tree : BehaviourTree)
  beh_tree |> beh_tree_react(AGENT_DIED_REACTION_ID, 0f)

