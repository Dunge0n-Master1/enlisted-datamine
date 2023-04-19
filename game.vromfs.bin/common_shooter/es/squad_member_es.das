require ecs
require DngWalkerai
require game.es.ai.walker_common
require HumanPhys
require CollRes
require DagorMath
require DagorMathUtils
require AnimV20
require DngHuman
require Grid
require GridCollision
require DagorDataBlock
require DagorRandom
require vehicle
require BehNodes
require human_sounds_net.modules.human_sounds_net_events
require common_shooter.es.squad_common
require game.es.vehicle.vehicle_seats_common

def is_timer_hit(var timer : float&; dt : float) : bool
  if (timer > 0.f)
    timer -= dt
    return timer <= 0.f ? true : false
  return false

[es(tag=server, no_order)]
def squad_member_response_es(info : ecs::UpdateStageInfoAct;
                             eid : ecs::EntityId;
                             var squad_member__responseTimer : float&;
                             squad_member__response : string;
                             squad_member__squad : ecs::EntityId;
                             isAlive : bool)
  if !isAlive || squad_member__squad == ecs::INVALID_ENTITY_ID
    return
  let leaderEid = get_Eid(squad_member__squad, "squad__leader") ?? INVALID_ENTITY_ID

  if (eid == leaderEid)
    return
  let isResponseRequired = is_timer_hit(squad_member__responseTimer, info.dt)
  if isResponseRequired
    sendEvent(eid, [[CmdRequestHumanSpeech phrase="{squad_member__response}Response"]])

[es(no_order, tag=server)]
def squad_member_crawl_with_leader(info : UpdateStageInfoAct; eid : ecs::EntityId; squad__leader : ecs::EntityId;
                                   squad__ownerPlayer : ecs::EntityId;
                                   var squad__membersCrawlNextCheckTime : float&;
                                   squad__membersCrawlCheckDelta : float;
                                   squad__membersCrawlDistance : float2;
                                   squad__membersCrawlOrderTime : float2)
  if has(squad__ownerPlayer, "playerIsBot") || (squad__membersCrawlNextCheckTime > info.curTime)
    return
  squad__membersCrawlNextCheckTime = info.curTime + squad__membersCrawlCheckDelta

  var leaderTm : float3x4
  var leaderStance = STANCE_STAND
  query(squad__leader) <| $ [es] (transform : float3x4;
                                  human_net_phys : HumanActor)
    leaderTm = transform
    leaderStance = determinate_stance(human_net_phys.phys.currentState)
  if leaderStance != STANCE_CRAWL
    return

  for_each_entity_in_grid(ecs_hash("humans"), BSphere3(leaderTm[3], squad__membersCrawlDistance.x), GridEntCheck BOUNDING) <| $(smEid : EntityId; smPos : float3)
    if (abs(smPos.y - leaderTm[3].y) > squad__membersCrawlDistance.y)
      return
    query(smEid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__squad : EntityId; var beh_tree : BehaviourTree&)
      if squad_member__squad != eid
        return
      beh_tree.blackBoard |> set("maxStanceOrder", STANCE_CRAWL)
      beh_tree.blackBoard |> set("maxStanceOrderForce", true)
      let orderTime = rnd_float(squad__membersCrawlOrderTime.x, squad__membersCrawlOrderTime.y)
      beh_tree.blackBoard |> set("maxStanceOrderEndTime", info.curTime + orderTime)

[es(tag=server, track=isInVehicle)]
def squad_member_can_be_leader_set(evt : Event; isInVehicle : bool; var squad_member__canBeLeader : bool&)
  if (!isInVehicle)
    // Not in vehicle anymore, can be leader
    squad_member__canBeLeader = true

[es(tag=server, on_appear, on_event=EventOnSeatOwnersChanged)]
def squad_member_can_be_leader_update(evt : Event; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__orderNo : int)
      let canPlaceManually = get_bool(vehicle_seats__seatEids[seat__orderNo], "seats_order__canPlaceManually") ?? false
      setOptional(seat__ownerEid, "squad_member__canBeLeader", canPlaceManually)
