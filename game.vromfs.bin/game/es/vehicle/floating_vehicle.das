require ecs
require app
require vehicle
require GamePhys
require DagorMath


[es(on_appear, REQUIRE=vehicle_net_phys__floatable)]
def floating_vehicle_on_appear(evt : Event;
                               floatable_vehicle__floatingVolumesOffset : float3;
                               var vehicle_net_phys : VehiclePhysActor)
  for volume in vehicle_net_phys.phys.volumes.floatingVolumes
    volume.c += floatable_vehicle__floatingVolumesOffset


[es(tag=server, on_appear, REQUIRE=(vehicle_net_phys__floatable, deadEntity))]
def floating_vehicle_start_flooding(evt : Event;
                                    vehicle_net_phys : VehiclePhysActor;
                                    floatable_vehicle__floodingDelay : float;
                                    var floatable_vehicle__initialFloatingVolumes : FloatList&;
                                    var floatable_vehicle__floodingStartTime : float&)
  reserve(floatable_vehicle__initialFloatingVolumes, length(vehicle_net_phys.phys.volumes.floatingVolumes))
  for volume in vehicle_net_phys.phys.volumes.floatingVolumes
    push(floatable_vehicle__initialFloatingVolumes, volume.r)

  floatable_vehicle__floodingStartTime = get_sync_time() + floatable_vehicle__floodingDelay


[es(tag=server, no_order, REQUIRE=(vehicle_net_phys__floatable, deadEntity))]
def floating_vehicle_update_flooding(info : UpdateStageInfoAct;
                                     floatable_vehicle__floodingSpeed : float;
                                     floatable_vehicle__floodingStartTime : float;
                                     floatable_vehicle__initialFloatingVolumes : FloatList;
                                     var floatable_vehicle__floatingVolumeScale : float&;
                                     var vehicle_net_phys : VehiclePhysActor&)
  assume radiusScale = floatable_vehicle__floatingVolumeScale
  assume floatingVolumes = vehicle_net_phys.phys.volumes.floatingVolumes
  assume initialFloatingVolumes = floatable_vehicle__initialFloatingVolumes

  if floatable_vehicle__floodingStartTime < 0.0 || info.curTime < floatable_vehicle__floodingStartTime || radiusScale <= 0.0
    return

  radiusScale = max(radiusScale - floatable_vehicle__floodingSpeed * info.dt, 0.0)

  for volume, initialVolume in floatingVolumes, initialFloatingVolumes
    volume.r = initialVolume * radiusScale
    volume.r2 = volume.r * volume.r

