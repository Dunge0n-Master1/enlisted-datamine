require ecs
require EnlistedHuman
require EnlistedActor
require HumanPhys
require EnlistedNet
require game.utils.net_utils

[es(tag=server, REQUIRE=player, no_order)]
def afk(info : UpdateStageInfoAct;
        eid : EntityId;
        possessed : EntityId;
        userid : uint64;
        connid : int;
        disconnected : bool;
        afk__disconnectTimeout : float;
        var afk__packedState : int&;
        var afk__walkPacked : int&;
        var afk__wishLookDirPacked : int&;
        var afk__wishShootDirPacked : int&;
        var afk__time : float&)
  if afk__disconnectTimeout <= 0.0f
    return

  if !possessed
    afk__time = 0.0f
    return

  query(possessed) <| $ [es] (human_net_phys : HumanActor?; human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID; isAlive : bool = false)
    if human_net_phys == null || (*human_net_phys).role != NetRole ROLE_REMOTELY_CONTROLLED_AUTHORITY || !isAlive || has(human_anim__vehicleSelected, "airplane")
      afk__time = 0.0f
      return

    var conn = get_client_connection(connid)
    if conn == null || disconnected
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

    if conn != null && afk__time > afk__disconnectTimeout
      print("[AFK]: Kick player {eid} with userId {int(userid)} after idle {afk__time} sec")
      net_disconnect(*conn, DisconnectionCause DC_KICK_INACTIVITY)
