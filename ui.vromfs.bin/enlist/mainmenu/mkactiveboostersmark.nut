from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor, activeTxtColor, msgHighlightedTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { curArmyBoosters, nextExpireTime } = require("%enlist/soldiers/model/boosters.nut")
let mkBoosterMark = require("%enlist/components/mkBoosterMark.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { withTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let { round } = require("math")

let sumBoosters = Computed(function() {
  let res = { positive = 0.0, negative = 0.0 }
  foreach(booster in curArmyBoosters.value){
    if (booster.expMul > 0)
      res.positive += booster.expMul
    else
      res.negative += booster.expMul
  }
  return res
})

let percentSign = @(num) num > 0 ? $"+{round(num * 100.0)}" : round(num * 100.0)

let toPercentColored = @(v) colorize(msgHighlightedTxtColor, percentSign(v))

let function mkBoosterInfoText(booster, curTime) {
  let { leftBattles, expireTime } = booster
  let percent = toPercentColored(booster.expMul)
  let limitsList = []
  if (expireTime > 0)
    limitsList.append(secondsToHoursLoc(max(0, expireTime - curTime)))
  if (leftBattles > 0)
    limitsList.append(loc("boostName/battlesLimit", { battles = leftBattles }))
  let limits = loc("boostName/limit", { limits = " / ".join(limitsList) })
  return loc("startBtn/boosterRow", { percent, limits })
}

let mkBlock = @(locId, percent, lines) function() {
  let blockHeader = colorize(activeTxtColor, loc(locId, { percent }))
  let blockLines = lines.map(@(line) mkBoosterInfoText(line, serverTime.value))
  return {
    rendObj = ROBJ_TEXTAREA
    watch = serverTime
    behavior = Behaviors.TextArea
    color = defTxtColor
    text = "\n".join([blockHeader].extend(blockLines))
  }
}

let mkTooltip = @() tooltipBox(function() {
  let bonuses = []
  let penalties = []
  foreach (booster in curArmyBoosters.value) {
    if (booster.expMul > 0)
      bonuses.append(booster)
    else
      penalties.append(booster)
  }
  let { positive, negative } = sumBoosters.value
  let infoRows = []
  if (bonuses.len() && penalties.len())
    infoRows.append({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = activeTxtColor
      text = loc($"boosterTotal", {
        value = round((positive + 1.0) * (negative + 1.0) * 100)
        bonus = round((positive + 1.0) * 100.0)
        penalty = round((negative + 1.0) * 100.0)
      })
    })

  if (bonuses.len())
    infoRows.append(mkBlock("startBtn/boosterBonus", percentSign(positive), bonuses))

  if (penalties.len())
    infoRows.append(mkBlock("startBtn/boosterPenalty", percentSign(negative), penalties))

  return {
    watch = [curArmyBoosters, sumBoosters]
    flow = FLOW_VERTICAL
    gap = hdpxi(15)
    children = infoRows
  }
})

return function(override) {
  let timeLeftText = Computed(function() {
    let time = nextExpireTime.value - serverTime.value
    return time <= 0 ? "" : secondsToHoursLoc(time)
  })

  return withTooltip(
    @() sumBoosters.value.positive == 0 && sumBoosters.value.negative == 0
      ? { watch = [sumBoosters] }
      : mkBoosterMark(sumBoosters.value.positive, sumBoosters.value.negative, timeLeftText.value,
          {
            watch = [sumBoosters, timeLeftText]
            cursor = normalTooltipTop
          }.__update(override)),
    mkTooltip)
}