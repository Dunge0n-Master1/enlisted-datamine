require ecs
require game.events_game
require game.utils.net_utils
require DngNet
require common_shooter.events_common_shooter
require DngDm

[es(tag=server)]
def entity_killed_by_headshot(evt : EventEntityKilledToPart;
                              eid : EntityId;
                              dm_parts__type : StringList)
  let hitHead = uint(evt.collNodeId) < uint(length(dm_parts__type)) && dm_parts__type[evt.collNodeId] == "head"
  if evt.damageType == int(DamageType DM_PROJECTILE) && hitHead
    let forceDisabled = find_query() <| $ [es(REQUIRE=forceDisableHeadShotSound)] () => true
    if forceDisabled
      return
    send_net_event(eid, [[EventHeadShotKill]], possessed_and_spectated(eid))
