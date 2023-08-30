from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { growthState } = require("%enlist/meta/servProfile.nut")
let { growth_select, growth_select_forced, growth_reward_take, growth_reward_take_forced,
  growth_add_exp } = require("%enlist/meta/clientApi.nut")
let { armies, curArmy } = require("%enlist/soldiers/model/state.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")

let curGrowthId = Watched(null)
let defaultTier = freeze({ index = 0, from = 0, to = 0, required = 1 })

let curGrowthConfig = Computed(@() configs.value?.growthConfig[curArmy.value] ?? {})
let growthRelations = @() Computed(function() {
  let result = curGrowthConfig.value.reduce(function(res, val, _, tbl) {
    let { id, col = null, line = null, requirements = [] } = val
    if (requirements.len() > 0) {
      let ancestor = tbl[requirements[0]]
      if (col == ancestor?.col && line == ancestor?.line) {
        let ancestorRelations = res?[ancestor.id] ?? [ancestor.id]
        let inheritorRelations = res?[id] ?? [id]
        ancestorRelations.extend(inheritorRelations)
        res[ancestor.id] <- ancestorRelations
        foreach(updateId in inheritorRelations)
          res[updateId] <- ancestorRelations
      }
    }
    return res
  }, {})
  return result
})


let curGrowthTiers = @() Computed(@() configs.value?.growthTiers.map(@(army)
  army.map(@(t) defaultTier.__merge(t)) ?? [])[curArmy.value])
let tierProgressByArmy = Watched(0)
let curGrowthSelected = Computed(@() armies.value?[curArmy.value].growthSelected)
let curSquads = Computed(function() {
  let armyId = curArmy.value
  return squadsCfgById.value?[armyId] ?? {}
})
let curTemplates = Computed(@() allItemTemplates.value?[curArmy.value] ?? {})

enum GrowthStatus {
  UNAVAILABLE = 0
  ACTIVE = 1
  COMPLETED = 2
  REWARDED = 3
}

console_register_command(@(growthId) growth_select(curArmy.value, growthId),
  "meta.growthSelect")

console_register_command(@() growth_select_forced(curArmy.value, curGrowthId.value),
  "meta.growthSelectCurrent")

console_register_command(@(growthId) growth_reward_take(curArmy.value, growthId),
  "meta.growthTake")

console_register_command(@() growth_reward_take_forced(curArmy.value, curGrowthId.value),
  "meta.growthTakeCurrent")

console_register_command(@(exp) growth_add_exp(curArmy.value, curGrowthId.value, exp),
  "meta.addCurGrowthExp")

return {
  GrowthStatus
  curGrowthId
  curGrowthConfig
  curGrowthTiers
  curGrowthState = growthState
  curGrowthSelected
  curSquads
  curTemplates
  growthRelations
  tierProgressByArmy

  callGrowthSelect = growth_select
  callGrowthRewardTake = growth_reward_take
}