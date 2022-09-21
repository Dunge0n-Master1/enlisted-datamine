let { register_for_devices_change, DeviceType } = require("%xboxLib/impl/input.nut")
let { controllerDisconnectedUpdate } = require("%enlSqGlob/controllerDisconnected.nut")


register_for_devices_change(function(device_type, count) {
  if (device_type == DeviceType.Gamepad) {
    controllerDisconnectedUpdate(count == 0)
  }
})