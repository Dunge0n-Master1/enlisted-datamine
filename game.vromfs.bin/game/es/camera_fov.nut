import "%dngscripts/ecs.nut" as ecs
let dgs_get_settings = require("dagor.system").dgs_get_settings

let function setFov(_eid, comp) {
  let fovSettingsPath = comp["camera__fovSettingsPath"]
  comp.fovSettings = clamp(dgs_get_settings()?.gameplay[fovSettingsPath] ?? comp.fovSettings, comp.fovLimits.x, comp.fovLimits.y)
}

ecs.register_es("camera_fov_es", { onInit = setFov },
{
  comps_rw = [ ["fovSettings", ecs.TYPE_FLOAT] ],
  comps_ro = [["fovLimits", ecs.TYPE_POINT2], ["camera__fovSettingsPath", ecs.TYPE_STRING]] },
{tags = "gameClient"})

