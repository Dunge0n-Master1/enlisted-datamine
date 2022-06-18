require ecs
require app
require math
require DagorMath
require DagorRandom
require Dacoll
require game.es.events

[es(tag=server, on_appear)]
def artillery_player_init_es(evt : Event;
                             artillery__baseInterval : float;
                             artillery__baseSpawnDelay : float;
                             var artillery__spawnDelay : float&;
                             var artillery__interval : float&)
  artillery__interval = artillery__baseInterval
  artillery__spawnDelay = artillery__baseSpawnDelay

[es(tag=server, after=init_squad_unlocks, on_appear)]
def artillery_squad_init_es(evt : Event;
                            squad__artilleryTimersMulUnlock : float;
                            squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (artillery__baseInterval : float;
                                       artillery__lastShotInTime : float;
                                       artillery__baseSpawnDelay : float;
                                       artillery__missionStartDelay : float;
                                       var artillery__spawnDelay : float&;
                                       var artillery__availableAtTime : float&;
                                       var artillery__interval : float&)
    var missionStartCooldownEndTime = -1.0
    query() <| $ [es] (firstPlayerSpawnTime : float)
      missionStartCooldownEndTime = firstPlayerSpawnTime + artillery__missionStartDelay

    artillery__interval = artillery__baseInterval * squad__artilleryTimersMulUnlock
    artillery__spawnDelay = artillery__baseSpawnDelay * squad__artilleryTimersMulUnlock
    let spawnCooldownEndTime = get_sync_time() + artillery__spawnDelay
    let cooldownEndTime = max(missionStartCooldownEndTime, spawnCooldownEndTime)
    artillery__availableAtTime = (artillery__lastShotInTime < 0.f ? cooldownEndTime :
                                    max(cooldownEndTime, artillery__lastShotInTime + artillery__interval))