options no_aot
require ecs
require app

def try_apply_bench_mode()
  let isBenchmark = find_query() <| $ [es(REQUIRE=benchmark_name)] () => true
  if !isBenchmark
    return
  query() <| $ [es] (var bot_spawner__allowSpawnBeforePlayer : bool&)
    bot_spawner__allowSpawnBeforePlayer = true
  query() <| $ [es(REQUIRE=player, REQUIRE_NOT=playerIsBot)] (var respawner__respTime : float&;
                                                              var respawner__respawnWhenInactiveTimeout : float&;
                                                              var respawner__canSpawnMinTime : float&;
                                                              var respawner__missionStartDelay : float&)
    respawner__respTime = 0.0
    respawner__respawnWhenInactiveTimeout = 60000.0
    respawner__canSpawnMinTime = 0.0
    respawner__missionStartDelay = 0.0

[es(on_appear, REQUIRE=benchmark_name)]
def apply_bench_mode_on_bench_creation(evt : Event)
  try_apply_bench_mode()

[es(on_appear, REQUIRE=bot_spawner__allowSpawnBeforePlayer)]
def check_bench_mode_on_spawner_creation(evt : Event)
  try_apply_bench_mode()

[es(on_appear, REQUIRE=player, REQUIRE_NOT=playerIsBot)]
def check_bench_mode_on_player_creation(evt : Event)
  try_apply_bench_mode()
