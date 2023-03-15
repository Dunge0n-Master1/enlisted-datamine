from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { BattleHeroesAward } = require("battleHeroesAwards.nut")

let battleHeroAwardIcon = {
  [BattleHeroesAward.TOP_PLACE] = { img = "ui/skin#battlehero/debriefing_awards_first_place.avif" },
  [BattleHeroesAward.TOP_VEHICLE_SQUAD] = { img = "ui/skin#battlehero/debriefing_awards_best_mechanic.avif" },
  [BattleHeroesAward.TOP_INFANTRY_SQUAD] = { img = "ui/skin#battlehero/debriefing_awards_best_infantryman.avif" },
  [BattleHeroesAward.TOP_KIND_RIFLE] = { img = "ui/skin#battlehero/debriefing_awards_best_rifle.avif" },
  [BattleHeroesAward.TOP_KIND_ASSAULT] = { img = "ui/skin#battlehero/debriefing_awards_best_assault.avif" },
  [BattleHeroesAward.TOP_KIND_MGUN] = { img = "ui/skin#battlehero/debriefing_awards_best_mgun.avif" },
  [BattleHeroesAward.TOP_KIND_ENGINEER] = { img = "ui/skin#battlehero/debriefing_awards_best_engineer.avif" },
  [BattleHeroesAward.TOP_KIND_FLAMETROOPER] = { img = "ui/skin#battlehero/debriefing_awards_best_flametrooper.avif" },
  [BattleHeroesAward.TOP_KIND_PILOT_ASSAULTER] = { img = "ui/skin#battlehero/debriefing_awards_best_pilot_assaulter.avif" },
  [BattleHeroesAward.TOP_KIND_PILOT_FIGHTER] = { img = "ui/skin#battlehero/debriefing_awards_best_pilot_fighter.avif" },
  [BattleHeroesAward.TOP_KIND_MORTARMAN] = { img = "ui/skin#battlehero/debriefing_awards_best_mortarman.avif" },
  [BattleHeroesAward.TOP_KIND_RADIOMAN] = { img = "ui/skin#battlehero/debriefing_awards_best_radioman.avif" },
  [BattleHeroesAward.TOP_KIND_TANKER] = { img = "ui/skin#battlehero/debriefing_awards_best_tanker.avif" },
  [BattleHeroesAward.TOP_KIND_ANTI_TANK] = { img = "ui/skin#battlehero/debriefing_awards_best_anti_tank.avif" },
  [BattleHeroesAward.TOP_KIND_SNIPER] = { img = "ui/skin#battlehero/debriefing_awards_best_sniper.avif" },
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = { img = "ui/skin#battlehero/debriefing_awards_crusher.avif" },
  [BattleHeroesAward.TOP_MELEE_KILLS] = { img = "ui/skin#battlehero/debriefing_awards_melee_specialist.avif" },
  [BattleHeroesAward.TOP_GRENADE_KILLS] = { img = "ui/skin#battlehero/debriefing_awards_explosives_specialist.avif" },
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = { img = "ui/skin#battlehero/debriefing_awards_ranged_specialist.avif" },
  [BattleHeroesAward.TACTICIAN] = { img = "ui/skin#battlehero/debriefing_awards_tactician.avif" },
  [BattleHeroesAward.UNIVERSAL] = { img = "ui/skin#battlehero/debriefing_awards_universal.avif" },
  [BattleHeroesAward.MULTISPECIALIST] = { img = "ui/skin#battlehero/debriefing_awards_multispecialist.avif" },
  [BattleHeroesAward.BATTLE_HEROES_CARD] = { img = "ui/skin#battlehero/debriefing_awards_postcard.avif" },
  [BattleHeroesAward.PLAYER_BATTLE_HERO] = { img = "ui/skin#battlehero/debriefing_awards_mvp.avif" },
}

let mkAwardForegroundIcon = @(img, size) {
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  size
  image = Picture(img)
}

let mkAwardForegroundText = @(text, size) {
  fontSize = size[1]*0.5
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  size
  text
}

let mkAwardValue = @(value, isBig) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  text = value
}.__update(isBig ? h2_txt : sub_txt)

let mkBattleHeroAwardIcon = function(award, size, isActive=true, isBig=false) {
  let awardId = award?.id ?? award
  let icon = battleHeroAwardIcon?[awardId] ?? { text = "?" }
  let tint = isActive ? {} : {tint = Color(40, 40, 40, 120), picSaturate = 0.0}
  return {
    size = size
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      icon?.img != null ? mkAwardForegroundIcon(icon.img, size) : mkAwardForegroundText(icon.text, size)
      award?.value != null ? mkAwardValue(award.value, isBig) : null
    ].map(@(v) v?.__merge(tint))
  }
}

return mkBattleHeroAwardIcon