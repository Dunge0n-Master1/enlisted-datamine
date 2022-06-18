require ecs
require EnlistedNet
require player
require math
require math.base
require DagorMath

[es(tag=server, track=scoring_player__friendlyFirePenalty, REQUIRE=player, REQUIRE_NOT=playerIsBot)]
def kick_player_for_friendly_fire_score(evt : Event;
                                        eid : EntityId;
                                        connid : int;
                                        squads__spawnCount : int;
                                        scoring_player__friendlyFirePenalty : int;
                                        friendly_fire__kickOnPenaltyScorePerSpawn : int;
                                        friendly_fire__minimumPenaltyToKick : int;
                                        name : string = "";
                                        var clientNetFlags : int&)
  if (squads__spawnCount > 0
      && scoring_player__friendlyFirePenalty <= -abs(friendly_fire__minimumPenaltyToKick)
      && scoring_player__friendlyFirePenalty <= -abs(friendly_fire__kickOnPenaltyScorePerSpawn) * squads__spawnCount)
    var conn = get_client_connection(connid)
    if conn != null
      clientNetFlags |= int(ClientNetFlags CNF_RECONNECT_FORBIDDEN)
      net_disconnect(*conn, DisconnectionCause DC_KICK_FRIENDLY_FIRE)
      print("[FriendlyFire] Player {name}[{eid}] was kicked for friendly fire. Penalty score {scoring_player__friendlyFirePenalty}")