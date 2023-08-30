require ecs
require app
require DagorDataBlock
require enlisted.game.es.enlisted_squad_common
require enlisted.game.es.bomb_site_common
require game.es.vehicle.vehicle_seats_common
require BehNodes
require DngBehTree
require CollRes
require DagorMath
require math.base

struct TrainData
  navPointId : int      = -1
  cartEid    : EntityId = INVALID_ENTITY_ID
  enterPoint : float3   = float3()
  navPoint   : float3   = float3()

[es(tag=server, no_order, REQUIRE=aiTrainBehaviour)]
def update_agent_on_train(act : UpdateStageInfoAct)
  query() <| $ [es] (transform aka agent_transform : float3x4;
                     var beh_tree__isAgentOnTrain : bool&)
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

def try_to_get_train_data(minDstSqForGetOnTrain : float;
                          agentPos : float3;
                          agentTeam : int;
                          var trainData : TrainData&)
  var minDstSq   = FLT_MAX
  var minDstPt   = float3()
  var minCartEid = INVALID_ENTITY_ID

  query() <| $ [es(REQUIRE=train)] (eid : EntityId;
                                    ai_train__enter_points : Point3List;
                                    ai_train__held_nav_points : Array;
                                    transform aka cart_transform : float3x4)
    assume agentTeamHeldNavPoints = *(get_ecs_BoolList(ai_train__held_nav_points[agentTeam - 1]))
    for place in agentTeamHeldNavPoints
      if place
        continue

      for i in iter_range(ai_train__enter_points)
        let pos = cart_transform * ai_train__enter_points[i]
        let toAgentDstSq = length_sq(agentPos - pos)
        if toAgentDstSq <= minDstSqForGetOnTrain && toAgentDstSq <= minDstSq
          minDstPt = ai_train__enter_points[i]
          minDstSq = toAgentDstSq
          minCartEid = eid

      return

  query(minCartEid) <| $ [es] (ai_train__nav_points : Point3List;
                               ai_train__held_nav_points : Array;
                               transform aka cart_transform : float3x4)
    assume agentTeamHeldNavPoints = *(get_ecs_BoolList(ai_train__held_nav_points[agentTeam - 1]))
    for i in iter_range(ai_train__nav_points)
      let pos = cart_transform * ai_train__nav_points[i]
      if !agentTeamHeldNavPoints[i] && length_sq(agentPos - pos) <= minDstSqForGetOnTrain
        trainData.navPointId = i
        trainData.navPoint   = ai_train__nav_points[i]
        trainData.cartEid    = minCartEid
        trainData.enterPoint = minDstPt

        return

def apply_train_behaviour(agentEid : EntityId)
  query(agentEid) <| $ [es] (team : int;
                             beh_tree__isAgentOnTrain : bool;
                             transform : float3x4;
                             beh_tree__data__orderReq : string;
                             beh_tree__data__runToTrain : string;
                             beh_tree__data__useTrain : string;
                             beh_tree__minDstForGetOnTrain : float;
                             var beh_tree : BehaviourTree&;
                             var beh_tree__refs__behaviour : das_string&;
                             var beh_tree__refs__orderType : das_string&;
                             var beh_tree__isInTrainBeh : bool&;
                             var beh_tree__isAgentShouldRunToTrain : bool&;
                             var beh_tree__isAgentShouldUseTrain : bool&;
                             var beh_tree__isAgentShouldOutTrain : bool&;
                             var beh_tree__latencyLoadBlackBoard : Object?)
    if !beh_tree__isAgentOnTrain && !beh_tree__isAgentShouldRunToTrain
      var trainData : TrainData

      try_to_get_train_data(square(beh_tree__minDstForGetOnTrain), transform[3], team, trainData)

      if trainData.cartEid != INVALID_ENTITY_ID
        query(trainData.cartEid) <| $ [es] (var ai_train__held_nav_points : Array&)
          assume agentTeamHeldNavPoints   = *(getRW_ecs_BoolList(ai_train__held_nav_points[team - 1]))
          agentTeamHeldNavPoints[trainData.navPointId]       = true

        beh_tree__isAgentShouldRunToTrain = true
        beh_tree__isAgentShouldUseTrain   = false
        beh_tree__isAgentShouldOutTrain   = false

        beh_tree__isInTrainBeh = true

        reset_squad_mate_order(agentEid)

        beh_tree__refs__behaviour := beh_tree__data__orderReq
        beh_tree__refs__orderType := beh_tree__data__runToTrain

        DngBehTree::load_beh_tree_from_ecs(agentEid)

        if beh_tree__latencyLoadBlackBoard != null
          *beh_tree__latencyLoadBlackBoard |> set("enterPosition", trainData.enterPoint)
          *beh_tree__latencyLoadBlackBoard |> set("cartEidParam", int(uint(trainData.cartEid)))
          *beh_tree__latencyLoadBlackBoard |> set("navPosition", trainData.navPoint)
          *beh_tree__latencyLoadBlackBoard |> set("navPtIdParam", trainData.navPointId)
        beh_tree.blackBoard |> set("enterPosition", trainData.enterPoint)
        beh_tree.blackBoard |> set("cartEidParam", int(uint(trainData.cartEid)))
        beh_tree.blackBoard |> set("navPosition", trainData.navPoint)
        beh_tree.blackBoard |> set("navPtIdParam", trainData.navPointId)

    if beh_tree__isAgentOnTrain && !beh_tree__isAgentShouldUseTrain && beh_tree__isAgentShouldRunToTrain
      reset_squad_mate_order(agentEid)

      beh_tree__isAgentShouldRunToTrain = false
      beh_tree__isAgentShouldUseTrain   = true
      beh_tree__isAgentShouldOutTrain   = false

      beh_tree__isInTrainBeh = true

      var trainData : TrainData

      trainData.enterPoint = beh_tree.blackBoard |> datablock_getPoint3("enterPosition", float3())
      trainData.cartEid    = EntityId(uint(beh_tree.blackBoard |> datablock_getInt("cartEidParam", 0)))

      trainData.navPoint   = beh_tree.blackBoard |> datablock_getPoint3("navPosition", float3())
      trainData.navPointId = beh_tree.blackBoard |> datablock_getInt("navPtIdParam", 0)

      beh_tree__refs__behaviour := beh_tree__data__useTrain

      DngBehTree::load_beh_tree_from_ecs(agentEid)

      if beh_tree__latencyLoadBlackBoard != null
        *beh_tree__latencyLoadBlackBoard |> set("enterPosition", trainData.enterPoint)
        *beh_tree__latencyLoadBlackBoard |> set("cartEidParam", int(uint(trainData.cartEid)))
        *beh_tree__latencyLoadBlackBoard |> set("navPosition", trainData.navPoint)
        *beh_tree__latencyLoadBlackBoard |> set("navPtIdParam", trainData.navPointId)
      beh_tree.blackBoard |> set("enterPosition", trainData.enterPoint)
      beh_tree.blackBoard |> set("cartEidParam", int(uint(trainData.cartEid)))
      beh_tree.blackBoard |> set("navPosition", trainData.navPoint)
      beh_tree.blackBoard |> set("navPtIdParam", trainData.navPointId)

    if beh_tree__isAgentOnTrain && !beh_tree__isAgentShouldUseTrain && !beh_tree__isAgentShouldRunToTrain
      apply_train_out_behaviour(agentEid)

def apply_train_out_behaviour(agentEid : EntityId)
  query(agentEid) <| $ [es] (beh_tree__isAgentOnTrain : bool;
                             beh_tree__data__outTrain : string;
                             var beh_tree : BehaviourTree&;
                             var beh_tree__refs__behaviour : das_string&;
                             var beh_tree__isAgentShouldRunToTrain : bool&;
                             var beh_tree__isAgentShouldUseTrain : bool&;
                             var beh_tree__isAgentShouldOutTrain : bool&;
                             var beh_tree__isInTrainBeh : bool&;
                             var beh_tree__latencyLoadBlackBoard : Object?)
    if (beh_tree__isAgentOnTrain || beh_tree__isAgentShouldUseTrain) && !beh_tree__isAgentShouldOutTrain
      reset_squad_mate_order(agentEid)

      beh_tree__isAgentShouldRunToTrain = false
      beh_tree__isAgentShouldUseTrain   = false
      beh_tree__isAgentShouldOutTrain   = true

      beh_tree__isInTrainBeh = true

      var trainData : TrainData

      trainData.enterPoint = beh_tree.blackBoard |> datablock_getPoint3("enterPosition", float3())
      trainData.cartEid    = EntityId(uint(beh_tree.blackBoard |> datablock_getInt("cartEidParam", 0)))

      trainData.navPoint   = beh_tree.blackBoard |> datablock_getPoint3("navPosition", float3())
      trainData.navPointId = beh_tree.blackBoard |> datablock_getInt("navPtIdParam", -1)

      beh_tree__refs__behaviour := beh_tree__data__outTrain

      DngBehTree::load_beh_tree_from_ecs(agentEid)

      if beh_tree__latencyLoadBlackBoard != null
        *beh_tree__latencyLoadBlackBoard |> set("enterPosition", trainData.enterPoint)
        *beh_tree__latencyLoadBlackBoard |> set("cartEidParam", int(uint(trainData.cartEid)))
        *beh_tree__latencyLoadBlackBoard |> set("navPosition", trainData.navPoint)
        *beh_tree__latencyLoadBlackBoard |> set("navPtIdParam", trainData.navPointId)
      beh_tree.blackBoard |> set("enterPosition", trainData.enterPoint)
      beh_tree.blackBoard |> set("cartEidParam", int(uint(trainData.cartEid)))
      beh_tree.blackBoard |> set("navPosition", trainData.navPoint)
      beh_tree.blackBoard |> set("navPtIdParam", trainData.navPointId)

[es(tag=server, no_order, REQUIRE=aiTrainBehaviour)]
def on_squad_leader_use_train(act : UpdateStageInfoAct)
  query() <| $ [es] (squad__leader : EntityId;
                     squad__ownerPlayer : EntityId;
                     squad__allMembers : EidList)
    if has(squad__ownerPlayer, "botAiEnabler")
      apply_train_behaviour(squad__leader)

    query(squad__leader) <| $ [es] (beh_tree__isAgentOnTrain : bool)
      if !beh_tree__isAgentOnTrain
        return

      for squadMember in squad__allMembers
        if squadMember == squad__leader
          continue

        apply_train_behaviour(squadMember)

    query(squad__leader) <| $ [es] (beh_tree__isAgentOnTrain : bool)
      if beh_tree__isAgentOnTrain
        return

      for squadMember in squad__allMembers
        if squadMember == squad__leader
          continue

        apply_train_out_behaviour(squadMember)

def reset_nav_points(beh_tree : BehaviourTree;
                     team : int)
  let cartEid  = EntityId(uint(beh_tree.blackBoard |> datablock_getInt("cartEidParam", -1)))
  query(cartEid) <| $ [es] (var ai_train__held_nav_points : Array&)
    let navPtId = beh_tree.blackBoard |> datablock_getInt("navPtIdParam", -1)
    if navPtId != -1
      assume agentTeamHeldNavPoints = *(getRW_ecs_BoolList(ai_train__held_nav_points[team - 1]))
      agentTeamHeldNavPoints[navPtId] = false

  query(cartEid) <| $ [es] (var ai_train__held_roof_nav_points : BoolList&)
    let navPtRoofId = beh_tree.blackBoard |> datablock_getInt("navPtRoofIdParam", -1)
    if navPtRoofId != -1
      ai_train__held_roof_nav_points[navPtRoofId] = false

[es(tag=server, track=beh_tree__isAgentOnTrain)]
def on_squad_leader_out_train(evt : Event;
                              eid : EntityId;
                              team : int;
                              beh_tree__isAgentOnTrain : bool;
                              beh_tree : BehaviourTree;
                              var beh_tree__isAgentShouldRunToTrain : bool&;
                              var beh_tree__isAgentShouldUseTrain : bool&;
                              var beh_tree__isAgentShouldOutTrain : bool&;
                              var beh_tree__isInTrainBeh : bool&)
  if !beh_tree__isAgentOnTrain && (beh_tree__isAgentShouldOutTrain || beh_tree__isAgentShouldUseTrain)
    beh_tree__isAgentShouldRunToTrain = false
    beh_tree__isAgentShouldUseTrain   = false
    beh_tree__isAgentShouldOutTrain   = false
    beh_tree__isInTrainBeh            = false

    reset_nav_points(beh_tree, team)

    reset_squad_mate_behaviour(eid, true)

[es(tag=server, track=possessedByPlr, REQUIRE=possessedByPlr)]
def on_agent_train_possesed(evt : Event;
                            team : int;
                            var beh_tree : BehaviourTree&;
                            var beh_tree__isAgentShouldRunToTrain : bool&;
                            var beh_tree__isAgentShouldUseTrain : bool&;
                            var beh_tree__isAgentShouldOutTrain : bool&;
                            var beh_tree__isInTrainBeh : bool&)
  if beh_tree__isInTrainBeh
    reset_nav_points(beh_tree, team)

    beh_tree__isAgentShouldRunToTrain = false
    beh_tree__isAgentShouldUseTrain   = false
    beh_tree__isAgentShouldOutTrain   = false
    beh_tree__isInTrainBeh            = false

    beh_tree.blackBoard |> set("enterPosition", float3())
    beh_tree.blackBoard |> set("cartEidParam", -1)

    beh_tree.blackBoard |> set("navPosition", float3())
    beh_tree.blackBoard |> set("navPtIdParam", -1)

[es(tag=server, on_event=EventEntityDied, REQUIRE=human)]
def reset_nav_points_on_agent_died(evt : Event;
                                   team : int;
                                   var beh_tree : BehaviourTree&;
                                   var beh_tree__isAgentShouldRunToTrain : bool&;
                                   var beh_tree__isAgentShouldUseTrain : bool&;
                                   var beh_tree__isAgentShouldOutTrain : bool&;
                                   var beh_tree__isInTrainBeh : bool&)
  if beh_tree__isInTrainBeh
    reset_nav_points(beh_tree, team)

    beh_tree__isAgentShouldRunToTrain = false
    beh_tree__isAgentShouldUseTrain   = false
    beh_tree__isAgentShouldOutTrain   = false
    beh_tree__isInTrainBeh            = false

    beh_tree.blackBoard |> set("enterPosition", float3())
    beh_tree.blackBoard |> set("cartEidParam", -1)

    beh_tree.blackBoard |> set("navPosition", float3())
    beh_tree.blackBoard |> set("navPtIdParam", -1)

[es(tag=server, on_appear, before=load_beh_tree_es)]
def set_agent_train_behavior(evt : Event;
                             beh_tree__data__passiveStayReactionTrain : string;
                             beh_tree__data__passiveMoveReactionTrain : string;
                             beh_tree__data__aggressiveStayReactionTrain : string;
                             beh_tree__data__aggressiveMoveReactionTrain : string;
                             beh_tree__data__updateRegroupPosTrain : string;
                             var beh_tree__refs__passiveStayReaction : das_string&;
                             var beh_tree__refs__passiveMoveReaction : das_string&;
                             var beh_tree__refs__aggressiveStayReaction : das_string&;
                             var beh_tree__refs__aggressiveMoveReaction : das_string&;
                             var beh_tree__refs__updateRegroupPos : das_string&)
  query() <| $ [es(REQUIRE=aiTrainBehaviour)] ()
    beh_tree__refs__passiveStayReaction := beh_tree__data__passiveStayReactionTrain
    beh_tree__refs__passiveMoveReaction := beh_tree__data__passiveMoveReactionTrain
    beh_tree__refs__aggressiveStayReaction := beh_tree__data__aggressiveStayReactionTrain
    beh_tree__refs__aggressiveMoveReaction := beh_tree__data__aggressiveMoveReactionTrain
    beh_tree__refs__updateRegroupPos := beh_tree__data__updateRegroupPosTrain

[es(on_event=EventLevelLoaded)]
def create_ai_train_beh_on_level_loaded(evt : Event)
  find_query() <| $ [es] (walker_agent__aiTrainBehaviourEntity : string)
    createEntity(walker_agent__aiTrainBehaviourEntity)
    return true
