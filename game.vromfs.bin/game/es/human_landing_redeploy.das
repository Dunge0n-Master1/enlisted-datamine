require ecs
require app
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common

[es(tag=server, REQUIRE_NOT=(deadEntity, human__awaitsRedeploy))]
def check_zone_for_redeploy_after_exit_vehicle(evt : EventEnterVehicle;
                                               eid : EntityId;
                                               redeploy__insideAreaTag : string;
                                               battle_areas_visitor__zonesIn : EidList;
                                               var redeploy__hideBattleAreaWarning : bool&)
  if !evt.enter && has(evt.vehicle, "vehicle__redeployOutsideBattleArea")
    let inHumanZone = 0 <= find_index_if(each(battle_areas_visitor__zonesIn)) <| $(zone)
      return has(zone, redeploy__insideAreaTag, ecs_hash(redeploy__insideAreaTag))
    if !inHumanZone
      addSubTemplate(eid, "landing_outside_battle_area_redeploy") <| $(var init)
        init |> set("landing_redeploy__vehicle", evt.vehicle)
      redeploy__hideBattleAreaWarning = true

[es(tag=server, on_appear, REQUIRE=human__awaitsRedeploy, REQUIRE_NOT=deadEntity, track=battle_areas_visitor__zonesIn)]
def redeploy_after_landing_set_timer(evt : Event;
                                     eid : EntityId;
                                     battle_areas_visitor__zonesIn : EidList;
                                     isOutsideBattleArea : bool;
                                     landing_redeploy__time : float;
                                     landing_redeploy__blackoutTime : float;
                                     redeploy__insideAreaTag : string;
                                     var redeploy__delay : float&;
                                     var redeploy__atTime : float&)
  if isOutsideBattleArea
    redeploy__delay = landing_redeploy__blackoutTime
    redeploy__atTime = get_sync_time() + landing_redeploy__time
  elif length(battle_areas_visitor__zonesIn) > 0
    let inHumanZone = 0 <= find_index_if(each(battle_areas_visitor__zonesIn)) <| $(zone)
      return has(zone, redeploy__insideAreaTag, ecs_hash(redeploy__insideAreaTag))
    if inHumanZone
      removeSubTemplate(eid, "landing_outside_battle_area_redeploy")

def kill_vehicle_if_empty(vehicle_eid : EntityId)
  query(vehicle_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (vehicle_seats__seatEids : EidList; var isAlive : bool&)
    if !is_vehicle_with_alive_crew(vehicle_seats__seatEids)
      isAlive = false

[es(tag=server, on_event=EventEntityRedeployed)]
def destroy_left_vehicle_after_redeploy(evt : Event;
                                        eid aka redeployed_eid : EntityId;
                                        landing_redeploy__vehicle aka redeployed_landing_redeploy__vehicle : EntityId)
  let isAllRedeployed = !find_query() <| $ [es] (eid : EntityId; landing_redeploy__vehicle : EntityId)
    return eid != redeployed_eid && landing_redeploy__vehicle == redeployed_landing_redeploy__vehicle
  if isAllRedeployed
    kill_vehicle_if_empty(redeployed_landing_redeploy__vehicle)
  removeSubTemplate(redeployed_eid, "landing_outside_battle_area_redeploy")

[es(tag=server, on_appear, track=isOutsideBattleArea, REQUIRE_NOT=human__awaitsRedeploy)]
def reset_battle_area_warning(evt : Event; isOutsideBattleArea : bool; var redeploy__hideBattleAreaWarning : bool&)
  redeploy__hideBattleAreaWarning &&= isOutsideBattleArea

[es(tag=server, REQUIRE=vehicle_seats__seats)]
def cancel_redeploy_after_landing_es(evt : CmdAcquireVehicleSeat)
  ecs::query(evt.requester) <| $ [es] (eid : EntityId; var redeploy__atTime : float&)
    redeploy__atTime = -1.0
    removeSubTemplate(eid, "landing_outside_battle_area_redeploy")
