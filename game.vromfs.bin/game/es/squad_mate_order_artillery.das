require ecs
require EnlistedWalkerai
require DagorDataBlock
require BehNodes
require game.es.events
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require game.es.sound_net.sound_net_events
require enlisted.game.es.artillery_radio_common
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common

def get_squad_radioman(squad_eid : ecs::EntityId; squad__leader : ecs::EntityId) : MemberForOrder
  return get_nearest_squad_mate_for_order(squad_eid, squad__leader, SquadMateOrder ESMO_ARTILLERY) <| $(eid : EntityId)
    var hasRadio = false
    ecs::query(eid) <| $ [es(REQUIRE=walker_agent)] (human_weap__radioEid : EntityId)
      hasRadio = !!human_weap__radioEid
    return hasRadio

def prepare_artillery_strike(squad_eid, squad__leader : ecs::EntityId; squad__numAliveMembers : int) : bool
  let radioMan = get_squad_radioman(squad_eid, squad__leader)
  if radioMan.executeOrder
    return true
  if radioMan.eid == INVALID_ENTITY_ID || radioMan.eid == squad__leader
    if squad__numAliveMembers <= 1
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad__leader, "no_alive_squadmates", "{SquadMateOrder ESMO_ARTILLERY}")
    else
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="artillery_order/no_radioman"]])
      send_order_cancel_bq(squad__leader, "no_radioman", "{SquadMateOrder ESMO_ARTILLERY}")
    return false

  var ordered = false

  ecs::query(radioMan.eid) <| $ [es] (var squad_member__orderType : int&;
                                      var squad_member__orderUseEntity : ecs::EntityId&;
                                      var squad_member__isPersonalOrder : bool&;
                                      var beh_tree : BehaviourTree&)
    beh_tree.blackBoard |> datablock_setBool("artilleryShouldSend", false)
    beh_tree.blackBoard |> datablock_setInt("artilleryRequester", int(uint(squad__leader)))
    squad_member__orderType = int(SquadMateOrder ESMO_ARTILLERY)
    squad_member__orderUseEntity = INVALID_ENTITY_ID
    squad_member__isPersonalOrder = false
    ordered = true

  if ordered
    send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_ARTILLERY}")
  return ordered

[es(tag=server)]
def on_squad_mate_artillery_order_over(evt : RequestArtilleryOverOrder; eid : ecs::EntityId)
  let squad_eid = eid
  ecs::find_query() <| $ [es] (squad_member__squad : ecs::EntityId;
                               var squad_member__orderType : int&;
                               var squad_member__orderPosition : float3&;
                               var squad_member__orderUseEntity : ecs::EntityId&;
                               var squad_member__isPersonalOrder : bool&;
                               var beh_tree : BehaviourTree&)
    if squad_member__squad != squad_eid
      return false
    if squad_member__orderType != int(SquadMateOrder ESMO_ARTILLERY)
      return false

    if evt.active
      squad_member__orderPosition = evt.targetPos
      beh_tree.blackBoard |> datablock_setInt("artilleryTypeIndex", evt.typeIndex)
      beh_tree.blackBoard |> datablock_setPoint3("artilleryPosEnd", evt.posEnd)
      beh_tree.blackBoard |> datablock_setBool("artilleryShouldSend", true)
    else
      if (beh_tree.blackBoard |> datablock_getBool("artilleryShouldSend", false))
        return false
      reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
      beh_tree.blackBoard |> datablock_setInt("artilleryRequester", 0)
      beh_tree.blackBoard |> datablock_setBool("artilleryShouldSend", false)
    return true

[es(tag=server)]
def on_squad_mate_artillery_order(evt : RequestSquadMateOrder; eid : ecs::EntityId; squad__leader : ecs::EntityId; squad__numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_ARTILLERY && can_order_artillery_strike(squad__leader, eid)
    prepare_artillery_strike(eid, squad__leader, squad__numAliveMembers)

[es(tag=gameClient)]
def on_squad_mate_artillery_order_open_map(evt : RequestSquadMateOrder; eid : ecs::EntityId; squad__leader : ecs::EntityId)
  if evt.orderType == SquadMateOrder ESMO_ARTILLERY && can_order_artillery_strike(squad__leader, eid)
    sendEvent(squad__leader, [[CmdOpenArtilleryMap]])

[es(on_event=EventEntityDied, tag=server)]
def on_squad_mate_artillery_died_es(evt : Event; eid : EntityId; squad_member__squad : ecs::EntityId; squad_member__orderType : int; squad__numAliveMembers : int)
  if squad_member__orderType == int(SquadMateOrder ESMO_ARTILLERY)
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_ARTILLERY}")
    ecs::query(squad_member__squad) <| $ [es] (squad__leader : ecs::EntityId)
      prepare_artillery_strike(squad_member__squad, squad__leader, squad__numAliveMembers)

[es(tag=server, no_order)]
def on_squad_mate_artillery_es(act : ecs::UpdateStageInfoAct;
                               squad_member__squad : ecs::EntityId;
                               var beh_tree : BehaviourTree&;
                               var squad_member__orderType : int&;
                               var squad_member__orderPosition : float3&;
                               var squad_member__orderUseEntity : ecs::EntityId&;
                               var squad_member__isPersonalOrder : bool&)
  if int(squad_member__orderType) != int(SquadMateOrder ESMO_ARTILLERY)
    return
  ecs::query(squad_member__squad) <| $ [es] (squad__leader : ecs::EntityId)
    if beh_tree.blackBoard |> datablock_getInt("artilleryRequester", 0) != int(uint(squad__leader))
      reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
      beh_tree.blackBoard |> datablock_setInt("artilleryRequester", 0)
      beh_tree.blackBoard |> datablock_setBool("artilleryShouldSend", false)

[es(tag=server)]
def squad_mate_order_artillery_es(evt : RequestSquadMateOrder; eid : ecs::EntityId; squad__leader : ecs::EntityId)
  if evt.orderType == SquadMateOrder ESMO_ARTILLERY
    let radioman = get_squad_radioman(eid, squad__leader)
    if radioman.eid != INVALID_ENTITY_ID && !radioman.executeOrder
      sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadPrepareArtilleryOrder", importance=1.]])
