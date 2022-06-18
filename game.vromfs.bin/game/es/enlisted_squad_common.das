module enlisted_squad_common shared
require ecs
require DagorRandom
require EnlistedDm
require EnlistedWalkerai
require DagorDataBlock
require game.es.events
require BehNodes
require game.events_game

variant MaybeOrder
  order : SquadMateOrder
  nothing : void?

struct MemberForOrder
  eid : EntityId
  executeOrder : bool

def request_squad_member_response(member_eid : ecs::EntityId; squad_member_response = "confirm")
  ecs::query(member_eid) <| $ [es] (var squad_member__responseTimer : float&; var squad_member__response : das_string)
    squad_member__responseTimer = 2.5 + gsrnd()
    squad_member__response := squad_member_response

def reset_squad_order(var squad__orderType : int&; var squad__orderUseEntity : ecs::EntityId&)
  squad__orderUseEntity = ecs::INVALID_ENTITY_ID
  squad__orderType = int(SquadOrder ESO_FOLLOW_ME)

def collect_squad(squad_eid, squad__leader : ecs::EntityId; callback : block<(eid : EntityId) : bool>) : bool
  return ecs::find_query() <| $ [es(REQUIRE=walker_agent)] (eid : ecs::EntityId; squad_member__squad : ecs::EntityId; isAlive : bool)
    if isAlive && squad_eid == squad_member__squad && eid != squad__leader
      return invoke(callback, eid)
    return false

def collect_squad_ai(squad_eid, squad__leader : ecs::EntityId; callback : block<(var tree : BehaviourTree) : bool>) : bool
  return ecs::find_query() <| $ [es] (eid : ecs::EntityId; squad_member__squad : ecs::EntityId; isAlive : bool; var beh_tree : BehaviourTree&)
    if isAlive && squad_eid == squad_member__squad && eid != squad__leader
      return invoke(callback, beh_tree)
    return false

def reset_squad_mate_order(var squad_member__orderType : int&; var squad_member__orderPosition : float3&;
                           var squad_member__orderUseEntity : ecs::EntityId&;
                           var squad_member__isPersonalOrder : bool&)
  squad_member__orderType = int(SquadMateOrder ESMO_NO_ORDER)
  squad_member__orderPosition = float3()
  squad_member__orderUseEntity = INVALID_ENTITY_ID
  squad_member__isPersonalOrder = false


def private reset_squadmate_orders_impl(var squad_member__orderType : int&;
                                        var squad_member__orderPosition : float3&;
                                        var squad_member__orderUseEntity : ecs::EntityId&;
                                        var squad_member__isPersonalOrder : bool&;
                                        var beh_tree : BehaviourTree&)
  beh_tree.blackBoard |> datablock_setInt("ammoRequester", 0)
  beh_tree.blackBoard |> datablock_setInt("healRequester", 0)
  beh_tree.blackBoard |> datablock_setInt("artilleryRequester", 0)
  beh_tree.blackBoard |> datablock_setInt("buildTarget", 0)
  beh_tree.blackBoard |> datablock_setInt("bombSiteEid", 0)
  beh_tree.blackBoard |> datablock_setBool("artilleryShouldSend", false)
  reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)

def reset_squad_mate_orders(squad_eid, squad__leader : ecs::EntityId)
  query(squad_eid) <| $ [es] (squad__allMembers : EidList)
    for memberEid in squad__allMembers
      if memberEid != squad__leader
        query(memberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (var squad_member__orderType : int&;
                                                            var squad_member__orderPosition : float3&;
                                                            var squad_member__orderUseEntity : ecs::EntityId&;
                                                            var squad_member__isPersonalOrder : bool&;
                                                            var beh_tree : BehaviourTree&)
          reset_squadmate_orders_impl(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder, beh_tree)

def reset_squadmate_orders_exclude_personal(squad_eid, squad__leader : EntityId)
  query(squad_eid) <| $ [es] (squad__allMembers : EidList)
    for memberEid in squad__allMembers
      if memberEid != squad__leader
        query(memberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (var squad_member__orderType : int&;
                                                            var squad_member__orderPosition : float3&;
                                                            var squad_member__orderUseEntity : ecs::EntityId&;
                                                            var squad_member__isPersonalOrder : bool&;
                                                            var beh_tree : BehaviourTree&)
          if !squad_member__isPersonalOrder
            reset_squadmate_orders_impl(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder, beh_tree)

def reset_personal_squadmate_orders(squadmate_eid : ecs::EntityId)
  ecs::query(squadmate_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__squad : EntityId;
                                                               var squad_member__orderType : int&;
                                                               var squad_member__orderPosition : float3&;
                                                               var squad_member__orderUseEntity : ecs::EntityId&;
                                                               var squad_member__isPersonalOrder : bool&;
                                                               var beh_tree : BehaviourTree&)
    if squad_member__isPersonalOrder
      if squad_member__orderType == int(SquadMateOrder ESMO_DEFEND_POINT) && has(squad_member__orderUseEntity, "capzone")
        query(squad_member__squad) <| $ [es] (squad__regroupPos : float3)
          beh_tree.blackBoard |> datablock_setPoint3("wishPosition", squad__regroupPos)
      reset_squadmate_orders_impl(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder, beh_tree)

def get_nearest_squad_mate_for_order(squad_eid, squad__leader : ecs::EntityId; order : SquadMateOrder) : MemberForOrder
  return get_nearest_squad_mate_for_order(squad_eid, squad__leader, order) <| $ [unused_argument(_)] (_ : EntityId) => true

def get_nearest_squad_mate_for_order(squad_eid, squad__leader : ecs::EntityId; order : SquadMateOrder; cond : block<(EntityId) : bool>) : MemberForOrder
  return get_nearest_squad_mate_for_order_impl(squad_eid, squad__leader, [[MaybeOrder order=order]], cond)

def get_nearest_squad_mate_not_ordered(squad_eid, squad__leader : ecs::EntityId) : MemberForOrder
  return get_nearest_squad_mate_not_ordered(squad_eid, squad__leader) <| $ [unused_argument(_)] (_ : EntityId) => true

def get_nearest_squad_mate_not_ordered(squad_eid, squad__leader : ecs::EntityId; cond : block<(EntityId) : bool>) : MemberForOrder
  return get_nearest_squad_mate_for_order_impl(squad_eid, squad__leader, [[MaybeOrder nothing=null]], cond)

def private get_nearest_squad_mate_for_order_impl(squad_eid, squad__leader : ecs::EntityId; maybe_order : MaybeOrder; cond : block<(EntityId) : bool>) : MemberForOrder
  let leaderTMRef = get_TMatrix(squad__leader, "transform")
  if leaderTMRef == null
    return [[MemberForOrder eid = INVALID_ENTITY_ID, executeOrder = false ]]
  let leaderTM = *leaderTMRef
  var alreadyOrdered = false
  var nearestTeammate = ecs::INVALID_ENTITY_ID
  var minDistSq = 0.0
  ecs::find_query() <| $ [es(REQUIRE=walker_agent)] (eid : EntityId;
                                                     squad_member__squad : EntityId;
                                                     squad_member__orderType : int;
                                                     squad_member__isPersonalOrder : bool;
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
    if (squad_member__orderType != int(SquadMateOrder ESMO_NO_ORDER) && !squad_member__isPersonalOrder) || !invoke(cond, eid)
      return false
    let distSq = distance_sq(transform[3], leaderTM[3])
    if nearestTeammate == ecs::INVALID_ENTITY_ID || distSq < minDistSq
      minDistSq = distSq
      nearestTeammate = eid
    return false

  return [[MemberForOrder eid = nearestTeammate, executeOrder = alreadyOrdered ]]

def get_num_alive_squad_members(squad_eid : ecs::EntityId)
  return get_int(squad_eid, "squad__numAliveMembers") ?? 0

def get_squad_leader(squad_eid : ecs::EntityId)
  return get_Eid(squad_eid, "squad__leader") ?? ecs::INVALID_ENTITY_ID

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
  sendEvent(eid, [[RequestSuicide]])

def kill_squad(squad_eid : EntityId)
  kill_squad(squad_eid) <| $ [unused_argument(_)] (_) => true

def kill_squad(squad_eid : EntityId; blk : block<(eid : EntityId) : bool>)
  ecs::query() <| $ [es] (eid : ecs::EntityId; squad_member__squad : ecs::EntityId; isAlive : bool)
    if isAlive && squad_eid == squad_member__squad && invoke(blk, eid)
      suicide_kill(eid)

def kill_player_squad(player_eid : EntityId) : void
  query(player_eid) <| $ [es(REQUIRE=player)] (possessed : EntityId)
    let squad_eid : EntityId = get_Eid(possessed, "squad_member__squad") ?? INVALID_ENTITY_ID
    if squad_eid != INVALID_ENTITY_ID
      kill_squad(squad_eid)
