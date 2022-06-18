require DagorSystem
require game.es.events
require ecs

[es(tag=server, on_disappear)]
def reset_score_ri_group_on_score_entity_destroyed(evt : Event;
                                                   ri_group_score__destroyableRiGroup : int)
  query() <| $ [es] (var destroyable_ri__group : int&)
    if destroyable_ri__group == ri_group_score__destroyableRiGroup
      destroyable_ri__group = -1

[es(tag=server)]
def destroyable_score_ri_destroyed(evt : EventRiExtraDestroyed;
                                   eid : EntityId;
                                   destroyable_ri__group : int)
  if destroyable_ri__group < 0 || !evt.offenderEid
    return
  let baseDestroyableRiGroup = destroyable_ri__group
  let baseRiEid = eid
  let otherRiInGroupExist = find_query() <| $ [es] (eid : EntityId; destroyable_ri__group : int)
    return eid != baseRiEid && destroyable_ri__group == baseDestroyableRiGroup
  if !otherRiInGroupExist
    let isScoreEntityFound = find_query() <| $ [es] (ri_group_score__destroyableRiGroup : int;
                                                     ri_group_score__addScoreForTeam : int;
                                                     ri_group_score__addScoreAmount : int)
      if destroyable_ri__group != ri_group_score__destroyableRiGroup
        return false
      find_query() <| $ [es] (team__id : int;
                              var team__score : float&)
        if team__id == ri_group_score__addScoreForTeam
          team__score += (float(ri_group_score__addScoreAmount))
          return true
        return false
      return true
    if !isScoreEntityFound
      logerr("no score entity for destroyable ri with group : {destroyable_ri__group}")

[es(on_appear)]
def group_score_destroyable_ri(evt : Event;
                               ri_group_score__destroyableRiGroup : int;
                               ri_group_score__addScoreForTeam : int)
  query() <| $ [es] (destroyable_ri__group : int;
                     var destroyable_ri__addScoreTeam : int&)
    if destroyable_ri__group == ri_group_score__destroyableRiGroup
      destroyable_ri__addScoreTeam = ri_group_score__addScoreForTeam

[es(on_appear)]
def init_team_for_score_destroyable_ri_on_create(evt : Event;
                                                 destroyable_ri__group : int;
                                                 var destroyable_ri__addScoreTeam : int&)
  find_query() <| $ [es] (ri_group_score__destroyableRiGroup : int; ri_group_score__addScoreForTeam : int)
    if ri_group_score__destroyableRiGroup == destroyable_ri__group
      destroyable_ri__addScoreTeam = ri_group_score__addScoreForTeam
      return true
    return false
