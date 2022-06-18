options no_aot
require ecs
require DagorConsole
require EnlistedCamera
require game.utils.hero
require daslib/strings_boost
require game.es.client.spectator_common


[console_cmd(name="camera.spectate")]
def console_camera_spectate(target_id = 0u)
  let activeCam : EntityId = get_cur_cam_entity()
  let target : EntityId = EntityId(target_id)
  if !doesEntityExist(activeCam)
    console_print("no active camera found")
  elif !console_set_spectated(activeCam, target)
    let activeCamId = int(uint(activeCam))
    let targetId = int(uint(target))
    let targetName = getEntityTemplateName(target)
    console_print("set camera's {activeCamId} target to entity {targetId}<{targetName}> failed")
  elif !target
    bind_camera_to_entity(activeCam, get_controlled_hero())


def console_set_spectated(cam_eid : EntityId; target : EntityId) : bool
  if empty(getEntityTemplateName(cam_eid))
    return false
  let hasSpectator : bool = has(cam_eid, "spectator")
  if target == INVALID_ENTITY_ID // invalid target -> stop spectating
    if hasSpectator
      removeSubTemplate(cam_eid, "spectator")
    return true
  if !doesEntityExist(target) // bad target?
    return false
  if !hasSpectator // no spectator component -> create
    addSubTemplate(cam_eid, "spectator") <| $(var init : ComponentsInitializer)
      init |> set("spectator__target", target)
  else
    var spectatedEid : EntityId? = getRW_Eid(cam_eid, "spectator__target")
    assert(spectatedEid != null)
    set_spectated(cam_eid, *spectatedEid, target)
  return true
