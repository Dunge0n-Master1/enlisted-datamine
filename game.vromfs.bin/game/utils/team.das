module team shared
require ecs
require player public

def is_teams_friendly(lhs, rhs : int)
  return lhs == rhs && lhs != TEAM_UNASSIGNED && rhs != TEAM_UNASSIGNED

def get_local_player_team()
  return get_int(get_local_player_eid(), "team") ?? TEAM_UNASSIGNED


def have_active_teammates(owner_eid : EntityId; our_team : int; include_bots = false)
  return find_query() <| $ [es(REQUIRE=human)] (eid : EntityId;
                                                team : int;
                                                countAsAlive, isAlive, isDowned : bool;
                                                beh_tree__enabled = false;
                                                isSpectatable = true)
    return (
         eid != owner_eid
      && countAsAlive && isAlive && isSpectatable
      && !isDowned
      && is_teams_friendly(team, our_team)
      && (include_bots ? true : !beh_tree__enabled)
    )
