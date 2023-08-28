require ecs
require ecs.safe
require math.base
require vehicle
require enlisted.events_enlisted

let DEFAULT_ZOOM_TIME = 0.2

def set_cockpit_zoom(cockpit__eid : EntityId;
                     dt : float;
                     is_zoom : bool;
                     var camera__magnification : float&;
                     var camera__zoomPos : float&)
  var isFound = false
  query(cockpit__eid) <| $ [es] (cockpit__slitZoom : Array;
                                 cockpit__slitZoomTime : FloatList;
                                 cockpit__currentSlit : int)
    let slitZoom = cockpit__slitZoom?[cockpit__currentSlit]
    let time = cockpit__slitZoomTime?[cockpit__currentSlit] ?? DEFAULT_ZOOM_TIME
    if slitZoom != null
      let zoomLevels = get_ecs_FloatList(*slitZoom)
      if zoomLevels != null && !empty(*zoomLevels)
        let zoomTargetPos = is_zoom ? 1.0 : 0.0
        if time > VERY_SMALL_NUMBER
          camera__zoomPos = move_to(camera__zoomPos, zoomTargetPos, dt, 1.0 / time)
        else
          camera__zoomPos = zoomTargetPos
        let minZoom = (*zoomLevels)[0]
        let maxZoom = (*zoomLevels)?[1] ?? minZoom
        camera__magnification = lerp(minZoom, maxZoom, camera__zoomPos)
        isFound = true
        return
  return isFound

def set_zoom(dt : float;
             is_zoom : bool;
             zoom_out : float;
             zoom_in : float;
             zoom_speed : float;
             var camera__magnification : float&;
             var camera__zoomPos : float&)
  camera__zoomPos = move_to(camera__zoomPos, is_zoom ? 1.0 : 0.0, dt, zoom_speed)
  camera__magnification = lerp(zoom_out, zoom_in, camera__zoomPos)

def set_gunner_zoom(dt : float;
                    is_zoom : bool;
                    camera_type : int;
                    cockpit__zoomOutFov : float;
                    cockpit__zoomInFov : float;
                    cockpit__zoomSpeed : float;
                    var camera__magnification : float&;
                    var camera__zoomPos : float&)
  if int(VehicleCameraType VEHICLE_CAMERA_GUNNER) == camera_type
    set_zoom(dt, is_zoom, cockpit__zoomOutFov, cockpit__zoomInFov, cockpit__zoomSpeed, camera__magnification, camera__zoomPos)
    return true
  return false

[es(tag=gameClient, REQUIRE=heroVehicle, before=shooter_cam_update_tm_es, after=human_optics_camera_es)]
def vehicle_zoom(info : ParallelUpdateFrameDelayed;
                 vehicleCameraType : int;
                 vehicle_input__isZoom : bool;
                 cockpit__eid : EntityId;
                 vehicle_free_look__zoomSpeed : float = 5.;
                 vehicle_free_look__zoomOut : float = 1.;
                 vehicle_free_look__zoomIn : float = 1.3;
                 cockpit__zoomSpeed : float = 5.;
                 cockpit__zoomOutFov : float = 1.;
                 cockpit__zoomInFov : float = 2.)
  let dt = info.dt
  query() <| $ [es] (camera__target : EntityId)
    query(camera__target) <| $ [es] (human_vehicle__isInHatch : bool = false;
                                     human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                                     human_vehicle__isHoldingGunPassenger : bool = false;
                                     var camera__magnification : float&;
                                     var camera__zoomPos : float&)
      var isSet = false
      if !human_vehicle__isInHatch
        isSet = set_cockpit_zoom(cockpit__eid, dt, vehicle_input__isZoom, camera__magnification, camera__zoomPos)
      if !isSet
        isSet = set_gunner_zoom(dt, vehicle_input__isZoom, vehicleCameraType, cockpit__zoomOutFov, cockpit__zoomInFov, cockpit__zoomSpeed,
                                camera__magnification, camera__zoomPos)
      if !isSet
        let human_gun_attached = get_bool(human_weap__currentGunEid, "human_gun_attached") ?? false
        if !human_gun_attached && !human_vehicle__isHoldingGunPassenger
          set_zoom(dt, vehicle_input__isZoom, vehicle_free_look__zoomOut, vehicle_free_look__zoomIn, vehicle_free_look__zoomSpeed,
                   camera__magnification, camera__zoomPos)
      query(cockpit__eid) <| $ [es] (cockpit__forwardOffsetTime : float; cockpit__cameraTime : float)
        if cockpit__cameraTime < 1. && cockpit__cameraTime > 0.
          camera__magnification = 1.0
        elif cockpit__forwardOffsetTime < 1.0
          camera__magnification = lerp(1.0, camera__magnification, cockpit__forwardOffsetTime)
