from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {soundOutputDevice, soundOutputDeviceUpdate,
  soundOutputDevicesList, soundOutputDevicesListUpdate,
  soundRecordDevice, soundRecordDeviceUpdate,
  soundRecordDevicesList, soundRecordDevicesListUpdate
} = require("%enlSqGlob/sound_state.nut")

let {startsWith} = require("%sqstd/string.nut")
let {sound_set_callbacks, sound_get_output_devices, sound_get_record_devices, sound_set_output_device} = require("%dngscripts/sound_system.nut")

let function findBestOutputDevice(devs_list) {
  return devs_list?[0] // first device in list is a device choosen by system as default
}

let function findBestRecordDevice(devs_list) {
  let filterfunc = function(d) {
    // add various rules here for inapropriate devices for sound recording
    // on different platforms
    return !startsWith(d.name, "Monitor of") // monitor device is a loopback from output in pulseaudio
  }
  let suitable = devs_list.filter(filterfunc)
  return suitable?[0] ?? devs_list?[0]
}

let function get_output_devices() {
  let sysDevs = sound_get_output_devices()
  if (sysDevs.len() > 0)
    return sysDevs
  return [{
    name = "No Output"
    id = -1
  }]
}

let function get_record_devices() {
  let sysDevs = sound_get_record_devices()
  if (sysDevs.len() > 0)
    return sysDevs
  return [{
    name = "No Record"
    id = -1
  }]
}


if (soundOutputDevicesList.value.len() == 0)
  soundOutputDevicesListUpdate(get_output_devices())

if (soundRecordDevicesList.value.len() == 0)
  soundRecordDevicesListUpdate(get_record_devices())


let function isDeviceInList(dev, devs_list) {
  if (dev == null)
    return false
  foreach (d in devs_list)
    if (d.name == dev?.name && d.id == dev?.id)
      return true
  return false
}

soundOutputDevice.subscribe(function(dev) {
  log($"[sound] set output device {dev?.name}")
  sound_set_output_device(dev ? dev.id: 0)
})

soundRecordDevice.subscribe(function(dev) {
  log($"[sound] set record device {dev?.name}")
})

soundOutputDevicesList.subscribe(function(dlist) {
  log(dlist)
})

soundRecordDevicesList.subscribe(function(dlist) {
  log(dlist)
})

if (soundOutputDevice.value == null) {
  local dev = get_setting_by_blk_path("sound/output_device")
  if (!isDeviceInList(dev, soundOutputDevicesList.value))
    dev = findBestOutputDevice(soundOutputDevicesList.value)
  soundOutputDeviceUpdate(dev)

}

if (soundRecordDevice.value == null) {
  local dev = get_setting_by_blk_path("sound/record_device")
  if (!isDeviceInList(dev, soundRecordDevicesList.value))
    dev = findBestRecordDevice(soundRecordDevicesList.value)
  soundRecordDeviceUpdate(dev)
}

sound_set_callbacks({
  function on_record_devices_list_changed() {
    soundRecordDevicesListUpdate(get_record_devices())
    if (!isDeviceInList(soundRecordDevice.value, soundRecordDevicesList.value))
      soundRecordDeviceUpdate(findBestRecordDevice(soundRecordDevicesList.value))
  }

  function on_output_devices_list_changed() {
    soundOutputDevicesListUpdate(get_output_devices())
    if (!isDeviceInList(soundOutputDevice.value, soundOutputDevicesList.value))
      soundOutputDeviceUpdate(findBestOutputDevice(soundOutputDevicesList.value))
  }
})
