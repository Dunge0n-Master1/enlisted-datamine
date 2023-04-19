require ecs
require DngWalkerai
require math
require zones
require DagorDataBlock
require danetlibs.native_dasevents.main.native_events
require enlisted.game.es.enlisted_squad_common
require enlisted.events_enlisted
require game.es.battle_area_common
require game.utils.team
require math.base
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require BehNodes
require game.es.squad_order_common

[es(tag=server, no_order)]
def squad_reset_order_far_away_es(act : UpdateStageInfoAct;
                                  eid aka squad_eid : EntityId;
                                  squad__leader : EntityId;
                                  squad__orderPosition : float3;
                                  squad__maxOrderDistance : float;
                                  squad__allMembers : EidList;
                                  var squad__orderUseEntity : EntityId&;
                                  var squad__orderType : int&)
  if !squad__leader || (squad__orderType != int(SquadOrder ESO_DEFEND_POINT) && squad__orderType != int(SquadOrder ESO_USE_VEHICLE))
    return
  if squad__orderType == int(SquadOrder ESO_DEFEND_POINT) && squad__orderUseEntity != INVALID_ENTITY_ID // ignore "control point" orders
    return

  query(squad__leader) <| $ [es] (transform aka leader_transform : float3x4)
    assume leaderPos = leader_transform[3]

    if distance_sq(squad__orderPosition, leaderPos) < square(squad__maxOrderDistance)
      return
    var isMembersTooFar = false
    for member in squad__allMembers
      if member != squad__leader
        query(member) <| $ [es(REQUIRE_NOT=deadEntity)] (transform aka member_transform : float3x4; squad_member__isPersonalOrder : bool)
          isMembersTooFar ||= !squad_member__isPersonalOrder && distance_sq(member_transform[3], leaderPos) >= square(squad__maxOrderDistance)
      if isMembersTooFar
        sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command_canceled/to_far"]])
        reset_squad_order(squad__orderType, squad__orderUseEntity)
        reset_squad_behaviour_exclude_personal(squad_eid)
        send_order_cancel_bq(squad__leader, "to_far", "{SquadOrder ESO_DEFEND_POINT}")
        return

[es(tag=server, REQUIRE=battle_area, track=active)]
def squad_reset_order_on_battlearea_deactivation_es(evt : Event; eid aka capzone_eid : EntityId; active : bool)
  if active
    return

  query() <| $ [es] (eid aka squad_eid : EntityId;
                     squad__orderPosition : float3 const&;
                     squad__leader : EntityId;
                     var squad__orderType : int&;
                     var squad__orderUseEntity : EntityId&)
    let leaderTeam = get_int(squad__leader, "team") ?? TEAM_UNASSIGNED
    if !has_active_human_battle_area_at(squad__orderPosition, leaderTeam, capzone_eid)
      reset_squad_order(squad__orderType, squad__orderUseEntity)
      reset_squad_behaviour_exclude_personal(squad_eid)
      send_order_cancel_bq(squad__leader, "battlearea_deactivation", "{SquadOrder ESO_DEFEND_POINT}")

[es(tag=server, REQUIRE=capzone, track=active)]
def squad_reset_order_on_capzone_update_es(evt : Event; eid aka zone_eid : EntityId; active : bool)
  if active
    return

  query() <| $ [es] (eid : EntityId;
                     squad__leader : EntityId;
                     var squad__orderType : int&;
                     var squad__orderUseEntity : EntityId&)
    if squad__orderType == int(SquadOrder ESO_DEFEND_POINT) && squad__orderUseEntity == zone_eid
      reset_squad_order(squad__orderType, squad__orderUseEntity)
      reset_squad_behaviour_exclude_personal(eid)
      send_order_cancel_bq(squad__leader, "capzone_update", "{squad__orderType}")
