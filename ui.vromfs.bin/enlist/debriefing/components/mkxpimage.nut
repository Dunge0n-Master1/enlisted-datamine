from "%enlSqGlob/ui_library.nut" import *

let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

let winImagePath = "ui/skin#battlehero/debriefing_awards_winner.png"
let battleHeroImagePath = "ui/skin#battlehero/debriefing_awards_mvp.png"
let boosterXpImagePath = @(size) "!ui/skin#xp_booster.svg:{0}:{0}:K".subst(size.tointeger())
let premiumImagePath = @(size) "!ui/skin#currency/enlisted_prem.svg:{0}:{0}:K".subst(size.tointeger())
let premiumSquadImagePath = @(size, armyId)
  "{0}:{1}:{1}:K".subst(armiesPresentation?[armyId].premIcon ?? "!ui/squads/ussr/prem_squad_ussr.svg", size.tointeger())
let freemiumImagePath = @(size) "!ui/skin#full_access.svg:{0}:{0}:K".subst(size.tointeger())

let xpImage = @(size, path) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture(path)
}

return {
  mkWinXpImage = @(size) xpImage(size, winImagePath)
  mkBattleHeroAwardXpImage = @(size) xpImage(size, battleHeroImagePath)
  mkPremiumAccountXpImage = @(size) xpImage(size, premiumImagePath(size))
  mkPremiumSquadXpImage = @(size, armyId) xpImage(size, premiumSquadImagePath(size, armyId))
  mkBoosterXpImage = @(size) xpImage(size, boosterXpImagePath(size))
  mkFreemiumXpImage = @(size) xpImage(size, freemiumImagePath(size))
}