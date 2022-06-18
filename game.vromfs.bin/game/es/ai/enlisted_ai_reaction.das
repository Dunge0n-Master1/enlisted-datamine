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
def register_enlisted_ai_reactions1()
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

[es(tag=server, track=squad__squadBehaviour, REQUIRE=squad__squadBehaviour)]
def update_squad_behaviour_changed_reaction(evt : Event;
                                            eid : EntityId)
  ecs::query() <| $ [es] (var beh_tree : BehaviourTree&; squad_member__squad : EntityId)
    if squad_member__squad == eid
      beh_tree |> beh_tree_react(SQUAD_BEHAVIOUR_CHANGED_REACTION_ID, 0f)

[es(tag=server, no_order)]
def update_agent_on_train(act : UpdateStageInfoAct;
                          beh_tree__agentOnTrainPeriod : float;
                          var beh_tree__agentOnTrainAt : float&;
                          var beh_tree__isAgentOnTrain : bool&;
                          transform aka agent_transform : float3x4)
  if act.curTime < beh_tree__agentOnTrainAt
    return

  beh_tree__agentOnTrainAt = act.curTime + beh_tree__agentOnTrainPeriod

  beh_tree__isAgentOnTrain = false
  query() <| $ [es(REQUIRE=train)] (train_cart__offsetXZ : float;
                                    train_cart__minHeight : float;
                                    train_cart__maxHeight : float;
                                    collres : CollisionResource;
                                    transform : float3x4)
    let localPos = inverse(transform) * agent_transform[3]

    var box = collres.vFullBBox

    box.bmin.y = train_cart__minHeight
    box.bmax.y = train_cart__maxHeight

    box.bmin.x -= train_cart__offsetXZ
    box.bmax.x += train_cart__offsetXZ

    box.bmin.z -= train_cart__offsetXZ
    box.bmax.z += train_cart__offsetXZ

    if !beh_tree__isAgentOnTrain
      beh_tree__isAgentOnTrain = BBox3(box) & localPos

[es(tag=server, track=beh_tree__isAgentOnTrain)]
def update_agent_on_train_reaction(evt : Event;
                                   beh_tree__isAgentOnTrain : bool;
                                   var beh_tree : BehaviourTree)
  if beh_tree__isAgentOnTrain
    beh_tree |> beh_tree_react(AGENT_ON_TRAIN_ENTER_REACTION_ID, 0f)
  else
    beh_tree |> beh_tree_react(AGENT_ON_TRAIN_LEAVE_REACTION_ID, 0f)

[es(tag=server, REQUIRE_NOT=deadEntity, no_order)]
def update_player_train_zone(act : UpdateStageInfoAct;
                             beh_tree__agentInTrainZonePeriod : float;
                             var beh_tree__agentInTrainZoneAt : float&;
                             var beh_tree__isAgentInTrainZone : bool&;
                             transform aka agent_transform : float3x4)
  if act.curTime < beh_tree__agentInTrainZoneAt
    return

  beh_tree__agentInTrainZoneAt = act.curTime + beh_tree__agentInTrainZonePeriod

  query() <| $ [es(REQUIRE=trainZone)] (ai_train_zone__box_min : float3;
                                        ai_train_zone__box_max : float3;
                                        transform : float3x4)
    let localPos = inverse(transform) * agent_transform[3]

    beh_tree__isAgentInTrainZone = BBox3(ai_train_zone__box_min, ai_train_zone__box_max) & localPos

[es(tag=server, track=beh_tree__isAgentInTrainZone)]
def update_player_train_zone_reaction(evt : Event;
                                      beh_tree__isAgentInTrainZone : bool;
                                      var beh_tree : BehaviourTree)
  if beh_tree__isAgentInTrainZone
    beh_tree |> beh_tree_react(AGENT_TRAIN_ZONE_ENTER_REACTION_ID, 0f)
  else
    beh_tree |> beh_tree_react(AGENT_TRAIN_ZONE_LEAVE_REACTION_ID, 0f)

[es(tag=server, track=possessedByPlr)]
def update_possesed_reaction(evt : Event;
                             possessedByPlr : EntityId;
                             var beh_tree : BehaviourTree)
  if possessedByPlr != INVALID_ENTITY_ID
    beh_tree |> beh_tree_react(AGENT_POSSESED_REACTION_ID, 0f)
  else
    beh_tree |> beh_tree_react(AGENT_UNPOSSESED_REACTION_ID, 0f)

[es(tag=server, on_event=EventEntityDied, REQUIRE=human)]
def update_agent_died_reaction(evt : Event;
                               var beh_tree : BehaviourTree)
  beh_tree |> beh_tree_react(AGENT_DIED_REACTION_ID, 0f)

[es(tag=server, REQUIRE_NOT=deadEntity, no_order)]
def update_bomb_interaction_reaction(act : UpdateStageInfoAct;
                                     isDowned : bool;
                                     walker_agent : EntityAgent;
                                     var beh_tree : BehaviourTree;
                                     beh_tree__bombSiteInRadiusDistSqr : float;
                                     var beh_tree__bombSiteInRadiusAt : float&;
                                     beh_tree__bombSiteInRadiusPeriod : float;
                                     beh_tree__enabled : bool = true)
  if isDowned || !beh_tree__enabled || act.curTime < beh_tree__bombSiteInRadiusAt
    return

  beh_tree__bombSiteInRadiusAt = act.curTime + beh_tree__bombSiteInRadiusPeriod

  query() <| $ [es] (active : bool;
                     transform : float3x4;
                     bomb_site__plantingTeam : int;
                     bomb_site__isPlantingOrReseting : bool;
                     bomb_site__isDefusing : bool;
                     bomb_site__isBombPlanted : bool)
    if !active
      return

    if walker_agent.teamId == bomb_site__plantingTeam && !bomb_site__isPlantingOrReseting && !bomb_site__isBombPlanted
      let isNearBombSite = distance_sq(walker_agent.pos, transform[3]) < beh_tree__bombSiteInRadiusDistSqr
      if  isNearBombSite
        beh_tree |> beh_tree_react(BOMB_CAN_BE_PLANTED_REACTION_ID, 0f)
        return
    elif walker_agent.teamId != bomb_site__plantingTeam && bomb_site__isBombPlanted && !bomb_site__isDefusing
      let isNearBombSite = distance_sq(walker_agent.pos, transform[3]) < beh_tree__bombSiteInRadiusDistSqr
      if  isNearBombSite
        beh_tree |> beh_tree_react(BOMB_CAN_BE_DEFUSED_REACTION_ID, 0f)
        return
