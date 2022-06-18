require ecs
require enlisted.events_enlisted
require DagorRandom
require DagorSystem

def swap_team(var team : int&; team1, team2 : int)
  if team == team1
    team = team2
  elif team == team2
    team = team1

[es(tag=server, on_event=EventLevelLoaded)]
def change_team_pair_es(evt : Event; swapProbability : float;  team1 : int; team2 : int; var isTeamsSwitched : bool&)
  if team1 != -1 && team2 != -1 && gfrnd() < swapProbability
    print("Spawns and battleAreas changed between teams {team1} and {team2}")
    isTeamsSwitched = true
    ecs::query() <| $ [es(REQUIRE=respbase)] (var team : int&)
      swap_team(team, team1, team2)
    ecs::query() <| $ [es(REQUIRE=battle_area)] (var battle_area__team : int&)
      swap_team(battle_area__team, team1, team2)
    ecs::query() <| $ [es(REQUIRE=resupplyZone)] (var resupply_zone__team : int&)
      swap_team(resupply_zone__team, team1, team2)
    broadcastEvent([[EventOnChangeSpawnTeams]])