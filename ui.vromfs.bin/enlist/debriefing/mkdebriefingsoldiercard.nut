from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let {
  mkLevelIcon, mkSoldierMedalIcon
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkSoldierPhoto } = require("%enlSqGlob/ui/soldierPhoto.nut")
let {soldierNameSlicer} = require("%enlSqGlob/ui/itemsInfo.nut")
let {withTooltip} = require("%ui/style/cursors.nut")
let mkBattleHeroAwardIcon = require("%enlSqGlob/ui/battleHeroAwardIcon.nut")

let SHOW_CARD_DELAY = 0.5
let EXP_RISE_DELAY = 0.9
let LVL_RISE_DELAY = 0.6

let soldierExpColor = Color(239, 219, 100)
let activeBgColor = Color(180,180,180,255)
let defBgColor = Color(0,0,0,120)

let soldierCardSize = [hdpxi(92), hdpxi(136)]

let smallPadding = hdpx(4)

let getExpProgressValue = @(exp, nextExp)
  nextExp > 0 ? clamp(exp.tofloat() / nextExp, 0, 1) : 0

let mkAddLevelBlock = @(lvlAdded, aDelay, animCtor) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  halign = ALIGN_CENTER
  children = [
    lvlAdded <= 0 ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          color = soldierExpColor
          text = loc("debriefing/new_level")
          fontFxColor = defBgColor
          fontFxFactor = min(hdpx(32), 32)
          fontFx = FFT_SHADOW
          transform = {}
          animations = [
            { prop = AnimProp.opacity, from = 0, to = 0, duration = aDelay,
              play = true }
            { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4,
              play = true, delay = aDelay }
            { prop = AnimProp.scale, from = [2,2], to = [1,1], duration = 0.6,
              play = true, delay = aDelay }
          ]
        }.__update(fontSub)
    {
      flow = FLOW_HORIZONTAL
      children = array(lvlAdded)
        .map(@(_, i) mkLevelIcon().__update({
          transform = {}
          animations = animCtor(aDelay + LVL_RISE_DELAY * i - 0.2,
            @() sound_play("ui/debriefing/squad_star"))
        }))
    }
  ]
}

let mkExpAnim = @(vv1, vv2, del, duration, cb = null) {
  prop = AnimProp.scale, easing = OutQuad, from = [vv1, 1], to = [vv2, 1],
  delay = del, duration, play = true, trigger = "content_anim",
  onFinish = cb
}

let function getExpAnimations(w1, w2, lvlAdded, delay, delay1, delay2, cb) {
  let res = [ mkExpAnim(w1, w1, 0, delay) ]
  let cbDelay = cb != null ? 0.2 : 0

  if (lvlAdded <= 0)
    return res.append( mkExpAnim(w1, w2, delay, delay1 + cbDelay, cb) )

  local riseDelay
  res.append( mkExpAnim(w1, 1, delay, delay1) )
  for (local i = 0; i < lvlAdded - 1; i++) {
    riseDelay = delay + delay1 + LVL_RISE_DELAY * i
    res.append( mkExpAnim(0, 1, riseDelay, LVL_RISE_DELAY) )
  }

  riseDelay = delay + delay1 + cbDelay + LVL_RISE_DELAY * (lvlAdded - 1)
  return res.append( mkExpAnim(0, w2, riseDelay, delay2, cb) )
}

let mkExpRiseBlock = @(w1, w2, lvlAdded, delay, delay1, delay2, cb) {
  rendObj = ROBJ_BOX
  size = [flex(), hdpx(7)]
  margin = smallPadding
  fillColor = defBgColor
  borderColor = activeBgColor
  borderWidth = hdpx(1)
  children = {
    rendObj = ROBJ_SOLID
    size = [pw(100), flex()]
    color = activeBgColor
    transform = { pivot = [0, 0], scale = [w2, 1] }
    animations = getExpAnimations(w1, w2, lvlAdded, delay, delay1, delay2, cb)
  }
}

let mkSoldierAwardIcon = @(award) withTooltip (
  mkBattleHeroAwardIcon(award, [hdpx(20), hdpx(20)]),
  @() loc($"debriefing/award_{award}"))

let mkAwards = @(awards) {
  size = flex()
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_TOP
  halign = ALIGN_RIGHT
  children = awards
  margin = smallPadding
}

let SOLDIER_CARD_PARAMS = {
  stat = null
  info = null
  awards = []
  animDelay = 0
  mkAppearAnimations = @(_delay) null
  nextAnimCb = null
}

local function mkSoldierCard(params = SOLDIER_CARD_PARAMS) {
  params = SOLDIER_CARD_PARAMS.__merge(params)

  let cb = params.nextAnimCb
  let aDelay = params.animDelay
  let maxLevel = params?.stat.maxLevel ?? params?.info.maxLevel ?? 1
  let wasLevel = min(params?.stat.wasExp.level ?? 0, maxLevel)
  let newLevel = min(params?.stat.newExp.level ?? 0, maxLevel)
  let wasExp = params?.stat.wasExp.exp ?? 0
  let newExp = params?.stat.newExp.exp ?? 0
  let wasNextLvlExp = params?.stat.wasExp.nextExp ?? wasExp
  let newNextLvlExp = params?.stat.newExp.nextExp ?? newExp

  let soldierName = soldierNameSlicer(params?.info)
  let soldierCallname = params?.info.callname ?? ""

  let w1 = getExpProgressValue(wasExp, wasNextLvlExp)
  let w2 = getExpProgressValue(newExp, newNextLvlExp)
  let lvlAdded = newLevel - wasLevel

  local delay1 = wasNextLvlExp == 0 ? 0
    : lvlAdded <= 0 ? EXP_RISE_DELAY * (newExp - wasExp) / wasNextLvlExp
    : EXP_RISE_DELAY * (wasNextLvlExp - wasExp) / wasNextLvlExp

  local delay2 = (!newNextLvlExp || lvlAdded <= 0) ? 0
    : EXP_RISE_DELAY * newExp / newNextLvlExp

  delay1 = max(delay1, EXP_RISE_DELAY / 4)
  delay2 = max(delay2, EXP_RISE_DELAY / 4)
  let medal = mkSoldierMedalIcon(params?.info, hdpx(16))
  let awards = params.awards.map(@(a) mkSoldierAwardIcon(a))
  return {
    content = {
      margin = hdpx(10)
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      children = [
        {
          children = [
            mkSoldierPhoto(params?.info.photoLarge ?? params?.info.photo, soldierCardSize, {
              size = [flex(), SIZE_TO_CONTENT]
              vplace = ALIGN_BOTTOM
              flow = FLOW_VERTICAL
              children = [
                mkAddLevelBlock(lvlAdded, aDelay + SHOW_CARD_DELAY + delay1, params.mkAppearAnimations)
                mkExpRiseBlock(w1, w2, lvlAdded, aDelay + SHOW_CARD_DELAY, delay1, delay2, cb)
              ]
            })
            medal == null ? null : medal.__update({ margin = smallPadding })
            mkAwards(awards)
            lvlAdded <= 0 ? null : {
              rendObj = ROBJ_BOX
              size = flex()
              borderColor = soldierExpColor
              borderWidth = hdpx(1)
              animations = [
                { prop = AnimProp.opacity, from = 0, to = 0, play = true,
                  duration = aDelay + delay1 + 0.3, trigger = "content_anim" }
                { prop = AnimProp.opacity, from = 0, to = 1, play = true,
                  delay = aDelay + delay1 + 0.3, duration = 0.3, trigger = "content_anim" }
              ]
            }
          ]
        }
        {
          rendObj = ROBJ_TEXT
          text = soldierCallname != "" ? soldierCallname : soldierName
          maxWidth = SIZE_TO_CONTENT
          hplace = ALIGN_CENTER
          size = [soldierCardSize[0], SIZE_TO_CONTENT]
          behavior = Behaviors.Marquee
        }.__update(fontSub)
      ]
      transform = {}
      animations = params.mkAppearAnimations(aDelay)
    }
    delay = delay1 + delay2 + max(0, EXP_RISE_DELAY * (lvlAdded - 1))
  }
}

return mkSoldierCard
