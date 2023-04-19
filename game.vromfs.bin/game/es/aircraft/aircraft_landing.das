require ecs
require ecs.safe
require strings
require Plane
require DngPlane
require game.es.events
require game.es.awards_common
require game.es.vehicle.vehicle_seats_common

[es(tag=server, REQUIRE_NOT=deadEntity)]
def plane_landing_state(evt : CmdPostPhysUpdate;
                        plane_net_phys : PlaneActor;
                        plane_landing__maxSpeed : float;
                        plane_landing__requiredTimeLanded : float;
                        var plane_landing__landedTime : float&;
                        var plane_landing__isLanded : bool&)
  assume fm = plane_net_phys.phys

  let isStopped = fm.Gears.onSurface && fm.speed <= plane_landing__maxSpeed

  plane_landing__isLanded ||= plane_landing__landedTime >= plane_landing__requiredTimeLanded
  plane_landing__isLanded &&= plane_landing__landedTime > 0.

  if isStopped
    plane_landing__landedTime += evt.dt
  else
    plane_landing__landedTime -= evt.dt
  plane_landing__landedTime = clamp(plane_landing__landedTime, 0., plane_landing__requiredTimeLanded)

[es(tag=server, on_appear, on_event=EventOnSeatOwnersChanged)]
def plane_landing_keep_pilot_guid_for_award(evt : Event;
                                            vehicle_seats__seatEids : EidList;
                                            var plane_landing__awardSoldierGuid : das_string&)
  let driver = get_vehicle_driver(vehicle_seats__seatEids)
  if !!driver
    plane_landing__awardSoldierGuid := driver |> get_string("guid", "")

[es(tag=server, REQUIRE=deadEntity, on_appear)]
def add_squad_revive_points_if_landed_plane_dead(evt : Event;
                                                 ownedBySquad : EntityId;
                                                 plane_landing__awardStat : string;
                                                 plane_landing__awardSoldierGuid : string;
                                                 plane_landing__isLanded : bool;
                                                 plane_landing__squadRevivePointsIfLanded : int;
                                                 plane__waitingTakeOff : Tag const?)
  if plane_landing__isLanded && plane__waitingTakeOff == null
    query(ownedBySquad) <| $ [es] (squad__isAlive : bool;
                                   squad__ownerPlayer : EntityId;
                                   var squad__revivePointsAfterDeath : int&)
      if squad__isAlive
        query(squad__ownerPlayer) <| $ [es] (squads__revivePointsPerSquad : int; squads__revivePointsAfterDeath : int)
          squad__revivePointsAfterDeath = min(100, max(squads__revivePointsAfterDeath,
                                                       squads__revivePointsPerSquad * plane_landing__squadRevivePointsIfLanded))
      if !empty(plane_landing__awardStat) && !empty(plane_landing__awardSoldierGuid)
        send_award_stat(squad__ownerPlayer, plane_landing__awardSoldierGuid, plane_landing__awardStat)

def reduce_squad_rotation_queue(player_eid : EntityId; squad_id : int; amount : int)
  query(player_eid) <| $ [es] (squads__revivePointsPerSquad : int; var squads__revivePointsList : IntList&)
    if squad_id >= 0 && squad_id < length(squads__revivePointsList)
      let pointsBefore = squads__revivePointsList[squad_id]
      squads__revivePointsList[squad_id] = (min(100, max(pointsBefore,
                                                         squads__revivePointsPerSquad * amount)))

[es(tag=server, track=squad__isAlive)]
def add_squad_revive_points_for_landed_plane_if_squad_dead(evt : Event;
                                                           squad__isAlive : bool;
                                                           eid aka squad_eid : EntityId;
                                                           squad__id : int;
                                                           squad__ownerPlayer : EntityId)
  if !squad__isAlive
    find_query() <| $ [es(REQUIRE_NOT=deadEntity)] (ownedBySquad : EntityId;
                                                    plane_landing__isLanded : bool;
                                                    plane_landing__squadRevivePointsIfLanded : int;
                                                    plane__waitingTakeOff : Tag const?)
      if ownedBySquad == squad_eid
        if plane_landing__isLanded && plane__waitingTakeOff == null
          reduce_squad_rotation_queue(squad__ownerPlayer, squad__id, plane_landing__squadRevivePointsIfLanded)
        return true
      return false

[es(tag=server, on_appear, REQUIRE=ownedBySquad)]
def plane_take_off_init(evt : Event; eid : EntityId; setupOnGround : bool)
  if setupOnGround
    addSubTemplate(eid, "plane_take_off")

[es(tag=server, REQUIRE=plane__waitingTakeOff)]
def plane_take_off(evt : CmdPostPhysUpdate;
                   eid : EntityId;
                   plane_net_phys : PlaneActor;
                   plane__takeOffHeight : float)
  if !plane_net_phys.phys.Gears.onSurface && plane_net_phys.phys.currentAlt > plane__takeOffHeight
    removeSubTemplate(eid, "plane_take_off")
