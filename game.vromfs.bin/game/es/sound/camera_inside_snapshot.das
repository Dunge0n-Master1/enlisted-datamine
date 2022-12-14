require ecs
require player
require vehicle
require soundEvent

def is_enable_snapshot(vehicle_eid : ecs::EntityId)
  var isEnable = false
  ecs::query(vehicle_eid) <| $ [es] (camera_inside_snapshot_enable : bool; camera_inside_snapshot_anyCameraType : bool = false; vehicleCameraType : int = 0)
    if camera_inside_snapshot_enable
      if camera_inside_snapshot_anyCameraType
        isEnable = true
      elif vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_NONE) && vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_COMMANDER)
        isEnable = true
  return isEnable

def snapshot_toggle(vehicle_eid : ecs::EntityId; camera_active : bool; bind_to_vehicle : bool; snapshot_name : string; isHeroCockpitCam : bool; var snapshot_event : SoundEvent&)
  let enable = bind_to_vehicle && camera_active && isHeroCockpitCam && is_enable_snapshot(vehicle_eid)
  if enable && !is_valid(snapshot_event.handle)
    snapshot_event |> play(snapshot_name)
  elif !enable && is_valid(snapshot_event.handle)
    abandon(snapshot_event.handle)


[es(tag=sound, track=camera__target, track=camera__active)]
def camera_inside_snapshot_toggle(evt : Event;
                                  camera__target : ecs::EntityId;
                                  camera__active : bool;
                                  bindToVehicle : bool;
                                  camera_inside_snapshot__path : string;
                                  var camera_inside_snapshot__event : SoundEvent&;
                                  isHeroCockpitCam = false;
                                  isPlaneCockpitCam = false)
  snapshot_toggle(camera__target, camera__active, bindToVehicle, camera_inside_snapshot__path, isHeroCockpitCam || isPlaneCockpitCam, camera_inside_snapshot__event)


[es(tag=sound, track=vehicleCameraType, REQUIRE=vehicleCameraType)]
def camera_inside_snapshot_camera_type(evt : Event)
  ecs::query() <| $ [es] (camera__target : ecs::EntityId;
                          camera__active : bool;
                          bindToVehicle : bool;
                          camera_inside_snapshot__path : string;
                          var camera_inside_snapshot__event : SoundEvent&;
                          isHeroCockpitCam = false;
                          isPlaneCockpitCam = false)
    snapshot_toggle(camera__target, camera__active, bindToVehicle, camera_inside_snapshot__path, isHeroCockpitCam || isPlaneCockpitCam, camera_inside_snapshot__event)
