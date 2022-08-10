from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor, activeTxtColor, msgHighlightedTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { globalBoost, curArmyBoosters, curBoosts, nextExpireTime } = require("%enlist/soldiers/model/boosters.nut")
let mkBoosterMark = require("%enlist/components/mkBoosterMark.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { withTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")

let boostsOrder = [globalBoost, "army", "squad", "soldier"]

let maxBoost = Computed(@() curBoosts.value.reduce(@(res, v) max(res, v), 0))

let toPercentColored = @(v) colorize(msgHighlightedTxtColor, (v * 100 + 0.5).tointeger())
let function mkBoosterInfoText(booster, curTime) {
  let { leftBattles, expireTime } = booster
  let percent = toPercentColored(booster.expMul)
  let limitsList = []
  if (expireTime > 0)
    limitsList.append(secondsToHoursLoc(max(0, expireTime - curTime)))
  if (leftBattles > 0)
    limitsList.append(loc("boostName/battlesLimit", { battles = leftBattles }))
  let limits = loc("boostName/limit", { limits = " / ".join(limitsList) })
  return loc("boostInfo/withLimits", { percent, limits })
}

let sumExp = @(boosters) boosters.reduce(@(res, b) res + b.expMul, 0.0)

let function mkTooltip() {
  let infoBlocks = Computed(function() {
    let boostersByType = {}
    foreach (booster in curArmyBoosters.value)
      boostersByType[booster.bType] <- (boostersByType?[booster.bType] ?? []).append(booster)

    let globalAdd = sumExp(boostersByType?[globalBoost] ?? [])
    let curTime = serverTime.value
    let blocks = boostsOrder.map(function(bType) {
      if (globalAdd == 0 && bType not in boostersByType)
        return null
      let typeBoosters = boostersByType?[bType] ?? []
      let rows = typeBoosters.map(@(b) mkBoosterInfoText(b, curTime))
      let isGlobalBoost = bType == globalBoost
      let addAmount = isGlobalBoost ? 0 : globalAdd
      if (addAmount > 0 || rows.len() > 1)
        rows.append(loc($"boostTotal/{bType}", {
          percent = toPercentColored((isGlobalBoost ? 0 : sumExp(typeBoosters)) + globalAdd)
        }))
      rows.insert(0, colorize(activeTxtColor, loc($"boostHeader/{bType}")))
      return "\n".join(rows)
    })
    return blocks.filter(@(b) b != null)
  })
  return tooltipBox(@() {
    watch = infoBlocks
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = infoBlocks.value.map(@(text) {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = defTxtColor
      text
    })
  })
}

return function(override) {
  let timeLeftText = Computed(function() {
    let time = nextExpireTime.value - serverTime.value
    return time <= 0 ? "" : secondsToHoursLoc(time)
  })

  return withTooltip(
    @() maxBoost.value <= 0 ? { watch = maxBoost }
      : mkBoosterMark(maxBoost.value, timeLeftText.value,
        {
          watch = [maxBoost, timeLeftText]
          cursor = normalTooltipTop
        }.__update(override))
    mkTooltip)
}