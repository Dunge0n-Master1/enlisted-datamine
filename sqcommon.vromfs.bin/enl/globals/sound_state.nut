let {globalWatched} = require("%dngscripts/globalState.nut")

let {soundOutputDevicesList, soundOutputDevicesListUpdate} = globalWatched("soundOutputDevicesList", @() [])
let {soundRecordDevicesList, soundRecordDevicesListUpdate} = globalWatched("soundRecordDevicesList", @() [])
let {soundOutputDevice, soundOutputDeviceUpdate} = globalWatched("soundOutputDevice")
let {soundRecordDevice, soundRecordDeviceUpdate} = globalWatched("soundRecordDevice")

return {
  soundOutputDevicesList, soundOutputDevicesListUpdate,
  soundRecordDevicesList, soundRecordDevicesListUpdate,
  soundOutputDevice, soundOutputDeviceUpdate,
  soundRecordDevice, soundRecordDeviceUpdate
}
