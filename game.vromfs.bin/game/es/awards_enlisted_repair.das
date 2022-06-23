require ecs
require enlisted.events_enlisted
require game.es.events
require game.es.awards_common
require game.utils.team

[es(tag=server)]
def award_vehicle_repaired(evt : EventOnRepaired;
                           ownedByPlayer : EntityId)
  let awardedSoldier = evt.eid
  query(awardedSoldier) <| $ [es] (squad_member__playerEid : EntityId; guid : string; team : int)
    if (ownedByPlayer == INVALID_ENTITY_ID
        || team == TEAM_UNASSIGNED
        || squad_member__playerEid == ownedByPlayer
        || (get_int(ownedByPlayer, "team") ?? TEAM_UNASSIGNED) != team)
      return
    using <| $(var awardList : Array#)
      awardList |> push_soldier_stat(squad_member__playerEid, guid, "vehicleRepairs")
      broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
        set(init, "list", awardList)
