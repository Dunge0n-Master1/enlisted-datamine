require ecs
require app
require math
require game.events_game

[es(tag=server, on_appear)]
def reset_squad_suicide_rate_on_squad_spawn(evt : Event; squad__ownerPlayer : ecs::EntityId)
  ecs::query(squad__ownerPlayer) <| $ [es] (var squads__suicideRate : float&;
                                            var squads__respawnPenaltyTime : float&;
                                            var squads__lastRespawnAtTime : float&)
    squads__lastRespawnAtTime = get_sync_time()
    squads__suicideRate = 0.f
    squads__respawnPenaltyTime = 0.f

def is_suicide(playerEid; evt : EventAnyEntityDied)
  return evt.offender == evt.victim || evt.offenderPlayer == playerEid

[es(tag=server, REQUIRE=player)]
def calc_squad_suicide_rate(evt : EventAnyEntityDied;
                            eid : EntityId;
                            var squads__suicideRate : float&;
                            var squads__respawnPenaltyTime : float&;
                            squads__lastRespawnAtTime : float;
                            squads__respawnPenaltyTimeThreshold : float;
                            squads__suicideRateThresholdForPenalty : float;
                            squads__botCount : int)
  let victimPlayer = get_Eid(evt.victim, "squad_member__playerEid") ?? INVALID_ENTITY_ID
  if victimPlayer != eid
    return

  let squadSize = float(squads__botCount + 1 /* leader */)
  let squadLifeTime = get_sync_time() - squads__lastRespawnAtTime
  if is_suicide(eid, evt)
    squads__suicideRate += 1.f / squadSize
  if squads__suicideRate >= squads__suicideRateThresholdForPenalty
    squads__respawnPenaltyTime = max(squads__respawnPenaltyTimeThreshold - squadLifeTime, 0.f)
