require ecs
require DagorDataBlock
require DagorConsole
require DagorSystem



[event(broadcast)]
struct EventApplyDevMode {}


def private is_devmode_enabled_in_settings()
  return dgs_get_settings() |> datablock_get_block_by_name("debug") |> datablock_getBool("devmodeEnabled", false)


[es(REQUIRE=player)]
def apply_dev_mode_client_only(evt : EventApplyDevMode;
                               var respawner__respawnWhenInactiveTimeout : float&)
  respawner__respawnWhenInactiveTimeout = 60.0


[es(REQUIRE=player)]
def apply_dev_mode(evt : EventApplyDevMode;
                   var respawner__respTime : float&;
                   var respawner__canSpawnMinTime : float&;
                   var respawner__missionStartDelay : float&;
                   var artillery__baseInterval : float&;
                   var artillery__baseSpawnDelay : float&;
                   var artillery__missionStartDelay : float&;
                   var squads__revivePointsAfterDeath : int&;
                   var squads__suicideRate : float&;
                   var squads__suicideRateThresholdForPenalty : float&;
                   var squads__firstSpawnDelayByType : Object&)
  respawner__respTime = 0.0
  respawner__canSpawnMinTime = 0.0
  respawner__missionStartDelay = 0.0

  artillery__baseInterval = 0.0
  artillery__baseSpawnDelay = 0.0
  artillery__missionStartDelay = 0.0

  squads__revivePointsAfterDeath = 100

  squads__suicideRate = 0.0
  squads__suicideRateThresholdForPenalty = 999.0

  squads__firstSpawnDelayByType |> set("aircraft", 0.0)
  squads__firstSpawnDelayByType |> set("aircraft_fighter", 0.0)
  squads__firstSpawnDelayByType |> set("aircraft_assault", 0.0)


[console_cmd(name="sandbox.enable_devmode", hint="Removes different gamemplay cooldowns and limitations for easier testing.")]
def enable_devmode_cmd()
  broadcastEvent([[EventApplyDevMode]])


[es(on_appear, REQUIRE=player)]
def apply_devmode_on_player_creation(evt : Event)
  if is_devmode_enabled_in_settings()
    broadcastEvent([[EventApplyDevMode]])
