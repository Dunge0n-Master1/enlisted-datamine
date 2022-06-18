require ecs
require EnlistedNet
require player
require game.es.player_events
require game.events_game
require enlisted.events_enlisted

[es(tag=server)]
def player_replicate_default_on_connect(evt : CmdSpawnEntityForPlayer;
                                        eid : EntityId;
                                        var player__defaultNetScopeInited : bool&;
                                        var clientNetFlags : int&)
  if !player__defaultNetScopeInited
    player__defaultNetScopeInited = true
    if 0 == (clientNetFlags & int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS))
      clientNetFlags |= int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS)
      sendEventImmediate(eid, [[CmdAddDefaultEntitiesInNetScopeForPlayer]])