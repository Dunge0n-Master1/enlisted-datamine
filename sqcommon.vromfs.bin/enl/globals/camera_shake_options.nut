import "%dngscripts/ecs.nut" as ecs
let mkOption = @(compName, option) {
  compName
  blkPath = $"gameplay/{option}"
}

let cameraShakeOptions = [
  mkOption("camera_settings__shakePowerMult", "camera_shake_power")
]

let cameraShakeComps = cameraShakeOptions.map(@(value) [value.compName, ecs.TYPE_FLOAT])

return {
  cameraShakeOptions
  cameraShakeComps
}