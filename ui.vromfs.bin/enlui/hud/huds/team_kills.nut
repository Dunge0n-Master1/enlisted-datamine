from "%enlSqGlob/ui_library.nut" import *

let {showFriendlyFireWarning} = require("%ui/hud/state/friendly_fire_warnings_state.nut")
let {textarea} = require("%ui/components/textarea.nut")

let trigger = {}
let warning = freeze(
  textarea(
    loc("teamkill_warning", "If you continue killing of your teammates you would be kick out of battle!"),
    {
      align = ALIGN_CENTER
      size = [sw(40), SIZE_TO_CONTENT]
      transform = {}
      animations = [
        { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.33, play=true, easing=OutCubic }
        { prop=AnimProp.scale, from=[1,1], to=[1,1], duration=0.5, playFadeOut=true, onExit = trigger}
        { prop=AnimProp.scale, from=[1,1], to=[0,1], duration=0.33, trigger, easing=OutCubic }
        { prop=AnimProp.opacity, from=1, to=0, duration=0.83, playFadeOut=true, easing=OutCubic }
      ]
    }
  )
)
return {
  tkWarning = @(){
    watch = showFriendlyFireWarning
    children = showFriendlyFireWarning.value ? warning : null
  }
}