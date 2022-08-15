from "%enlSqGlob/ui_library.nut" import *

require("%ui/hud/state/awards.nut")
require("%ui/hud/state/score_awards_state.nut")
let awardsLog = require("%ui/hud/state/eventlog.nut").awards
let { lerp } = require("%sqstd/math.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { strokeStyle } = require("%enlSqGlob/ui/viewConst.nut")

const ANIM_TRIGGER = "animScoreAward"
const maxAwardsToShow = 5

let numAnimations = [
  { prop=AnimProp.opacity, from=0.0, to=0.0, duration=0.1, play=true easing=OutCubic }
  { prop=AnimProp.scale, from=[2,2], to=[1,1], delay=0.1, duration=0.5, play=true easing=OutCubic }
  { prop=AnimProp.opacity, from=0.0, to=1.0, delay=0.1, duration=0.5, play=true easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[2,2], duration=0.1, playFadeOut=true easing=OutCubic }
  { prop=AnimProp.opacity, from=1.0, to=0.0, delay=0.1, duration=0.1, playFadeOut=true easing=OutCubic }
]

let color = Color(130,130,130,80)

let xtext = freeze({
  rendObj = ROBJ_TEXT
  text = "x"
  color
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [0, -body_txt.fontSize * 0.05]
}.__merge(body_txt, strokeStyle))

let function mkAwardText(text, params = {}){
  if (text == null)
    return null
  return {
    rendObj = ROBJ_TEXT
    text
    color
    hplace = ALIGN_CENTER
  }.__merge(body_txt, strokeStyle, params)
}

let awardHgt = calc_str_box(mkAwardText("H"))[1].tointeger()

let transitions = [
  { prop = AnimProp.translate, duration = 0.3, easing = OutQuad }
  { prop = AnimProp.opacity, duration = 0.1, easing = OutQuad }
]
let pivot = [0.5, 0.5]
let gap = awardHgt/3

let mkMainAwardAnimations = @(_normidx, opacity) [
  { prop=AnimProp.scale, from=[1,1], to=[1,0.2], duration=0.2, playFadeOut=true, easing=OutCubic}
  { prop=AnimProp.translate, from=[0, awardHgt*3], to=[0, awardHgt*3 + fsh(8)], duration=0.6, playFadeOut=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=min(opacity, 0.6), to=0, duration=0.4, playFadeOut=true easing=OutCubic}
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.2, play=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true }
]

let awardImg = Picture($"ui/skin#skull.svg:{awardHgt}:{awardHgt}:K")
let awardIconsByType = {
  kill = @(key){
    rendObj = ROBJ_IMAGE
    image = awardImg
    size = [awardHgt, awardHgt]
    transform = {}
    key
    opacity = 1
    color
    animations = [
      { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.5, play=true, easing=InOutQuintic}
      { prop=AnimProp.opacity, from=0, to=1, duration=0.4, play=true, easing=InOutQuintic }
    ]
  }
}

let awardTextByType = {
  multi_kill = @(item) mkAwardText(loc($"hud/awards/multi_kill/counter", item.awardData))
}

let function defAwardText(item) {
  let { awardData, num = null } = item
  let awardType = awardData.type

  local locText = awardData?.text ?? ""
  if (locText == "")
    locText = loc($"hud/awards/{awardType}", "")
  if (locText == "")
    locText = null
  else if (awardData?.forgiven)
    locText = loc($"hud/awards/anti_award_forgiven", locText, {antiaward = locText})
  let awardText = mkAwardText(locText)

  if (awardText == null)
    return null
  if (num == null)
    return awardText
  return {
    flow = FLOW_HORIZONTAL
    children = [
      awardText
      { size = [gap, SIZE_TO_CONTENT] }
      xtext
      mkAwardText(num, { animations = numAnimations, transform = { pivot }})
    ]
  }
}

let getAwardText = @(item) (awardTextByType?[item.awardData.type] ?? defAwardText)(item)
let hasAwardText = @(item) getAwardText(item) != null

let function makeAward(item, idx, col) {
  let len = col.len()
  let normidx = len - 1 - idx
  let { awardData, key = null, num = null } = item
  let awardType = awardData.type
  let awardText = getAwardText(item)
  let awardIcon = awardIconsByType?[awardType]($"{key}_{num}")
  let opacity = clamp(lerp(maxAwardsToShow-3, maxAwardsToShow-1, 1.0, 0.4, normidx), 0, 1)
  return {
    key
    gap
    flow = FLOW_HORIZONTAL
    size = SIZE_TO_CONTENT
    children = [
      awardIcon
      awardText
    ]
    opacity = opacity
    animations = mkMainAwardAnimations(normidx, opacity)
    transform = {
      pivot = pivot
      translate = [0, awardHgt * normidx]
    }
    transitions = transitions
  }
}

let tipBack = {
  rendObj = ROBJ_WORLD_BLUR
  padding = hdpx(2)
  size = SIZE_TO_CONTENT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  transform = { pivot = [0.5, 0.5] }
}

let text_hint = @(text) {
  rendObj = ROBJ_TEXT
  margin = hdpx(2)
  text
  fontSize = body_txt.fontSize
  transform = {}
}

let mkScoreText = @(value)
  tipBack.__merge({
    children = [
      text_hint(loc("hud/score_award", {value})).__update({
        animations=[{ prop=AnimProp.scale, from=[1.4,1.4], to=[1,1], duration=0.3, play=true, easing=OutQuintic, trigger=ANIM_TRIGGER}]
      })
    ]
  })

let currentScoreAwards = Watched({})

awardsLog.events.subscribe(function(awards) {
  if (awards.len() == 0)
    currentScoreAwards({})
  else
    currentScoreAwards.mutate(function(currentAwards) {
      foreach (award in awards)
        if (award?.key != null && (award.awardData?.score ?? 0) > 0)
          currentAwards[award.key] <- award.awardData.score
    })
})

let currentScore = Computed(@() (currentScoreAwards.value.reduce(@(a, b) a + b) ?? 0).tointeger() )

currentScore.subscribe(@(_) anim_start(ANIM_TRIGGER))

return function () {
  local awards = awardsLog.events.value
    .filter(hasAwardText)
    .map(makeAward)
  let len = awards.len()
  if (len > maxAwardsToShow)
    awards = awards.slice(len-maxAwardsToShow)
  awards.reverse()

  let scoreText = currentScore.value > 0
    ? mkScoreText(currentScore.value)
    : null
  return {
    watch = [awardsLog.events, currentScore]
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    size = [pw(30), maxAwardsToShow*awardHgt + gap*(maxAwardsToShow-1)]

    children = [
      {
        padding = [0, hdpx(4)]
        gap = hdpx(2)
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = awards
      }
      {
        size = [0,0] // Attach to right side of previous child
        children = scoreText
      }
    ]
  }
}
