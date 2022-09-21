from "%enlSqGlob/ui_library.nut" import *

let serverConfigs = require("%enlist/meta/configs.nut").configs

let sClassesCfg = Computed(function() {
  let baseClasses = serverConfigs.value?.soldier_classes ?? {}
  let tiers = (serverConfigs.value?.perkPointsTiers ?? {})
  return baseClasses.map(@(c) c.__merge({ pointsByTiers = tiers?[c?.pointsGenId] ?? [] }))
})

return sClassesCfg