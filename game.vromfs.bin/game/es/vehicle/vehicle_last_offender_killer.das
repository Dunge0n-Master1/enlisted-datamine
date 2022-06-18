require ecs
require common_shooter.events_common_shooter
require enlisted.game.es.offender_cache_common
require game.utils.team

def get_offender_team(eid : EntityId)
  return get_int(eid, "team") ?? get_int(get_offender_from_cache(eid).player, "team") ?? TEAM_UNASSIGNED

[es(tag=server, REQUIRE=vehicle)]
def vehicle_damage_part_last_offender_weapon(evt : EventOnPartDamaged;
                                             isAlive : bool;
                                             isExploded : bool;
                                             team : int = TEAM_UNASSIGNED;
                                             var lastOffender : EntityId&;
                                             var last_offender__shellId : int&;
                                             var last_offender__gunPropsId : int&)
  let offenderEid = evt.hitData.offender
  if isAlive && !isExploded && !!offenderEid
    if !!lastOffender && is_teams_friendly(get_offender_team(offenderEid), team) && !is_teams_friendly(get_offender_team(lastOffender), team)
      return
    last_offender__shellId = int(evt.hitData.shellId)
    last_offender__gunPropsId = int(evt.hitData.gunPropsId)
    lastOffender = offenderEid