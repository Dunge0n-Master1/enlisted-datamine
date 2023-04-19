from "%enlSqGlob/ui_library.nut" import *

let { sound_set_volume } = require("%dngscripts/sound_system.nut")

foreach (opt in ["MASTER","ambient","weapon","effects","voices","interface","music"]) {
  let capOpt = opt
  console_register_command(function(val) {sound_set_volume(capOpt, val)}, $"sound.set_volume_{opt}")
}
console_register_command(function(val) {sound_set_volume("MASTER", val)}, "sound.set_volume")
