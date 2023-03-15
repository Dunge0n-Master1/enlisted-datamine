require ecs
require app
require ecs.safe
require DagorSystem

def private set_squad_time(is_alive : bool; squad_id : string; var squad_stats : Object&)
  var squadStat = (squad_stats[squad_id] ?as Object)
  if squadStat == null
    logerr("squad stat isn't inited for '{squad_id}'")
    return

  if is_alive
    set(*squadStat, "spawnTime", get_sync_time())
  else
    let spawnTime = (squadStat?.spawnTime ?? -1.)
    if spawnTime > 0.
      set(*squadStat, "time", (squadStat?.time ?? 0.) + get_sync_time() - spawnTime)
    set(*squadStat, "spawnTime", -1.)

[es(tag=server, on_appear)]
def squad_stat_init_es(evt : Event; squad__squadProfileId : string; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var squadStats : Object&)
    if !has(squadStats, squad__squadProfileId)
      using() <| $(var empty : Object)
        squadStats |> set(squad__squadProfileId, empty)

[es(tag=server, track=disconnected, after=squad_stat_init_es)]
def squad_stat_on_player_disconnected_es(evt : Event; respawner__squad : EntityId; disconnected : bool; var squadStats : Object&)
  query(respawner__squad) <| $ [es] (squad__squadProfileId : string)
    set_squad_time(!disconnected, squad__squadProfileId, squadStats)

[es(tag=server, on_event=(CmdGetBattleResult, EventTeamRoundResult), before=(send_battle_result_es, get_battle_result_es))]
def squad_stat_on_round_result_es(evt : Event; squad__squadProfileId : string; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var squadStats : Object&)
    set_squad_time(false/*is_alive*/, squad__squadProfileId, squadStats)

[es(tag=server, on_appear, track=squad__isAlive, after=squad_stat_init_es)]
def squad_stat_on_die_es(evt : Event;
                         squad__squadProfileId : string;
                         squad__ownerPlayer : EntityId;
                         squad__isAlive : bool)
  query(squad__ownerPlayer) <| $ [es] (var squadStats : Object&)
    set_squad_time(squad__isAlive, squad__squadProfileId, squadStats)
