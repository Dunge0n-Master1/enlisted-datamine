module enlisted_squad_common shared
require ecs
require DagorRandom
require DngDm
require DngWalkerai
require game.es.ai.walker_common
require DagorDataBlock
require game.es.events
require BehNodes
require game.events_game
require enlisted.game.es.squad_behaviour_command_common
require DngBehTree
require enlisted.game.es.enlisted_covers_common
require game.es.squad_order_common
require DngNet

variant MaybeOrder
  order : SquadMateOrder
  nothing : void?

struct MemberForOrder
  eid : EntityId
  executeOrder : bool

def reset_squad_mate_ai_components(squadMemberEid : EntityId)
  query(squadMemberEid) <| $ [es] (var beh_tree__navPointId : int&;
                                   var beh_tree__capturedCapzone : EntityId&;
                                   var beh_tree__capzoneOfInterest : EntityId&;
                                   var beh_tree__orderIsInVehicle : bool&;
                                   var beh_tree__orderShouldUseVehicle : bool&;
                                   var beh_tree__isInVehicle : bool&;
                                   var beh_tree__shouldUseVehicle : bool&;
                                   var beh_tree__isFreefallOrParachute : bool&;
                                   var beh_tree__useBomb : bool&)
    beh_tree__navPointId = -1
    beh_tree__capturedCapzone = INVALID_ENTITY_ID
    beh_tree__capzoneOfInterest = INVALID_ENTITY_ID
    beh_tree__orderIsInVehicle = false
    beh_tree__orderShouldUseVehicle = false
    beh_tree__isInVehicle = false
    beh_tree__shouldUseVehicle = false
    beh_tree__useBomb = false
    beh_tree__isFreefallOrParachute = false

  reset_covers(squadMemberEid)

def reload_squad_mate_beh_tree(squadMemberEid : EntityId)
  var was_maxStance = STANCE_STAND
  var was_maxStanceOrder = STANCE_STAND
  var was_maxStanceOrderForce = false
  var was_maxStanceOrderEndTime = 0.0
  var was_maxStanceAtLeast = STANCE_CRAWL
  query(squadMemberEid) <| $ [es] (beh_tree : BehaviourTree)
    was_maxStance             = beh_tree.blackBoard |> datablock_getInt("maxStance", STANCE_STAND)
    was_maxStanceOrder        = beh_tree.blackBoard |> datablock_getInt("maxStanceOrder", STANCE_STAND)
    was_maxStanceOrderForce   = beh_tree.blackBoard |> datablock_getBool("maxStanceOrderForce", false)
    was_maxStanceOrderEndTime = beh_tree.blackBoard |> datablock_getReal("maxStanceOrderEndTime", 0.0)
    was_maxStanceAtLeast      = beh_tree.blackBoard |> datablock_getInt("maxStanceAtLeast", STANCE_CRAWL)

  DngBehTree::load_beh_tree_from_ecs(squadMemberEid)

  query(squadMemberEid) <| $ [es] (var beh_tree : BehaviourTree&;
                                   var beh_tree__latencyLoadBlackBoard : Object?)
    if beh_tree__latencyLoadBlackBoard != null
      *beh_tree__latencyLoadBlackBoard |> set("maxStance", was_maxStance)
      *beh_tree__latencyLoadBlackBoard |> set("maxStanceOrder", was_maxStanceOrder)
      *beh_tree__latencyLoadBlackBoard |> set("maxStanceOrderForce", was_maxStanceOrderForce)
      *beh_tree__latencyLoadBlackBoard |> set("maxStanceOrderEndTime", was_maxStanceOrderEndTime)
      *beh_tree__latencyLoadBlackBoard |> set("maxStanceAtLeast", was_maxStanceAtLeast)
    beh_tree.blackBoard |> set("maxStance", was_maxStance)
    beh_tree.blackBoard |> set("maxStanceOrder", was_maxStanceOrder)
    beh_tree.blackBoard |> set("maxStanceOrderForce", was_maxStanceOrderForce)
    beh_tree.blackBoard |> set("maxStanceOrderEndTime", was_maxStanceOrderEndTime)
    beh_tree.blackBoard |> set("maxStanceAtLeast", was_maxStanceAtLeast)

def reset_squad_mate_behaviour(squadMemberEid : EntityId;
                               newBehaviour : string;
                               var behaviour : das_string&)
  reset_squad_mate_ai_components(squadMemberEid)

  behaviour := newBehaviour
  reload_squad_mate_beh_tree(squadMemberEid)

def reset_squad_mate_behaviour(squadMemberEid : EntityId;
                               resetIfOnTrain : bool = false)
  query(squadMemberEid) <| $ [es(REQUIRE_NOT=ignoreResetSquadMateBehavior)] (squad_member__squad : EntityId;
                                                                             beh_tree__isInTrainBeh : bool;
                                                                             human_freefall__isFreefall : bool;
                                                                             beh_tree__data__findCoverBeh : string;
                                                                             beh_tree__data__checkCoverBeh : string;
                                                                             beh_tree__data__findCoverAroundLeaderBeh : string;
                                                                             beh_tree__data__findCoverAroundLeaderAwayBeh : string;
                                                                             beh_tree__data__findCoverAroundPointBeh : string;
                                                                             beh_tree__data__checkCoverAroundPointBeh : string;
                                                                             beh_tree__data__aggressiveBeh : string;
                                                                             beh_tree__data__passiveBeh : string;
                                                                             beh_tree__data__defendPoint : string;
                                                                             var beh_tree__refs__behaviour : das_string&;
                                                                             var beh_tree__refs__findCoverRef : das_string&;
                                                                             var beh_tree__refs__checkCoverRef : das_string&)
    if beh_tree__isInTrainBeh && !resetIfOnTrain || human_freefall__isFreefall
      return

    query(squad_member__squad) <| $ [es] (squad__squadBehaviour : int;
                                          squad__ownerPlayer : EntityId;
                                          squad__orderType : int)
      var formationSpread = int(SquadFormationSpread ESFN_CLOSEST)
      ecs::query(squad__ownerPlayer) <| $ [es] (squadFormationSpread : int)
        formationSpread = squadFormationSpread

      if squad__orderType == int(SquadOrder ESO_FOLLOW_ME)
        if formationSpread == int(SquadFormationSpread ESFN_CLOSEST)
          beh_tree__refs__findCoverRef := beh_tree__data__findCoverAroundLeaderBeh
          beh_tree__refs__checkCoverRef := beh_tree__data__checkCoverAroundPointBeh
        elif formationSpread == int(SquadFormationSpread ESFN_STANDARD)
          beh_tree__refs__findCoverRef := beh_tree__data__findCoverAroundLeaderAwayBeh
          beh_tree__refs__checkCoverRef := beh_tree__data__checkCoverAroundPointBeh
        else
          beh_tree__refs__findCoverRef := beh_tree__data__findCoverBeh
          beh_tree__refs__checkCoverRef := beh_tree__data__checkCoverBeh

        if squad__squadBehaviour == int(SquadBehaviour ESB_AGGRESSIVE)
          reset_squad_mate_behaviour(squadMemberEid,
                                     beh_tree__data__aggressiveBeh,
                                     beh_tree__refs__behaviour)
        else
          reset_squad_mate_behaviour(squadMemberEid,
                                     beh_tree__data__passiveBeh,
                                     beh_tree__refs__behaviour)
      elif squad__orderType == int(SquadOrder ESO_DEFEND_POINT)
        beh_tree__refs__findCoverRef := beh_tree__data__findCoverAroundPointBeh
        beh_tree__refs__checkCoverRef := beh_tree__data__checkCoverAroundPointBeh
        reset_squad_mate_behaviour(squadMemberEid,
                                   beh_tree__data__defendPoint,
                                   beh_tree__refs__behaviour)
      elif squad__orderType == int(SquadOrder ESO_USE_VEHICLE)
        beh_tree__refs__findCoverRef := beh_tree__data__findCoverAroundPointBeh
        beh_tree__refs__checkCoverRef := beh_tree__data__checkCoverAroundPointBeh
        reset_squad_mate_behaviour(squadMemberEid,
                                   beh_tree__data__defendPoint,
                                   beh_tree__refs__behaviour)

def reset_squad_behaviour(squadEid : EntityId)
  query(squadEid) <| $ [es] (squad__allMembers : EidList)
    for squadMemberEid in squad__allMembers
      reset_squad_mate_behaviour(squadMemberEid)

def reset_squad_behaviour_exclude_personal(squadEid : EntityId)
  query(squadEid) <| $ [es] (squad__allMembers : EidList)
    for squadMemberEid in squad__allMembers
      query(squadMemberEid) <| $ [es] (squad_member__isPersonalOrder : bool)
        if !squad_member__isPersonalOrder
          reset_squad_mate_behaviour(squadMemberEid)

def request_squad_member_response(member_eid : EntityId; squad_member_response = "confirm")
  query(member_eid) <| $ [es] (var squad_member__responseTimer : float&; var squad_member__response : das_string)
    squad_member__responseTimer = 2.5 + gsrnd()
    squad_member__response := squad_member_response

def reset_squad_order(var squad__orderType : int&; var squad__orderUseEntity : EntityId&)
  squad__orderUseEntity = INVALID_ENTITY_ID
  squad__orderType = int(SquadOrder ESO_FOLLOW_ME)

def reset_squad_order(squadEid : EntityId)
  query(squadEid) <| $ [es] (var squad__orderType : int&;
                             var squad__orderUseEntity : EntityId&)
    reset_squad_order(squad__orderType,
                      squad__orderUseEntity)

def collect_squad(squad_eid, squad__leader : EntityId; callback : block<(eid : EntityId) : bool>) : bool
  return find_query() <| $ [es(REQUIRE=walker_agent)] (eid : EntityId; squad_member__squad : EntityId; isAlive : bool)
    if isAlive && squad_eid == squad_member__squad && eid != squad__leader
      return invoke(callback, eid)
    return false

def collect_squad_ai(squad_eid, squad__leader : EntityId; callback : block<(var tree : BehaviourTree) : bool>) : bool
  return find_query() <| $ [es] (eid : EntityId; squad_member__squad : EntityId; isAlive : bool; var beh_tree : BehaviourTree&)
    if isAlive && squad_eid == squad_member__squad && eid != squad__leader
      return invoke(callback, beh_tree)
    return false

def reset_squad_mate_order(var squad_member__orderType : int&; var squad_member__orderPosition : float3&;
                           var squad_member__orderUseEntity : EntityId&;
                           var squad_member__isPersonalOrder : bool&)
  squad_member__orderType = int(SquadMateOrder ESMO_NO_ORDER)
  squad_member__orderPosition = float3()
  squad_member__orderUseEntity = INVALID_ENTITY_ID
  squad_member__isPersonalOrder = false

def reset_squad_mate_order(squadMateEid : EntityId)
  query(squadMateEid) <| $ [es] (var squad_member__orderType : int&;
                                 var squad_member__orderPosition : float3&;
                                 var squad_member__orderUseEntity : EntityId&;
                                 var squad_member__isPersonalOrder : bool&)
    reset_squad_mate_order(squad_member__orderType,
                           squad_member__orderPosition,
                           squad_member__orderUseEntity,
                           squad_member__isPersonalOrder)

def private reset_squadmate_orders_impl(var squad_member__orderType : int&;
                                        var squad_member__orderPosition : float3&;
                                        var squad_member__orderUseEntity : EntityId&;
                                        var squad_member__isPersonalOrder : bool&;
                                        var beh_tree : BehaviourTree&)
  beh_tree.blackBoard |> set("ammoRequester", 0)
  beh_tree.blackBoard |> set("healRequester", 0)
  beh_tree.blackBoard |> set("artilleryRequester", 0)
  beh_tree.blackBoard |> set("buildTarget", 0)
  beh_tree.blackBoard |> set("bombSiteEid", 0)
  beh_tree.blackBoard |> set("artilleryShouldSend", false)
  reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)

def reset_squad_mate_orders(squad_eid, squad__leader : EntityId)
  query(squad_eid) <| $ [es] (squad__allMembers : EidList)
    for memberEid in squad__allMembers
      if memberEid != squad__leader
        query(memberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (var squad_member__orderType : int&;
                                                            var squad_member__orderPosition : float3&;
                                                            var squad_member__orderUseEntity : EntityId&;
                                                            var squad_member__isPersonalOrder : bool&;
                                                            var beh_tree : BehaviourTree&)
          reset_squadmate_orders_impl(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder, beh_tree)

def reset_squadmate_orders_exclude_personal(squad_eid : EntityId)
  query(squad_eid) <| $ [es] (squad__allMembers : EidList)
    for memberEid in squad__allMembers
      query(memberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (var squad_member__orderType : int&;
                                                          var squad_member__orderPosition : float3&;
                                                          var squad_member__orderUseEntity : EntityId&;
                                                          var squad_member__isPersonalOrder : bool&;
                                                          var beh_tree : BehaviourTree&)
        if !squad_member__isPersonalOrder
          reset_squadmate_orders_impl(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder, beh_tree)

def reset_personal_squadmate_orders(squadmate_eid : EntityId)
  query(squadmate_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__squad : EntityId;
                                                          var squad_member__orderType : int&;
                                                          var squad_member__orderPosition : float3&;
                                                          var squad_member__orderUseEntity : EntityId&;
                                                          var squad_member__isPersonalOrder : bool&;
                                                          var beh_tree : BehaviourTree&)
    if squad_member__isPersonalOrder
      if squad_member__orderType == int(SquadMateOrder ESMO_DEFEND_POINT) && has(squad_member__orderUseEntity, "capzone")
        query(squad_member__squad) <| $ [es] (squad__regroupPos : float3)
          beh_tree.blackBoard |> set("wishPosition", squad__regroupPos)
      reset_squadmate_orders_impl(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder, beh_tree)

def get_nearest_squad_mate_for_order(squad_eid, squad__leader : EntityId; order : SquadMateOrder) : MemberForOrder
  return get_nearest_squad_mate_for_order(squad_eid, squad__leader, order) <| $ [unused_argument(_)] (_ : EntityId) => true

def get_nearest_squad_mate_for_order(squad_eid, squad__leader : EntityId; order : SquadMateOrder; cond : block<(EntityId) : bool>) : MemberForOrder
  return get_nearest_squad_mate_for_order_impl(squad_eid, squad__leader, [[MaybeOrder order=order]], cond)

def get_nearest_squad_mate_not_ordered(squad_eid, squad__leader : EntityId) : MemberForOrder
  return get_nearest_squad_mate_not_ordered(squad_eid, squad__leader) <| $ [unused_argument(_)] (_ : EntityId) => true

def get_nearest_squad_mate_not_ordered(squad_eid, squad__leader : EntityId; cond : block<(EntityId) : bool>) : MemberForOrder
  return get_nearest_squad_mate_for_order_impl(squad_eid, squad__leader, [[MaybeOrder nothing=null]], cond)

def private get_nearest_squad_mate_for_order_impl(squad_eid, squad__leader : EntityId; maybe_order : MaybeOrder; cond : block<(EntityId) : bool>) : MemberForOrder
  let leaderTMRef = get_TMatrix(squad__leader, "transform")
  if leaderTMRef == null
    return [[MemberForOrder eid = INVALID_ENTITY_ID, executeOrder = false ]]
  let leaderTM = *leaderTMRef
  var alreadyOrdered = false
  var nearestTeammate = INVALID_ENTITY_ID
  var minDistSq = 0.0
  find_query() <| $ [es(REQUIRE=walker_agent)] (eid : EntityId;
                                                squad_member__squad : EntityId;
                                                squad_member__orderType : int;
                                                transform : float3x4;
                                                isAlive : bool;
                                                isDowned : bool = false)
    if squad_eid != squad_member__squad || eid == squad__leader || !isAlive || isDowned
      return false
    if maybe_order is order
      alreadyOrdered = squad_member__orderType == int(maybe_order as order)
      if alreadyOrdered
        nearestTeammate = eid
        return true
    if !invoke(cond, eid)
      return false
    let distSq = distance_sq(transform[3], leaderTM[3])
    if nearestTeammate == INVALID_ENTITY_ID || distSq < minDistSq
      minDistSq = distSq
      nearestTeammate = eid
    return false

  return [[MemberForOrder eid = nearestTeammate, executeOrder = alreadyOrdered ]]

def get_num_alive_squad_members(squad_eid : EntityId)
  return get_int(squad_eid, "squad__numAliveMembers") ?? 0

def get_squad_leader(squad_eid : EntityId)
  return get_Eid(squad_eid, "squad__leader") ?? INVALID_ENTITY_ID

def get_squad_owner(squadEid : EntityId)
  var ownerEid = INVALID_ENTITY_ID
  query(squadEid) <| $ [es] (squad__ownerPlayer : EntityId)
    ownerEid = squad__ownerPlayer
  return ownerEid

def is_squad_member(squadEid : EntityId; memberEid : EntityId) : bool
  if !squadEid
    return false

  var isMemberSquad = false
  query(memberEid) <| $ [es] (squad_member__squad : EntityId)
    isMemberSquad = squad_member__squad == squadEid
  return isMemberSquad

def suicide_kill(eid : EntityId)
  send_net_event(eid, [[RequestSuicide]])

def kill_squad(squad_eid : EntityId)
  kill_squad(squad_eid) <| $ [unused_argument(_)] (_) => true

def kill_squad(squad_eid : EntityId; blk : block<(eid : EntityId) : bool>)
  query() <| $ [es] (eid : EntityId; squad_member__squad : EntityId; isAlive : bool)
    if isAlive && squad_eid == squad_member__squad && invoke(blk, eid)
      suicide_kill(eid)

def kill_player_squad(player_eid : EntityId) : void
  query(player_eid) <| $ [es(REQUIRE=player)] (possessed : EntityId)
    let squad_eid : EntityId = get_Eid(possessed, "squad_member__squad") ?? INVALID_ENTITY_ID
    if squad_eid != INVALID_ENTITY_ID
      kill_squad(squad_eid)
