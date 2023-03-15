require ecs
require enlisted.events_enlisted
require game.es.events
require game.es.awards_common
require game.es.vehicle.vehicle_events
require game.utils.team

def award_vehicle_maintenance(eid : EntityId; vehicle_owner_player_eid : EntityId; stat : string)
  query(eid) <| $ [es] (squad_member__playerEid : EntityId; guid : string; team : int)
    if (vehicle_owner_player_eid == INVALID_ENTITY_ID
        || team == TEAM_UNASSIGNED
        || squad_member__playerEid == vehicle_owner_player_eid
        || (get_int(vehicle_owner_player_eid, "team") ?? TEAM_UNASSIGNED) != team)
      return
    using() <| $(var awardList : Array)
      awardList |> push_soldier_stat(squad_member__playerEid, guid, stat)
      broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
        set(init, "list", awardList)

[es(tag=server)]
def award_vehicle_repaired(evt : EventOnRepaired; ownedByPlayer : EntityId)
  award_vehicle_maintenance(evt.eid, ownedByPlayer, "vehicleRepairs")

[es(tag=server)]
def award_vehicle_extinguished(evt : EventOnVehicleExtinguished; ownedByPlayer : EntityId)
  award_vehicle_maintenance(evt.eid, ownedByPlayer, "vehicleExtinguishes")
