require ecs
require EnlistedHuman
require EnlistedActor
require HumanPhys
require EnlistedNet
require game.utils.net_utils

[es(tag=server, track=possessed, REQUIRE=possessed)]
def reset_afk_timer_on_possess(evt : Event; var afk__time : float&)
  afk__time = 0.

[es(tag=server, REQUIRE=player, no_order)]
def afk(info : UpdateStageInfoAct;
        eid : EntityId;
        possessed : EntityId;
        userid : uint64;
        connid : int;
        disconnected : bool;
        respawner__enabled : bool;
        respawner__spectatorEnabled : bool;
        afk__disconnectTimeout : float;
        afk__respawnerDisconnectTimeout : float = 180.;
        var afk__packedState : int&;
        var afk__walkPacked : int&;
        var afk__wishLookDirPacked : int&;
        var afk__wishShootDirPacked : int&;
        var afk__time : float&)
  if afk__disconnectTimeout <= 0.0f
    return

  var conn = get_client_connection(connid)
  if conn == null || disconnected
    afk__time = 0.0f
    return

  if respawner__spectatorEnabled
    afk__time = 0.0f
    return

  var disconnectTimeout = afk__disconnectTimeout
  if respawner__enabled
    disconnectTimeout = afk__respawnerDisconnectTimeout
    afk__time += info.dt

  query(possessed) <| $ [es(REQUIRE_NOT=deadEntity)] (human_net_phys : HumanActor const?; human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID)
    if human_net_phys == null || (*human_net_phys).role != NetRole ROLE_REMOTELY_CONTROLLED_AUTHORITY || has(human_anim__vehicleSelected, "airplane")
      afk__time = 0.0f
      return

    assume ct = (*human_net_phys).phys.appliedCT
    if afk__packedState == int(ct.packedState) && afk__walkPacked == int(ct.walkPacked) && afk__wishLookDirPacked == int(ct.wishLookDirPacked) && afk__wishShootDirPacked == int(ct.wishShootDirPacked)
      afk__time += info.dt
    else
      afk__time = 0.0f

    afk__packedState = int(ct.packedState);
    afk__walkPacked = int(ct.walkPacked);
    afk__wishLookDirPacked = int(ct.wishLookDirPacked);
    afk__wishShootDirPacked = int(ct.wishShootDirPacked);

  if afk__time > disconnectTimeout
    print("[AFK]: Kick player {eid} with userId {int(userid)} after idle {afk__time} sec")
    net_disconnect(*conn, DisconnectionCause DC_KICK_INACTIVITY)
