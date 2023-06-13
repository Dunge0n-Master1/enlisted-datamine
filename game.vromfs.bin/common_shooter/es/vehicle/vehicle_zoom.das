require ecs
require ecs.safe
require math.base
require vehicle
require enlisted.events_enlisted

let DEFAULT_ZOOM_TIME = 0.2

def set_cockpit_zoom(cockpit__eid : EntityId;
                     dt : float;
                     var camera__magnification : float&;
                     var camera__zoomPos : float&)
  var isFound = false
  query(cockpit__eid) <| $ [es] (cockpit__slitZoom : Array;
                                 cockpit__slitZoomTime : FloatList;
                                 cockpit__currentSlit : int;
                                 cockpit__isZoom : bool)
    let slitZoom = cockpit__slitZoom?[cockpit__currentSlit]
    let time = cockpit__slitZoomTime?[cockpit__currentSlit] ?? DEFAULT_ZOOM_TIME
    if slitZoom != null
      let zoomLevels = get_ecs_FloatList(*slitZoom)
      if zoomLevels != null && !empty(*zoomLevels)
        let zoomTargetPos = cockpit__isZoom ? 1.0 : 0.0
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

def set_turret_zoom(turret_control__gunEids : EidList;
                    dt : float;
                    camera_type : int;
                    cockpit__zoomOutFov : float const?;
                    cockpit__zoomInFov : float const?;
                    var camera__magnification : float&;
                    var camera__zoomPos : float&)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstTurretInput))] (turret_input__minZoom : float;
                                                                         turret_input__maxZoom : float;
                                                                         turret_input__isZoom : bool)
      let isZoom = turret_input__isZoom
      let zoomOutFov = cockpit__zoomOutFov ?? turret_input__minZoom
      let zoomInFov = cockpit__zoomInFov ?? turret_input__maxZoom
      let zoomPos = move_to(camera__zoomPos, isZoom ? 1.0 : 0.0, dt, 5.0)
      let zoom = (int(VehicleCameraType VEHICLE_CAMERA_GUNNER) == camera_type ?
        lerp(zoomOutFov, zoomInFov, zoomPos) :
        lerp(turret_input__minZoom, turret_input__maxZoom, zoomPos))
      camera__magnification = zoom
      camera__zoomPos = zoomPos

[es(tag=gameClient, REQUIRE=heroVehicle, before=shooter_cam_update_tm_es, after=human_optics_camera_es)]
def turret_zoom_es(info : ParallelUpdateFrameDelayed;
                   turret_control__gunEids : EidList;
                   vehicleCameraType : int;
                   cockpit__eid : EntityId;
                   cockpit__zoomOutFov : float const?;
                   cockpit__zoomInFov : float const?)
  let dt = info.dt
  query() <| $ [es] (camera__target : EntityId)
    query(camera__target) <| $ [es] (human_vehicle__isInHatch : bool = false;
                                     human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                                     human_vehicle__isHoldingGunPassenger : bool = false;
                                     var camera__magnification : float&;
                                     var camera__zoomPos : float&)
      var isSet = false
      if !human_vehicle__isInHatch
        isSet = set_cockpit_zoom(cockpit__eid, dt, camera__magnification, camera__zoomPos)
      if !isSet
        let human_gun_attached = get_bool(human_weap__currentGunEid, "human_gun_attached") ?? false
        if !human_gun_attached && !human_vehicle__isHoldingGunPassenger
          set_turret_zoom(turret_control__gunEids, dt, vehicleCameraType, cockpit__zoomOutFov, cockpit__zoomInFov, camera__magnification, camera__zoomPos)
      query(cockpit__eid) <| $ [es] (cockpit__forwardOffsetTime : float; cockpit__cameraTime : float)
        if cockpit__cameraTime < 1. && cockpit__cameraTime > 0.
          camera__magnification = 1.0
        elif cockpit__forwardOffsetTime < 1.0
          camera__magnification = lerp(1.0, camera__magnification, cockpit__forwardOffsetTime)
