require ecs

[es(tag=(server, gameClient), on_appear, REQUIRE=player, before=spawn_squad_es)]
def spawn_tutorial_player_immediate_es(evt : Event;
                                       var respawner__enabled : bool&;
                                       var respawner__respStartTime : float&;
                                       var respawner__respEndTime : float&;
                                       var respawner__canRespawnTime : float&;
                                       var respawner__canRespawnWaitNumber : int&;
                                       var respawner__respTime : float&;
                                       var isFirstSpawn : bool&;
                                       var respawner__canSpawnMinTime : float&;
                                       var respawner__missionStartDelay : float&)
  find_query() <| $ [es(REQUIRE=spawnPlayerImmediate)] ()
    respawner__enabled = false
    respawner__respStartTime = -1.f
    respawner__respEndTime = -1.f
    respawner__canRespawnTime = -1.f
    respawner__canRespawnWaitNumber = -1
    respawner__respTime = 0.0
    respawner__canSpawnMinTime = 0.0
    respawner__missionStartDelay = 0.0
    isFirstSpawn = false
    return true

