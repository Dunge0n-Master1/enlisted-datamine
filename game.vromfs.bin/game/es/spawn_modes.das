require ecs
require game.es.events

def apply_spawn_mode_to_player_and_team(player_eid : EntityId)
  var UNLIMITED_SPAWNS = false
  var ONE_SPAWN_PER_UNIT = false

  query() <| $ [es(REQUIRE=spawnMode)] (spawn_mode__unlimitedSpawns : bool = false;
                                        spawn_mode__oneSpawnPerUnit : bool = false)
    if spawn_mode__unlimitedSpawns
      UNLIMITED_SPAWNS = true
    if spawn_mode__oneSpawnPerUnit
      ONE_SPAWN_PER_UNIT = true

  if UNLIMITED_SPAWNS
    ONE_SPAWN_PER_UNIT = false

  var heal = -1
  var dead = -1
  if UNLIMITED_SPAWNS
    heal = 100
    dead = 100
  if ONE_SPAWN_PER_UNIT
    heal = 0
    dead = 0

  var perSoldier = false
  query(player_eid) <| $ [es] (var soldier_revive_points__healPerSquadmate : IntList&;
                               var soldier_revive_points__afterDeath : IntList&)
    perSoldier = true

    if heal >= 0
      for pts in soldier_revive_points__healPerSquadmate
        pts = heal

    if dead >= 0
      for pts in soldier_revive_points__afterDeath
        pts = dead

  // Should keep squads available until all soldiers dead for LONE_FIGHTERS mode
  // (see spawn_defeat.das for code that makes squad unavailable if all soldiers dead)
  //
  if perSoldier && ONE_SPAWN_PER_UNIT
    heal = 100
    dead = 100

  query(player_eid) <| $ [es] (team : int;
                               var squads__revivePointsPerSquad : int&;
                               var squads__revivePointsAfterDeath : int&)
    if heal >= 0
      squads__revivePointsPerSquad = heal
    if dead >= 0
      squads__revivePointsAfterDeath = dead

    if UNLIMITED_SPAWNS || ONE_SPAWN_PER_UNIT
      query() <| $ [es] (team__id : int; var team__eachSquadMaxSpawns : int&)
        if team__id == team
          team__eachSquadMaxSpawns = -1

[es(tag=server, REQUIRE=spawnMode, on_appear)]
def apply_spawn_mode_init_es(evt : Event)
  query() <| $ [es(REQUIRE=player)] (eid : EntityId)
    apply_spawn_mode_to_player_and_team(eid)

[es(tag=server, REQUIRE=(player, squads__revivePointsPerSquad, squads__revivePointsAfterDeath), on_appear, track=isArmiesReceived)]
def apply_spawn_mode_on_player_profile_changed_es(evt : Event; eid : EntityId; isArmiesReceived : bool)
  if isArmiesReceived
    apply_spawn_mode_to_player_and_team(eid)

[es(tag=server, REQUIRE=(player, soldier_revive_points__healPerSquadmate, soldier_revive_points__afterDeath),
                on_appear, after=soldier_revive_points_init_es)]
def apply_spawn_mode_after_init_soldier_revive_es(evt : Event; eid : EntityId)
  apply_spawn_mode_to_player_and_team(eid)
