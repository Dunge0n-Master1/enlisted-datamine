require ecs
require EnlistedNet
require game.utils.net_utils
require vehicle
require EnlistedWeapon
require DagorMathUtils
require common_shooter.events_common_shooter
require common_shooter.es.weapon.turret_common

// Sync turret angles for special case: the player owns a vehicles connection - the player will receive AAS and not shapshots (turret angles goes by snapshots)
// Send turret angels for such players

[es(tag=netClient)]
def turret_sync_apply_shoot_angles_es(evt : CmdSyncTurretShootAngles; net_phys__currentStatePosition : float3)
  let shootFromPos = net_phys__currentStatePosition + float3(0., 2., 0.)
  query(evt.turretEid) <| $ [es] (var turret_aim__shootAngles : float2&;
                                  var turret_aim__shootToPos : float3&)
    turret_aim__shootAngles = evt.shootAngles
    turret_aim__shootToPos  = shootFromPos + angles_to_dir(turret_aim__shootAngles) * AIM_DISTANCE


def find_vehicle_connection_owners_seat(seatEids; replication)
  let controlledByConnId = replication != null ? net_object_getControlledBy(*replication) : INVALID_CONNECTION_ID

  var ownerSeatEid = INVALID_ENTITY_ID
  for seatEid in seatEids
    if !!ownerSeatEid
      break

    query(seatEid) <| $ [es] (seat__isPlayer : bool; seat__playerEid : EntityId)
      if !seat__isPlayer
        return

      // Send the message to player that own a vehicle.
      // Such players won't recevie snapshots (turret angles goes by snapshots)
      let connid = get_int(seat__playerEid, "connid") ?? INVALID_CONNECTION_ID
      if controlledByConnId != INVALID_CONNECTION_ID && controlledByConnId == connid
        ownerSeatEid = seatEid

  return ownerSeatEid

[es(tag=server, no_order)]
def turret_sync_shoot_angles_es(info : UpdateStageInfoAct;
                                eid : EntityId;
                                turret_control__gunEids : EidList;
                                vehicle_seats__seatEids : EidList;
                                turret_aim_sync__interval : float;
                                replication : NetObject const?;
                                var turret_aim_sync__nextSyncAtTime : float&)
  if turret_aim_sync__nextSyncAtTime > info.curTime
    return

  turret_aim_sync__nextSyncAtTime = info.curTime + turret_aim_sync__interval

  let vehicleEid = eid
  let seatEid = find_vehicle_connection_owners_seat(vehicle_seats__seatEids, replication)
  query(seatEid) <| $ [es] (seat__ownerControls : VehicleControlsState)
    for turretEid in turret_control__gunEids
      query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (eid : EntityId;
                                                          turret__id : int;
                                                          turret_aim__shootAngles : float2;
                                                          var turret_aim_sync__prevShootAngles : float2&)
        if !can_control_turret(seat__ownerControls, turret__id) && turret_aim__shootAngles != turret_aim_sync__prevShootAngles
          turret_aim_sync__prevShootAngles = turret_aim__shootAngles
          sendEvent(vehicleEid, [[CmdSyncTurretShootAngles turretEid=eid, shootAngles=turret_aim__shootAngles]])
