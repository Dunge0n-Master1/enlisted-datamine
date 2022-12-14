from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { rent_squad } = require("%enlist/meta/clientApi.nut")


let rentSquadsConfig = Computed(function() {
  let costSchemes = configs.value?.rentPrices ?? {}
  return (configs.value?.rentConfig.squads ?? {})
    .map(@(armyCfg) armyCfg.map(@(schemeId) costSchemes?[schemeId] ?? []))
})


let function rentSquad(armyId, squadId, rentTime, price) {
  rent_squad(armyId, squadId, rentTime, price)
}


return {
  rentSquadsConfig
  rentSquad
}
