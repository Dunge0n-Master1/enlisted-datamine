from "%enlSqGlob/ui_library.nut" import *

let { sound_set_volume, sound_play } = require("sound")

console_register_command(function(name) {sound_play(name)}, "sound.play")
foreach (opt in ["MASTER","ambient","weapon","effects","voices","interface","music"]) {
  let capOpt = opt
  console_register_command(function(val) {sound_set_volume(capOpt, val)}, $"sound.set_volume_{opt}")
}
console_register_command(function(val) {sound_set_volume("MASTER", val)}, "sound.set_volume")
