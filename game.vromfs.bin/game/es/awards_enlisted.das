require ecs
require game.es.awards_common
require enlisted.game.es.offender_cache_common
require game.es.events
require game.utils.team

[es(tag=server)]
def ri_destroyed_award(evt : EventEntityDestroyed;
                       riOffender : EntityId;
                       destroyable_ri__addScoreTeam : int)
  let offender = get_offender_from_cache(riOffender)
  let offenderPlayerTeam = get_int(offender.player, "team") ?? TEAM_UNASSIGNED
  if is_valid_cache_soldier(offender) && destroyable_ri__addScoreTeam == offenderPlayerTeam
    send_award_stat(offender.player, offender.guid, "barrageBalloonDestructions")
