let { nestWatched } = require("%dngscripts/globalState.nut")

return {
  items = {}
  wallposters = {}
  soldiers = {}
  soldiersLook = {}
  soldiersOutfit = {}
  squads = {}
  armies = {}
  soldierPerks = {}
  researches = {}
  armyEffects = {}
  slotsIncrease = {}
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
}.map(@(defValue, key) nestWatched($"PLAYER_PROFILE_{key}", defValue))