require ecs
require common_shooter.events_common_shooter
require common_shooter.es.vehicle.vehicle_offender_common
require game.utils.team

[es(tag=server, REQUIRE=vehicle)]
def vehicle_damage_part_last_offender_weapon(evt : EventOnPartDamaged;
                                             isAlive : bool;
                                             isExploded : bool;
                                             team : int = TEAM_UNASSIGNED;
                                             var lastOffender : EntityId&;
                                             var last_offender__shellId : int&;
                                             var last_offender__gunPropsId : int&)
  let offenderEid = evt.hitData.offender
  if isAlive && !isExploded
    try_set_last_vehicle_offender(offenderEid, int(evt.hitData.gunPropsId), int(evt.hitData.shellId), team,
                                  lastOffender, last_offender__gunPropsId, last_offender__shellId)
