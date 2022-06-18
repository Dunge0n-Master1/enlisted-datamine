from "%enlSqGlob/ui_library.nut" import *

require("%enlist/soldiers/model/onlyInEnlistVm.nut")("squadsConfig")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let serverConfigs = require("%enlSqGlob/configs/configs.nut").configs

let ordered = Computed(@() (serverConfigs.value?.squads_config ?? {})
  .map(@(list, armyId) list.map(function(squad, sIdx) {
        let squadPres = squadsPresentation?[armyId][squad?.id] ?? {}
        return squad.__merge(squadPres, { index = sIdx })
      }
    )
  )
)

let byId = Computed(@() ordered.value.map(function(list) {
  let res = {}
  foreach (squad in list)
    res[squad.id] <- squad
  return res
}))

return {
  squadsCfgOrdered = ordered
  squadsCfgById = byId
}