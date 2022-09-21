
from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { getLinkedArmyName, isObjLinkedToAnyOfObjects } = require("%enlSqGlob/ui/metalink.nut")
let { soldiersOutfit } = require("%enlist/meta/servProfile.nut")
let { curCampSoldiers } = require("%enlist/meta/profile.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")

let outfitSchemes = Computed(@() configs.value?.outfit_schemes ?? {})

let outfitShopTypes = Computed(@() configs.value?.outfit_shop ?? {})

let allOutfitByArmy = Computed(@()
  soldiersOutfit.value.reduce(function(res, outfit) {
    let armyId = getLinkedArmyName(outfit)
    if (armyId not in res)
      res[armyId] <- []
    res[armyId].append(outfit)
    return res
  }, {}))

let curArmyOutfit = Computed(function() {
  let soldiers = curCampSoldiers.value
  return (allOutfitByArmy.value?[curArmy.value] ?? [])
    .filter(@(outfit) !isObjLinkedToAnyOfObjects(outfit, soldiers))
  })

return {
  outfitSchemes
  outfitShopTypes
  allOutfitByArmy
  curArmyOutfit
}