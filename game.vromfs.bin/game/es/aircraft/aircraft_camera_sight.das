require ecs
require math
require math.base
require DngPlane
require DagorMath
require GamePhys
require AnimV20
require GeomNodeTree

def set_look_max_zoom(turret_control__gunEids : EidList; var gunmod__lookMaxZoom : float&)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstTurretInput))] (turret_input__maxZoom : float)
      gunmod__lookMaxZoom = turret_input__maxZoom

[es(on_appear)]
def plane_telesight_init(evt : Event;
                         animchar : AnimcharBaseComponent&;
                         cockpit__vehicleEid : EntityId;
                         cockpit__seatNo : int;
                         gunmod__lensNode : string;
                         gunmod__telesightOffset : float3;
                         var gunmod__defaultMouseAimLimits : float2&;
                         var gunmod__lookMaxZoom : float&;
                         var gunmod__cameraOffset : float3&)
  query(cockpit__vehicleEid) <| $ [es] (vehicle_seats__seatEids : EidList;
                                        turret_control__gunEids : EidList;
                                        plane_input__mouseAimLimitYaw : float;
                                        plane_input__mouseAimLimitPitch : float)
    let initialHeadPos = get_Point3(vehicle_seats__seatEids[cockpit__seatNo], "seat__cameraPos") ?? float3()

    var rootTm : float3x4
    let gunmod__sightNodeId = *animchar.nodeTree |> geomtree_findNodeIndex(gunmod__lensNode)
    *animchar.nodeTree |> geomtree_getNodeWtmRelScalar(0, rootTm)
    let invRootTm = inverse(rootTm)
    let lensPosRel = *animchar.nodeTree |> geomtree_getNodeWposRel(gunmod__sightNodeId)
    let lensPosLocal = invRootTm * lensPosRel
    gunmod__cameraOffset = lensPosLocal - initialHeadPos + gunmod__telesightOffset
    gunmod__defaultMouseAimLimits = float2(plane_input__mouseAimLimitYaw, plane_input__mouseAimLimitPitch)
    set_look_max_zoom(turret_control__gunEids, gunmod__lookMaxZoom)

[es(on_disappear)]
def plane_telesight_disappear(evt : Event;
                              cockpit__vehicleEid : EntityId;
                              gunmod__defaultMouseAimLimits : float2;
                              var gunmod__isZoom : bool&)
  query(cockpit__vehicleEid) <| $ [es] (var plane_input__mouseAimLimitYaw : float&;
                                        var plane_input__mouseAimLimitPitch : float&)
    gunmod__isZoom = false
    plane_input__mouseAimLimitYaw = gunmod__defaultMouseAimLimits.x
    plane_input__mouseAimLimitPitch = gunmod__defaultMouseAimLimits.y

[es(tag=render, before=before_camera_sync, after=animchar_cam_target_with_offset_es)]
def plane_move_to_sight_update(info : UpdateStageInfoAct;
                               cockpit__eid : EntityId;
                               plane_net_phys : PlaneActor;
                               plane_input : PlaneInput;
                               var camera__lookDir : float3&;
                               var camera__look_at : DPoint3&;
                               var camera__magnification : float&)
  query(cockpit__eid) <| $ [es] (transform : float3x4;
                                 gunmod__cameraOffset : float3;
                                 gunmod__isZoom : bool;
                                 gunmod__zoomTime : float;
                                 gunmod__minZoom : float;
                                 gunmod__maxZoom : float;
                                 gunmod__lookMaxZoom : float = 2.0f;
                                 gunmod__cameraStabilizationMult : float = 0.95;
                                 var gunmod__zoomPos : float&;
                                 var gunmod__cameraPos : float&)
    let zoomTargetPos = gunmod__isZoom ? 1.0f : 0.0f
    let cameraTargetPos = gunmod__isZoom && !plane_input.mouseAimEnabledBlocked ? 1.0f : 0.0f

    gunmod__zoomPos = move_to(gunmod__zoomPos, zoomTargetPos, info.dt, safeinv(gunmod__zoomTime))
    gunmod__cameraPos = move_to(gunmod__cameraPos, cameraTargetPos, info.dt, safeinv(gunmod__zoomTime))
    let wishPos = rotate(transform, gunmod__cameraOffset)
    camera__look_at += lerp(DPoint3(0.lf, 0.lf, 0.lf), DPoint3(wishPos), gunmod__cameraPos)

    let forwardDir = plane_net_phys.phys.visualLocation.O.quat |> quat_get_forward()
    let lookDirLerpFactor = float3(gunmod__cameraPos * gunmod__cameraStabilizationMult)
    camera__lookDir = lerp(camera__lookDir, forwardDir, lookDirLerpFactor)

    let maxZoom = lerp(gunmod__lookMaxZoom, gunmod__maxZoom, gunmod__cameraPos)
    let zoom = lerp(gunmod__minZoom, maxZoom, gunmod__zoomPos)
    camera__magnification = zoom
