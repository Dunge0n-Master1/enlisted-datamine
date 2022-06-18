from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { BattleHeroesAward } = require("battleHeroesAwards.nut")

let battleHeroAwardIcon = {
  [BattleHeroesAward.TOP_PLACE] = { img = "ui/skin#battlehero/debriefing_awards_first_place.png" },
  [BattleHeroesAward.TOP_VEHICLE_SQUAD] = { img = "ui/skin#battlehero/debriefing_awards_best_mechanic.png" },
  [BattleHeroesAward.TOP_INFANTRY_SQUAD] = { img = "ui/skin#battlehero/debriefing_awards_best_infantryman.png" },
  [BattleHeroesAward.TOP_KIND_RIFLE] = { img = "ui/skin#battlehero/debriefing_awards_best_rifle.png" },
  [BattleHeroesAward.TOP_KIND_ASSAULT] = { img = "ui/skin#battlehero/debriefing_awards_best_assault.png" },
  [BattleHeroesAward.TOP_KIND_MGUN] = { img = "ui/skin#battlehero/debriefing_awards_best_mgun.png" },
  [BattleHeroesAward.TOP_KIND_ENGINEER] = { img = "ui/skin#battlehero/debriefing_awards_best_engineer.png" },
  [BattleHeroesAward.TOP_KIND_FLAMETROOPER] = { img = "ui/skin#battlehero/debriefing_awards_best_flametrooper.png" },
  [BattleHeroesAward.TOP_KIND_PILOT_ASSAULTER] = { img = "ui/skin#battlehero/debriefing_awards_best_pilot_assaulter.png" },
  [BattleHeroesAward.TOP_KIND_PILOT_FIGHTER] = { img = "ui/skin#battlehero/debriefing_awards_best_pilot_fighter.png" },
  [BattleHeroesAward.TOP_KIND_MORTARMAN] = { img = "ui/skin#battlehero/debriefing_awards_best_mortarman.png" },
  [BattleHeroesAward.TOP_KIND_RADIOMAN] = { img = "ui/skin#battlehero/debriefing_awards_best_radioman.png" },
  [BattleHeroesAward.TOP_KIND_TANKER] = { img = "ui/skin#battlehero/debriefing_awards_best_tanker.png" },
  [BattleHeroesAward.TOP_KIND_ANTI_TANK] = { img = "ui/skin#battlehero/debriefing_awards_best_anti_tank.png" },
  [BattleHeroesAward.TOP_KIND_SNIPER] = { img = "ui/skin#battlehero/debriefing_awards_best_sniper.png" },
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = { img = "ui/skin#battlehero/debriefing_awards_crusher.png" },
  [BattleHeroesAward.TOP_MELEE_KILLS] = { img = "ui/skin#battlehero/debriefing_awards_melee_specialist.png" },
  [BattleHeroesAward.TOP_GRENADE_KILLS] = { img = "ui/skin#battlehero/debriefing_awards_explosives_specialist.png" },
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = { img = "ui/skin#battlehero/debriefing_awards_ranged_specialist.png" },
  [BattleHeroesAward.TACTICIAN] = { img = "ui/skin#battlehero/debriefing_awards_tactician.png" },
  [BattleHeroesAward.UNIVERSAL] = { img = "ui/skin#battlehero/debriefing_awards_universal.png" },
  [BattleHeroesAward.MULTISPECIALIST] = { img = "ui/skin#battlehero/debriefing_awards_multispecialist.png" },
  [BattleHeroesAward.BATTLE_HEROES_CARD] = { img = "ui/skin#battlehero/debriefing_awards_postcard.png" },
  [BattleHeroesAward.PLAYER_BATTLE_HERO] = { img = "ui/skin#battlehero/debriefing_awards_mvp.png" },
}

let mkAwardForegroundIcon = @(img, size) {
  rendObj = ROBJ_IMAGE
  keepAspect = true
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