let sharedWatched = require("%dngscripts/sharedWatched.nut")

let state = {
  outputDevicesList = []
  recordDevicesList = []
  outputDevice = null
  recordDevice = null
}.map(@(value, name) sharedWatched($"sound.{name}", @() value))

return {
  outputDevicesList = state.outputDevicesList
  recordDevicesList = state.recordDevicesList
  outputDevice = state.outputDevice
  recordDevice = state.recordDevice
}
