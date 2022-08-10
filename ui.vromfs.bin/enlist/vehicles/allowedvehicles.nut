from "%enlSqGlob/ui_library.nut" import *

let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")

let allowedBySquads = Computed(@()
  squadsCfgById.value.map(@(squadsCfg)
    squadsCfg.map(function(squad) {
      let res = {}
      let squadVehicle = squad?.startVehicle ?? "" //compatibility with prev profile version. 30.10.2020
      if (squadVehicle != "")
        res[squadVehicle] <- true
      foreach (vehicle in squad?.allowedVehicles ?? [])
        res[vehicle] <- true
      return res
    })
  ))

return allowedBySquads
