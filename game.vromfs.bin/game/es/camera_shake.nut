import "%dngscripts/ecs.nut" as ecs
let {get_setting_by_blk_path} = require("settings")
let {cameraShakeOptions, cameraShakeComps} = require("%enlSqGlob/camera_shake_options.nut")

let function setCameraShakeSettings(_evt, _eid, comp) {
  foreach (option in cameraShakeOptions)
    comp[option.compName] = get_setting_by_blk_path(option.blkPath) ?? comp[option.compName]
}

ecs.register_es("camera_shake_settings_ui_es", {onInit = setCameraShakeSettings}, {comps_rw = cameraShakeComps}, {tags = "gameClient"})
