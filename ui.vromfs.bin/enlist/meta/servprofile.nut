from "%enlSqGlob/ui_library.nut" import *
let {nestWatched} = require("%dngscripts/globalState.nut")

let profile = nestWatched("PLAYER_PROFILE", {})

let export = {
  items = {}
  wallposters = {}
  soldiers = {}
  soldiersLook = {}
  soldiersOutfit = {}
  squads = {}
  armies = {}
  soldierPerks = {}
  researches = {}
  deliveries = {}
  armyEffects = {}
  slotsIncrease = {}
  savedEvents = {}
  purchasesCount = {}
  purchasesExt = {}
  receivedUnlocks = {}
  rewardedSingleMissons = {}
  premium = {}
  armyStats = {}
  activeBoosters = {}
  decorators = {}
  vehDecorators = {}
  medals = {}
  offers = {}
  metaConfig = {}
}.map(@(value, key) Computed(@() profile.value?[key] ?? value))

export.__update({ profile })

return export
