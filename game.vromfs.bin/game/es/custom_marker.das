require ecs
require player

[es(tag=ui, on_appear, REQUIRE=localPlayer, track=team)]
def player_team_set_custom_marker_active_es(evt : Event; team : int)
  query() <| $ [es] (custom_marker__showForTeam : int; var custom_marker__active : bool&)
    custom_marker__active = custom_marker__showForTeam == team || custom_marker__showForTeam == TEAM_UNASSIGNED

[es(tag=ui, on_appear)]
def custom_marker_show_by_player_team_es(evt : Event; custom_marker__showForTeam : int; var custom_marker__active : bool&)
  query() <| $ [es(REQUIRE=localPlayer)] (team : int)
    custom_marker__active = custom_marker__showForTeam == team || custom_marker__showForTeam == TEAM_UNASSIGNED
