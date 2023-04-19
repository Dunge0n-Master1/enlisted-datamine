require ecs
require ecs.safe
require app
require soundHash
require vehicle_sounds_net.modules.vehicle_sounds_net_events
require game.es.events
require game.es.vehicle.vehicle_events
require game.utils.net_utils
require dm
require DngDm
require common_shooter.events_common_shooter
require DagorMath
require DngNet


[es(tag=server)]
def vehicle_damage_net_sound_part_damaged(evt : EventOnPartDamaged; eid : EntityId;
                                          isExploded : bool;
                                          var vehicle_damage_net_sound__nextTime : float&;
                                          vehicle_damage_net_sound__cooldown : float)
  if !isExploded
    let hpFixed = int(evt.hpFixed)
    let prevHpFixed = int(evt.prevHpFixed)
    if prevHpFixed > hpFixed
      if hpFixed > 0
        if int(evt.hitData.shellId) >= 0
          let curTime = get_sync_time()
          if curTime >= vehicle_damage_net_sound__nextTime
            vehicle_damage_net_sound__nextTime = curTime + vehicle_damage_net_sound__cooldown
            let relHp = safediv(float(prevHpFixed - hpFixed), float(MAX_REL_HP_FIXED))
            send_net_event(eid, [[CmdPlayVehicleDamageSound hash=sound_hash("partDamage"), relHp=relHp, time=curTime]], enum_connections_vehicle(eid))
      else
        send_net_event(eid, [[CmdPlayVehicleDamageSound hash=sound_hash("partDestroy"), time=get_sync_time()]])


[es(tag=server)]
def vehicle_damage_net_sound_volumetric_damage_es(evt : EventOnVolumetricDamage; eid : EntityId;
                                                  isExploded : bool)
  if !isExploded
    for it in evt.damagedParts
      let part = it as Object
      let hpFixed = int(part?.hpFixed ?? uint16(0))
      let prevHpFixed = int(part?.prevHpFixed ?? uint16(0))
      if prevHpFixed > hpFixed
        if hpFixed == 0
          send_net_event(eid, [[CmdPlayVehicleDamageSound hash=sound_hash("partDestroyByFire"), time=get_sync_time()]])
