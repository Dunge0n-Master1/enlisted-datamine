require ecs
require DagorConsole

/**
 * Because scripts for tutorial load late,
 * we need this hack to apply fast spawn squad settings
**/
[es(tag=gameClient, on_appear, REQUIRE=player)]
def tutorial_pre_init_es(evt : Event;
                         var respawner__respTime : float&;
                         var respawner__canSpawnMinTime : float&;
                         var respawner__missionStartDelay : float&;
                         var respawner__respawnWhenInactiveTimeout : float&;
                         var respawner__respStartTime : float&;
                         var respawner__allowForceRespawn : bool&;
                         var squads__respawnPenaltyTime : float&;
                         var squads__revivePointsAfterDeath : int&;
                         var squads__firstSpawnDelayByType : Object&)
  find_query() <| $ [es(REQUIRE=isTutorial)] ()
    respawner__respTime = 0.0
    respawner__canSpawnMinTime = 0.0
    respawner__missionStartDelay = 0.0
    respawner__respStartTime = 0f
    respawner__respawnWhenInactiveTimeout = 0f
    respawner__allowForceRespawn = true

    squads__revivePointsAfterDeath = 100
    squads__respawnPenaltyTime = 0f

    squads__firstSpawnDelayByType |> set("aircraft", 0.0)
    squads__firstSpawnDelayByType |> set("aircraft_fighter", 0.0)
    squads__firstSpawnDelayByType |> set("aircraft_assault", 0.0)

    return true
