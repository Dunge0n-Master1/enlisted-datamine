require ecs
require EnlistedWalkerai
require danetlibs.native_dasevents.main.native_events
require enlisted.game.es.enlisted_squad_common
require game.es.battle_area_common
require game.utils.team
require math.base
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require game.es.squad_order_common

[es(tag=server, no_order)]
def squadmate_reset_personal_order_far_away_es(act : UpdateStageInfoAct;
                                               eid : EntityId;
                                               transform : float3x4;
                                               squad_member__squad : EntityId;
                                               var squad_member__orderType : int&;
                                               var squad_member__orderPosition : float3&;
                                               var squad_member__orderUseEntity : EntityId&;
                                               var squad_member__isPersonalOrder : bool&)
  if !squad_member__isPersonalOrder
    return
  if squad_member__orderType != int(SquadMateOrder ESMO_DEFEND_POINT) && squad_member__orderType != int(SquadMateOrder ESMO_USE_VEHICLE)
    return
  if squad_member__orderType == int(SquadMateOrder ESMO_DEFEND_POINT) && squad_member__orderUseEntity != INVALID_ENTITY_ID // ignore "control point" orders
    return
  query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__maxOrderDistance : float)
    if eid == squad__leader
      return

    let memberTm = transform
    query(squad__leader) <| $ [es] (transform : float3x4)
      let leaderTM = transform
      let maxOrderDistSq = square(squad__maxOrderDistance)
      let distSqFromOrderPosToLeader = distance_sq(squad_member__orderPosition, leaderTM[3])
      let distSqFromMemberToLeader = distance_sq(memberTm[3], leaderTM[3])

      if distSqFromOrderPosToLeader >= maxOrderDistSq && distSqFromMemberToLeader >= maxOrderDistSq
        sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="personal_context_command_canceled/too_far"]])
        reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
        reset_squad_mate_behaviour(eid)
        send_order_cancel_bq(eid, "too_far", "{SquadMateOrder ESMO_DEFEND_POINT}")

[es(tag=server, REQUIRE=battle_area, track=active)]
def squadmate_reset_personal_order_on_battlearea_deactivation_es(evt : Event; eid : EntityId; active : bool)
  if active
    return

  let areaEid = eid
  query() <| $ [es] (eid : EntityId;
                     team : int = TEAM_UNASSIGNED;
                     var squad_member__orderType : int&;
                     var squad_member__orderPosition : float3&;
                     var squad_member__orderUseEntity : EntityId&;
                     var squad_member__isPersonalOrder : bool&)
    if !squad_member__isPersonalOrder
      return
    if squad_member__orderType != int(SquadMateOrder ESMO_DEFEND_POINT) && squad_member__orderType != int(SquadMateOrder ESMO_USE_VEHICLE)
      return
    if squad_member__orderType == int(SquadMateOrder ESMO_DEFEND_POINT) && squad_member__orderUseEntity != INVALID_ENTITY_ID // ignore "control point" orders
      return
    if !has_active_human_battle_area_at(squad_member__orderPosition, team, areaEid)
      reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
      reset_squad_mate_behaviour(eid)
      send_order_cancel_bq(eid, "battlearea_deactivation", "{SquadMateOrder ESMO_DEFEND_POINT}")

[es(tag=server, REQUIRE=capzone, track=active)]
def squadmate_reset_personal_order_on_capzone_deactivation_es(evt : Event; eid aka zone_eid : EntityId; active : bool)
  if active
    return

  query() <| $ [es] (eid : EntityId;
                     var squad_member__orderType : int&;
                     var squad_member__orderPosition : float3&;
                     var squad_member__orderUseEntity : EntityId&;
                     var squad_member__isPersonalOrder : bool&)
    if !squad_member__isPersonalOrder
      return
    if squad_member__orderType != int(SquadMateOrder ESMO_DEFEND_POINT)
      return
    if squad_member__orderUseEntity != zone_eid
      return
    send_order_cancel_bq(eid, "capzone_update", "{squad_member__orderType}")
    reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
    reset_squad_mate_behaviour(eid)
