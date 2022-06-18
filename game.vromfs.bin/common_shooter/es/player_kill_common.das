module player_kill_common shared

require DagorSystem
require ecs
require EnlistedDm
require game.es.player_common
require GameTimers

def kill_player(player_eid : EntityId) : void
  let found : bool = query(player_eid) <| $ [es(REQUIRE=player)] (possessed : EntityId)
    print("Killing player {int(uint(player_eid))} possessed entity {int(uint(possessed))}")
    let ddesc = DamageDesc(DamageType DM_DISCONNECTED, FLT_MAX, float3())
    apply_damage(possessed, possessed, ddesc);
  if !found
    logwarn("Can't find entity possessed by player {int(uint(player_eid))}")

def kill_player_by_timeout(player_eid : EntityId; var kill_timer_handler : uint64&) : void
  let timeout : float = game_params_get_timer("keepAlivePlayerlessSquadTimeSec", 120.f)
  if timeout > 0.f
    let timeoutCb <- @ <| ()
      kill_player(player_eid)
    game_timer_clear(kill_timer_handler)
    kill_timer_handler = game_timer_set(timeoutCb, timeout)
