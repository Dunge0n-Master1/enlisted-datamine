require ecs
require EnlistedWalkerai
require math
require zones
require DagorDataBlock
require game.es.events
require enlisted.game.es.enlisted_squad_common
require enlisted.events_enlisted
require game.es.battle_area_common
require game.utils.team
require math.base
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require BehNodes
require game.es.squad_order_common

def get_entity_transform(eid : EntityId) : float3x4 const?
  return get_TMatrix(eid, "transform")

[es(tag=server, no_order)]
def squad_reset_order_far_away_es(act : ecs::UpdateStageInfoAct; eid, squad__leader : ecs::EntityId; squad__orderPosition : float3 const&;
                                  squad__maxOrderDistance : float; var squad__orderUseEntity : EntityId&; var squad__orderType : int&)
  if !squad__leader || (squad__orderType != int(SquadOrder ESO_DEFEND_POINT) && squad__orderType != int(SquadOrder ESO_USE_VEHICLE))
    return
  if squad__orderType == int(SquadOrder ESO_DEFEND_POINT) && squad__orderUseEntity != INVALID_ENTITY_ID // ignore "control point" orders
    return
  let leaderTm = get_entity_transform(squad__leader)
  if leaderTm == null
    return

  if distance_sq(squad__orderPosition, (*leaderTm)[3]) >= square(squad__maxOrderDistance)
    let isMembersTooFar = collect_squad(eid, squad__leader) <| $(member_eid : EntityId)
      let member_transform = get_TMatrix(member_eid, "transform")
      if member_transform != null
        return distance_sq((*member_transform)[3], (*leaderTm)[3]) >= square(squad__maxOrderDistance)
      return false

    if isMembersTooFar
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command_canceled/to_far"]])
      reset_squad_order(squad__orderType, squad__orderUseEntity)
      reset_squad_behaviour_exclude_personal(eid)
      send_order_cancel_bq(squad__leader, "to_far", "{SquadOrder ESO_DEFEND_POINT}")

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
def squad_reset_order_on_capzone_update_es(evt : Event; active : bool)
  if active
    return

  query() <| $ [es] (eid : EntityId;
                     squad__leader : EntityId;
                     var squad__orderType : int&;
                     var squad__orderUseEntity : EntityId&)
    if squad__orderType == int(SquadOrder ESO_USE_VEHICLE)
      return
    reset_squad_order(squad__orderType, squad__orderUseEntity)
    reset_squad_behaviour_exclude_personal(eid)
    send_order_cancel_bq(squad__leader, "capzone_update", "{squad__orderType}")
