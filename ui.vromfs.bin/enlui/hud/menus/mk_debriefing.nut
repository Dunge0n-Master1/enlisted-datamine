from "%enlSqGlob/ui_library.nut" import *

let { h1_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { switch_to_menu_scene } = require("app")
let textarea = require("%ui/components/textarea.nut").smallTextarea
let JB = require("%ui/control/gui_buttons.nut")
let { strokeStyle } = require("%enlSqGlob/ui/viewConst.nut")

let winColor = Color(255,200,50,200)
let loseColor = Color(200,40,20,200)
let neutralColor = Color(150,180,250,150)
let textFx = {
  halign = ALIGN_CENTER
}.__update(h1_txt, strokeStyle)


const shortDebriefingTime = 5

let animations = [
  { prop=AnimProp.opacity, from=0, to=1 duration=0.5, play=true, easing=InOutCubic}
  { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.3, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0 duration=0.5, playFadeOut=true, easing=InOutCubic}
  { prop=AnimProp.scale, from=[1,1], to=[2,2], duration=0.3, playFadeOut=true, easing=InOutCubic}
]

let requestExitToLobby = Watched(false).subscribe(@(v) v ? switch_to_menu_scene() : null)

let function closeAction() {
  requestExitToLobby(true)
}

let function mkShortDebriefing(debriefing){
  let result = debriefing?.result
  let isVictory = result?.success
  let function info(){
    let title = textarea( " ".concat((result?.title ?? ""), result.who),
      textFx.__merge({
        size = [sh(100), SIZE_TO_CONTENT]
        color = isVictory ? winColor
          : result?.fail ? loseColor
          : neutralColor
      }))
    return {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      gap = fsh(1)
      pos = [0, -fsh(20)]
      size = SIZE_TO_CONTENT
      children = [ title ]
    }
  }
  return {
    key = "debriefingRootShort"
    size = [sw(100),sh(100)]
    function onDetach(){
      gui_scene.clearTimer(closeAction)
    }
    function onAttach() {
      gui_scene.setTimeout(shortDebriefingTime, closeAction)
    }
    children = [
     {
        valign = ALIGN_CENTER
        size = flex()
        children = info
      }
    ]

    hotkeys = [["^{0} | @HUD.GameMenu | Esc".subst(JB.B), {action = closeAction, description={skip=true}}]]

    transform = {pivot = [0.5, 0.25]}
    animations = animations
    sound = {
      attach = isVictory ? "ui/victory" : "ui/fail"
      detach = "ui/menu_highlight"
    }
  }
}

let function mkDebriefing(debriefingData) {
  let function debriefing() {
    let debriefingV = debriefingData.value
    let children = mkShortDebriefing(debriefingV)

    return {
      children = children
      watch = [debriefingData]
    }
  }
  return debriefing
}

return mkDebriefing
