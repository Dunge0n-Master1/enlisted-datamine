from "%enlSqGlob/ui_library.nut" import *

require("%enlist/soldiers/model/onlyInEnlistVm.nut")("squadsConfig")

let serverConfigs = require("%enlSqGlob/configs/configs.nut").configs

let sClassesCfg = Computed(function() {
  let baseClasses = serverConfigs.value?.soldier_classes ?? {}
  let tiers = (serverConfigs.value?.perkPointsTiers ?? {})
  return baseClasses.map(@(c) c.__merge({ pointsByTiers = tiers?[c?.pointsGenId] ?? [] }))
})

return sClassesCfg