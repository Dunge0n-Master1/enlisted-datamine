from "%enlSqGlob/ui_library.nut" import *

let { h1_txt, h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")
let {set_fully_covering} = require("loading")
let {levelIsLoading} = require("%ui/hud/state/appState.nut")
let {mkParallaxBkg, mkAnimatedEllipsis} = require("%ui/loading/loadingComponents.nut")
let {shuffle} = require("%sqstd/rand.nut")
let {verPadding, horPadding} = require("%enlSqGlob/safeArea.nut")
let { darkBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let { doesLocTextExist } = require("dagor.localize")
let {loadingImages} = require("%ui/hud/state/loading.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let curImg = Computed(@() shuffle(loadingImages.value ?? [])?[0])

local hintsToChange = []

let hintsKey = "loading_tip"
local lastAddedTipIdx = 0

for(local idx = 1; idx - lastAddedTipIdx < 3 ; idx++){
  let newKey = $"{hintsKey}{idx}"
  if (doesLocTextExist(newKey)){
    hintsToChange.append(newKey)
    lastAddedTipIdx = idx
  }
}

hintsToChange = shuffle(hintsToChange)

let curIdx = Watched(0)

let curHint = Computed(@() hintsToChange.len() > 0
  ? hintsToChange[curIdx.value % hintsToChange.len()]
  : "practice_desc")

let tipHeaderColor = Color(230,200,30,255)

const defaultTimeToSwitch = 20
const defaultAutoTimeToSwitch = 15
let function nextTipAuto(){
  curIdx(curIdx.value + 1)
}
let function nextTip() {
  gui_scene.clearTimer(nextTipAuto)
  gui_scene.clearTimer(callee())
  gui_scene.setTimeout(defaultTimeToSwitch, callee())
  curIdx(curIdx.value + 1)
}
let function prevTip(){
  gui_scene.clearTimer(nextTipAuto)
  gui_scene.clearTimer(nextTip)
  gui_scene.setTimeout(defaultTimeToSwitch, nextTip)
  curIdx(curIdx.value + 1)
}
gui_scene.setInterval(defaultAutoTimeToSwitch, nextTipAuto)

let showImage = keepref(Computed(@() curImg.value != null && !levelIsLoading.value))
showImage.subscribe(set_fully_covering)

let color = Color(160,160,160,160)

let fontSize = hdpx(25)
let animatedEllipsis = mkAnimatedEllipsis(fontSize, color)

let animatedLoading = @(){
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  watch = [verPadding, horPadding]
  valign = ALIGN_CENTER
  padding = [verPadding.value + fsh(1), horPadding.value + sw(4)]
  pos = [-fsh(7),-fsh(3)]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("Loading")
      color = color
    }.__update(h1_txt)
    {size=[hdpx(4),0]}
    animatedEllipsis
  ]
}

const parallaxK = -0.025
local letterBoxHeight=(sh(100) - sw(100)/16*9)/2
if (letterBoxHeight < 0)
  letterBoxHeight = 0

let letterboxUp = {rendObj = ROBJ_SOLID size=[flex(), letterBoxHeight], color = Color(0,0,0)}
let letterboxDown = letterboxUp.__merge({vplace=ALIGN_BOTTOM})


let loadingBkg = mkParallaxBkg(curImg, parallaxK, (sh(100)-letterBoxHeight*2), sw(100))

let blackScreen = {
  rendObj = ROBJ_SOLID
  color = Color(0,0,0)
  size = flex()
}

let tipsHotkeys = @() {
  size = flex()
  children = {
    behavior = Behaviors.Button
    size = flex()
    hotkeys = [
      ["^A | Down | S | M:0", prevTip],
      ["^W | Up | D | | M:1", nextTip],
      ["^J:D.Left | Left", prevTip],
      ["^J:D.Right | Right", nextTip]
    ]
  }
}

let decoratedImage = @(){
  size = flex()
  watch = curImg
  children = curImg.value != null ? [
    blackScreen
    loadingBkg
    letterboxUp
    letterboxDown
  ] : null
}

let animations = [
  { prop=AnimProp.translate, from=[sw(10),0], to=[0,0], duration=0.2, play=true, easing=InCubic},
  { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InCubic},
  { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InCubic},
  { prop=AnimProp.translate, from=[0,0], to=[-sw(10),0], duration=0.3, playFadeOut=true, easing=OutCubic}
]

let activeTipHdr = tipCmp({
  textColor = tipHeaderColor
  fontFxColor = Color(0,0,0,190)
  fontFxFactor = 64
  fontFx = FFT_SHADOW
  fontFxOffsX = 2
  fontFxOffsY = 2
  text = loc("loading/controlsHelpTip")
  inputId = "HUD.Briefing"
  style = { rendObj = null }
}.__update(h2_txt))


let tipText = @() {
  watch = curHint
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  text = loc(curHint.value)
  size = [flex(), SIZE_TO_CONTENT]
  orientation = O_VERTICAL
  transform = {}
  speed = [hdpx(10),hdpx(200)]
  delay = 3
}.__update(body_txt)

let activeTipText = {
  size = [min(sw(80), sh(100)), SIZE_TO_CONTENT]
  clipChildren = true
  children = tipText
  valign = ALIGN_CENTER
}

let tips = @() {
  size = [sw(75), SIZE_TO_CONTENT]
  transform = {pivot = [0.5, 0.5]}
  watch = curHint
  vplace = ALIGN_CENTER
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      key = curHint.value
      transform = {pivot = [0.5, 0.5]}
      animations = animations
      flow = FLOW_VERTICAL
      children = activeTipText
    }
    tipsHotkeys
  ]
}


let bottomBlock = @(){
  padding = [verPadding.value + fsh(1), horPadding.value + sw(4)]
  watch = [verPadding, horPadding]
  rendObj = ROBJ_SOLID
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = max(fsh(18), verPadding.value + fsh(18))
  color = darkBgColor
  children = [
    {
      size = flex()
      children = [
        activeTipHdr
        tips
      ]
    }
    animatedLoading
  ]
}

let missionTitle = @(){
  watch = [missionName, missionType]
  rendObj = ROBJ_TEXT
  text = loc(missionName.value, { mission_type = loc($"missionType/{missionType.value}") })
  margin = [verPadding.value + sh(5), horPadding.value + sw(7)]
  color
  fontFxColor = Color(0,0,0,190)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_SHADOW
  fontFxOffsX = min(2,hdpx(2))
  fontFxOffsY = min(2, hdpx(2))
}.__update(h1_txt)
let screen = {
  size = flex()
  children = [
    decoratedImage
    missionTitle
    bottomBlock
  ]
}

return screen