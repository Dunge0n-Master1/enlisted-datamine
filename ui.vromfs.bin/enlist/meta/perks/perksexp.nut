from "%enlSqGlob/ui_library.nut" import *

let {configs} = require("%enlist/meta/configs.nut")

let perkLevelsGrid = Computed(@() configs.value?.perk_levels_grid)

let getExpToNextLevel = @(level, maxLevel, expToLevel)
  level < maxLevel ? (expToLevel?[level] ?? 0) : 0

let getGoldToNextLevel = @(level, maxLevel, lvlsCfg) lvlsCfg == null ? 0
  : level < (maxLevel ?? lvlsCfg.MAX_LEVEL) ? (lvlsCfg.goldToLevel?[level] ?? lvlsCfg.goldToPerkOnMaxLevel)
  : lvlsCfg.goldToPerkOnMaxLevel

let getOrdersToNextLevel = kwarg(function(level, maxLvl, cfg) {
  let orderTpl = cfg?.orderTpl
  let ordersRequire = level < (maxLvl ?? cfg.MAX_LEVEL)
    ? (cfg?.ordersRequire[level] ?? cfg?.ordersToPerkOnMaxLevel ?? 0)
    : (cfg?.ordersToPerkOnMaxLevel ?? 0)
  return orderTpl == null || ordersRequire <= 0 ? null
    : { orderTpl, ordersRequire }
})

let getNextLevelData = kwarg(function(level, maxLevel, exp, lvlsCfg) {
  let expToLevel = getExpToNextLevel(level, maxLevel, lvlsCfg.expToLevel)
  let goldToLevel = getGoldToNextLevel(level, maxLevel, lvlsCfg)
  if (expToLevel <= 0 || goldToLevel <= 0)
    return null

  let needExp = expToLevel - exp
  return {
    exp = needExp
    cost = max(goldToLevel * needExp / expToLevel, 1)
  }
})

let getGoldToMaxLevel = kwarg(function(level, maxLevel, exp, lvlsCfg) {
  local totalPrice = 0
  for (local lvl = level; lvl < maxLevel; lvl++)
    totalPrice += getNextLevelData({
      level = lvl
      maxLevel = maxLevel
      exp = lvl == level ? exp : 0
      lvlsCfg = lvlsCfg
    })?.cost ?? 0

  return totalPrice
})

return {
  perkLevelsGrid
  getExpToNextLevel
  getGoldToNextLevel
  getOrdersToNextLevel
  getNextLevelData
  getGoldToMaxLevel
}
