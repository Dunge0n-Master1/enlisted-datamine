import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { HUD_TIPS_FAIL_TEXT_COLOR } = require("%ui/hud/style.nut")
let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { artilleryIsAvailable, artilleryAvailableTimeLeft, artilleryIsReady, artilleryIsAvailableByLimit
} = require("%ui/hud/state/artillery.nut")
let { mkHasBinding } = require("%ui/components/controlHudHint.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let {CmdShowArtilleryCooldownHint} = require("dasevents")

let gap = hdpx(5)

let function show_artillery_cooldown_hint(){
  let timeLeft = artilleryAvailableTimeLeft.value
  if (timeLeft <= 0)
    return
  let timeLeftStr = secondsToStringLoc(timeLeft)
  playerEvents.pushEvent({
    text = loc("artillery/cooldown", {timeLeft = timeLeftStr})
    color = HUD_TIPS_FAIL_TEXT_COLOR
  })
}

let artilleryHotkey = "Human.ArtilleryStrike"
let hasArtilleryBinding = mkHasBinding(artilleryHotkey)
let function artilleryOrder() {
  let hint = tipCmp({
    text = Computed(@() !artilleryIsAvailableByLimit.value ? loc("artillery/already_active")
      : artilleryAvailableTimeLeft.value > 0
        ? loc("artillery/cooldown", { timeLeft = secondsToStringLoc(artilleryAvailableTimeLeft.value) })
      : loc("squad_orders/artillery_strike"))
    inputId = hasArtilleryBinding.value ? artilleryHotkey : "HUD.CommandsMenu"
  }.__update(sub_txt))
  return {
    watch = hasArtilleryBinding
    children = hint
  }
}

let artilleryIconHgt = calc_comp_size(artilleryOrder)[1]
let artilleryIcon = Picture("ui/skin#artillery_strike.svg:{0}:{0}:K".subst(artilleryIconHgt))
let artilleryIconComp = @() { watch = artilleryIsReady }
  .__update(!artilleryIsReady.value ? {}
    : { rendObj = ROBJ_IMAGE, image = artilleryIcon, size = [artilleryIconHgt, artilleryIconHgt] })

let artilleryOrderFull = @() {
  flow = FLOW_HORIZONTAL
  watch = artilleryIsAvailable
  gap
  valign = ALIGN_CENTER
  children = !artilleryIsAvailable.value ? null : [
    artilleryOrder
    artilleryIconComp
  ]
}

let artillery = @() {
  flow = FLOW_VERTICAL
  gap = gap
  children = [artilleryOrderFull]
}

ecs.register_es("artillery_hero_show_cooldown_hint_es",
  {
    [CmdShowArtilleryCooldownHint] = @(_evt, _eid, _comp) show_artillery_cooldown_hint()
  },
  { comps_rq = ["player"] },
  { tags="gameClient" }
)

return artillery
