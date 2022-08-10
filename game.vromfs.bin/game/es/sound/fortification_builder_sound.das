require ecs
require game.utils.team
require player

[es(tag=sound, on_appear, REQUIRE=(buildByPlayer, muteForTeammates))]
def fortification_builder_sound_activate(evt : Event;
                                         team : int;
                                         var sound_control__enable : bool&)
  let localPlayerEid  = get_local_player_eid()
  let localPlayerTeam = get_int(localPlayerEid, "team") ?? TEAM_UNASSIGNED
  sound_control__enable = !is_teams_friendly(team, localPlayerTeam)
