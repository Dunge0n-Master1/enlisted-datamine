require ecs
require app
require soundHash
require vehicle_sounds_net.modules.vehicle_sounds_net_events
require game.es.events
require game.es.vehicle.vehicle_events
require dm
require common_shooter.events_common_shooter
require EnlistedNet

[es(tag=server, REQUIRE=vehicle_net_sound)]
def vehicle_damage_net_sound_part_damaged(evt : EventOnPartDamaged; eid : EntityId;
                                          isExploded : bool)
  if !isExploded
    let hpFixed = int(evt.hpFixed)
    let prevHpFixed = int(evt.prevHpFixed)
    if hpFixed == 0 && prevHpFixed > hpFixed
      send_net_event(eid, [[CmdPlayVehicleDamageSound hash=sound_hash("partDestroy"), time=get_sync_time()]])

[es(tag=server, REQUIRE=vehicle_net_sound)]
def vehicle_damage_net_sound_volumetric_damage_es(evt : EventOnVolumetricDamage; eid : EntityId;
                                                  isExploded : bool)
  if !isExploded
    for partIt in evt.damagedParts
      let part = get_ecs_object(partIt)
      let hpFixed = int(get_uint16(part, "hpFixed") ?? uint16(0))
      let prevHpFixed = int(get_uint16(part, "prevHpFixed") ?? uint16(0))
      if hpFixed == 0 && prevHpFixed > hpFixed
        send_net_event(eid, [[CmdPlayVehicleDamageSound hash=sound_hash("partFire"), time=get_sync_time()]])
