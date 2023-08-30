from "%enlSqGlob/ui_library.nut" import *

let {fontSub} = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let speakingPlayers = require("%ui/hud/state/voice_chat.nut")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let {horPadding, verPadding} = require("%enlSqGlob/safeArea.nut")

let speakingColor = Color(0, 255, 0)
let speakingIcon = faComp("volume-up", {
  vplace = ALIGN_BOTTOM
  color = speakingColor
  transform = {}
  animations = [
    { prop=AnimProp.scale, from=[1.2, 1.2], duration=0.1, play=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=0, to=1, duration=0.1, play=true, easing=OutCubic }
    { prop=AnimProp.scale, to=[0, 0], duration=0.1, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
  fontSize = hdpx(12)
})

let function mkSpeaker(name) {
  return {
    flow = FLOW_HORIZONTAL
    valing = ALIGN_BOTTOM
    gap = fsh(0.2)
    children = [
      speakingIcon
      {
        color = speakingColor
        text = name
        rendObj = ROBJ_TEXT
      }.__update(fontSub, {fontSize = hdpx(12)})
    ]
  }
}

let function mapTable(table, func= @(v) v){
  let ret = []
  foreach (k, _ in table)
    ret.append(func(k))
  return ret
}

return @() {
  flow = FLOW_VERTICAL
  gap = fsh(0.2)
  margin = [verPadding.value, hdpx(10) + horPadding.value]
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR
  zOrder = Layers.Tooltip
  size = SIZE_TO_CONTENT
  watch = [speakingPlayers, horPadding, verPadding]
  children = mapTable(speakingPlayers.value, @(name) mkSpeaker(remap_others(name)))
}
