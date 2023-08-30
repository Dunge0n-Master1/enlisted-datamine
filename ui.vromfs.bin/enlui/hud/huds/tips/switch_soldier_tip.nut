from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { isDowned } = require("%ui/hud/state/health_state.nut")
let { heroSquadNumAliveMembers } = require("%ui/hud/state/hero_squad.nut")
let { tipAlternate } = require("%ui/hud/huds/tips/tipComponent.nut")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)

let needSwitchSoldierTip = Computed(@() isDowned.value
  && controlledHeroEid.value
  && heroSquadNumAliveMembers.value > 1)

let tipDefaults = {
  textColor = Color(200,40,40,110)
  transform = {pivot=[0,0.5]}
  animations = [{prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack}]
  textAnims = [
    {prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull}
    {prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull}
  ]
}

let switchSquadSoldierTip = tipAlternate(tipDefaults.__merge({
  textsInputs = [
    { inputId = "Human.SquadNext", text = loc("controls/Human.SquadNext") }
    { inputId = "HUD.SquadSoldiersMenu", text = loc("controls/HUD.SquadSoldiersMenu") }
  ]
}, fontSub))

let function switch_soldier_tip(){
  let res = { watch = needSwitchSoldierTip }
  if (!needSwitchSoldierTip.value)
    return res
  return res.__update({
    children = switchSquadSoldierTip
  })
}

return switch_soldier_tip