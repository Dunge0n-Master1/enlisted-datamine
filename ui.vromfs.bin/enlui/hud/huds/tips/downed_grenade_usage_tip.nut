from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { isDowned } = require("%ui/hud/state/health_state.nut")
let { hasAnyGrenade } = require("%ui/hud/state/hero_weapons.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { mkHasBinding } = require("%ui/control/formatInputBinding.nut")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)

let hasGrenadeBind = mkHasBinding("Human.ThrowDowned")

let needShowGrenadeTip = Computed(@() isDowned.value && controlledHeroEid.value
  && hasGrenadeBind.value && hasAnyGrenade.value)

let tipDefaults = {
  textColor = Color(200,40,40,110)
  transform = {pivot=[0,0.5]}
  animations = [{prop=AnimProp.translate, from=[sw(50),0], to=[0,0],
    duration=0.5, play=true, easing=InBack}]
  textAnims = [
    {prop=AnimProp.color, from=color0, to=color1, duration=1.0,
      play=true, loop=true, easing=CosineFull}
    {prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0,
      play=true, loop=true, easing=CosineFull}
  ]
}

let grenadeUsageTip = tipCmp(tipDefaults.__merge({
  text = loc("tips/useGrenade")
  inputId = "Human.ThrowDowned"
}, fontSub))


let downed_grenade_usage_tip = @() {
  watch = needShowGrenadeTip
  children = needShowGrenadeTip.value ? grenadeUsageTip : null
}

return downed_grenade_usage_tip