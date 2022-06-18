from "%enlSqGlob/ui_library.nut" import *

let {h2_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {connectivity} = require("%ui/hud/state/network.nut")
let {sound_play} = require("sound")
let {CONNECTIVITY_OK, CONNECTIVITY_NO_PACKETS} = require("connectivity")

connectivity.subscribe(function(value) {
  if (value == CONNECTIVITY_NO_PACKETS)
    sound_play("ui/network_error")
})

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)
let msgDisrupted = freeze({
  rendObj = ROBJ_TEXT
  margin = fsh(1)
  text = loc("hud/NetworkDisrupted")
  color = Color(200,40,40,110)
  hplace = ALIGN_CENTER
  pos = [0, sh(15)]

  transform = {}

  animations = [
    { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
    { prop=AnimProp.scale, from=[1,1], to=[0,1], duration=0.25, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  ]
}.__update(h2_txt))

let function root() {
  return {
    key = "network-state"
    size = flex()
    watch = connectivity
    children = connectivity.value != CONNECTIVITY_OK ? msgDisrupted : null
  }
}


return root
