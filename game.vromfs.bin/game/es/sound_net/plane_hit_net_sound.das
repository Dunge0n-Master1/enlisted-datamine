require ecs
require EnlistedNet
require game.utils.net_utils
require game.es.events
require game.es.sound_net.sound_net_events

[es(tag=server, REQUIRE=airplane)]
def plane_send_hit_sound_projectile(evt : EventOnHitByProjectile; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      send_net_event(seat__ownerEid, [[CmdPlayProjectileHitSound
        localHitPos = evt.localHitPos,
        localNormal = evt.localNormal,
        caliber = evt.caliber,
        bulletTypeId = evt.bulletTypeId,
        nodeId = evt.nodeId,
        pierced = evt.pierced
      ]], target_entity_conn(seat__ownerEid))

[es(tag=server, REQUIRE=airplane)]
def plane_send_ricochet_sound_projectile(evt : EventOnRicochet; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      send_net_event(seat__ownerEid, [[CmdPlayProjectileRicochetSound
        localHitPos = evt.localHitPos,
        caliber = evt.caliber
      ]], target_entity_conn(seat__ownerEid))
