module teleport_common shared
require ecs
require EnlistedActor
require DagorSystem
require game.es.server_debug_common
require EnlistedNet

def teleport_eid_to(eid : EntityId; pos : float3; use_camera_pos : bool = false)
  var targetTm : float3x4
  let heroTm = get_TMatrix(eid, "transform")
  let hasCamera = find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      identity(targetTm)
      targetTm[0] = normalize(cross(float3(0.f, -1.f, 0.f), transform[0]))
      targetTm[2] = normalize(cross(transform[2], float3(0.f, 1.f, 0.f)))
      targetTm[3] = use_camera_pos ? transform[3] : pos
    return camera__active
  if !hasCamera && heroTm != null
    targetTm = *heroTm
    if !use_camera_pos
      targetTm[3] = pos
  elif !hasCamera
    logerr("Failed to get any transform")
    return
  teleport_phys_actor(eid, targetTm)


def teleport_or_request(eid : EntityId; pos : float3)
  if is_server()
    teleport_eid_to(eid, pos, false)
  else
    exec_server_cmd("phys.teleport {pos.x} {pos.y} {pos.z} :hero:")
