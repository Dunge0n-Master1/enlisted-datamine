from "%enlSqGlob/ui_library.nut" import *

let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")

let RETIRE_ORDER = "soldier_order"
let retireReturn = Computed(@() sClassesCfg.value.reduce(function(res, cfgClass, sClass) {
  let { retireOrdersReturn = [] } = cfgClass
  if (retireOrdersReturn.len() > 0)
    res[sClass] <- retireOrdersReturn
  return res
}, {}))

return {
  RETIRE_ORDER
  retireReturn
}
