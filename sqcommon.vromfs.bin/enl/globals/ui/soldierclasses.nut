from "%enlSqGlob/ui_library.nut" import *

let { tactical_font } = require("%enlSqGlob/ui/fonts_style.nut")
let { rankIcons, rankGlyphs } = require("%enlSqGlob/ui/rankIcons.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")

let colorsByRare = [Color(180,180,180), Color(220,220,100)]

let mkRankIcon = @(rank) @(armyId) rankIcons?[armyId][rank]
let mkRankGlyph = @(rank) @(armyId) rankGlyphs?[armyId][rank]

let premiumCfg = {
  isPremium = true
  getIcon = @(armyId) armiesPresentation?[armyId].premIcon
}

let eventCfg = {
  isEvent = true
  getIcon = @(_armyId) "!ui/squads/event_squad_icon.svg"
}

let soldierKinds = freeze({
  unknown = {
    icon = "unknown.svg"
    locId = "Unknown"
  }
  rifle = {
    icon = "rifle.svg"
    iconsByRare = ["rifle.svg", "rifle_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/rifle"
  }
  mgun = {
    icon = "machine_gun.svg"
    iconsByRare = ["machine_gun.svg", "machine_gun_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/mgun"
  }
  assault = {
    icon = "submachine_gun.svg"
    iconsByRare = ["submachine_gun.svg", "submachine_gun_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/assault"
  }
  sniper = {
    icon = "sniper_rifle.svg"
    iconsByRare = ["sniper_rifle.svg", "sniper_rifle_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/sniper"
  }
  anti_tank = {
    icon = "launcher.svg"
    iconsByRare = ["launcher.svg", "launcher_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/anti_tank"
  }
  tanker = {
    icon = "driver_tank.svg"
    iconsByRare = ["driver_tank.svg", "driver_tank_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/tanker"
  }
  radioman = {
    icon = "radioman.svg"
    iconsByRare = ["radioman.svg", "radioman_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/radioman"
  }
  mortarman = {
    icon = "mortarman.svg"
    iconsByRare = ["mortarman.svg", "mortarman_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/mortarman"
  }
  pilot_fighter = {
    icon = "pilot_fighter.svg"
    iconsByRare = ["pilot_fighter.svg", "pilot_fighter_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/pilot_fighter"
  }
  pilot_assaulter = {
    icon = "pilot_assaulter.svg"
    iconsByRare = ["pilot_assaulter.svg", "pilot_assaulter_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/pilot_assaulter"
  }
  flametrooper = {
    icon = "flametrooper.svg"
    iconsByRare = ["flametrooper.svg", "flametrooper_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/flametrooper"
  }
  engineer = {
    icon = "engineer.svg"
    iconsByRare = ["engineer.svg", "engineer_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/engineer"
  }
  biker = {
    icon = "biker.svg"
    iconsByRare = ["biker.svg", "biker_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/biker"
  }
  medic = {
    icon = "medic.svg"
    iconsByRare = ["medic.svg", "medic_veteran.svg"]
    colorsByRare = colorsByRare
    locId = "soldierClass/medic"
  }
})

let soldierClasses = freeze({
  unknown = {
    locId = ""
    getIcon = @(_) null
    getGlyph = @(_) null
    rank = 0
    kind = "unknown"
  }
  rifle = {
    locId = "soldierClass/rifle"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "rifle"
  }
  tutorial_rifle = {
    locId = "soldierClass/rifle"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "rifle"
  }
  rifle_uk = {
    locId = "soldierClass/rifle"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "rifle"
  }
  rifle_it = {
    locId = "soldierClass/rifle"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "rifle"
  }
  rifle_2 = {
    locId = "soldierClass/rifle_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "rifle"
  }
  rifle_3 = {
    locId = "soldierClass/rifle_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "rifle"
  }
  mgun = {
    locId = "soldierClass/mgun"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "mgun"
  }
  mgun_2 = {
    locId = "soldierClass/mgun_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "mgun"
  }
  mgun_3 = {
    locId = "soldierClass/mgun_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "mgun"
  }
  assault = {
    locId = "soldierClass/assault"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "assault"
  }
  assault_2 = {
    locId = "soldierClass/assault_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "assault"
  }
  assault_3 = {
    locId = "soldierClass/assault_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "assault"
  }
  assault_4 = {
    locId = "soldierClass/assault_4"
    getIcon = mkRankIcon(4)
    getGlyph = mkRankGlyph(4)
    rank = 4
    kind = "assault"
  }
  sniper = {
    locId = "soldierClass/sniper"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "sniper"
  }
  sniper_2 = {
    locId = "soldierClass/sniper_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "sniper"
  }
  sniper_3 = {
    locId = "soldierClass/sniper_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "sniper"
  }
  anti_tank = {
    locId = "soldierClass/anti_tank"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "anti_tank"
  }
  anti_tank_2 = {
    locId = "soldierClass/anti_tank_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "anti_tank"
  }
  tanker = {
    locId = "soldierClass/tanker"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "tanker"
  }
  tanker_it = {
    locId = "soldierClass/tanker"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "tanker"
  }
  tanker_uk = {
    locId = "soldierClass/tanker"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "tanker"
  }
  tanker_2 = {
    locId = "soldierClass/tanker_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "tanker"
  }
  tanker_3 = {
    locId = "soldierClass/tanker_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "tanker"
  }
  radioman = {
    locId = "soldierClass/radioman"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "radioman"
  }
  radioman_2 = {
    locId = "soldierClass/radioman_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "radioman"
  }
  mortarman = {
    locId = "soldierClass/mortarman"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "mortarman"
  }
  mortarman_2 = {
    locId = "soldierClass/mortarman_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "mortarman"
  }
  pilot_fighter = {
    locId = "soldierClass/pilot_fighter"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "pilot_fighter"
  }
  pilot_fighter_2 = {
    locId = "soldierClass/pilot_fighter_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "pilot_fighter"
  }
  pilot_fighter_3 = {
    locId = "soldierClass/pilot_fighter_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "pilot_fighter"
  }
  pilot_assaulter = {
    locId = "soldierClass/pilot_assaulter"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "pilot_assaulter"
  }
  pilot_assaulter_uk = {
    locId = "soldierClass/pilot_assaulter"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "pilot_assaulter"
  }
  pilot_assaulter_it = {
    locId = "soldierClass/pilot_assaulter"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "pilot_assaulter"
  }
  pilot_assaulter_2 = {
    locId = "soldierClass/pilot_assaulter_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "pilot_assaulter"
  }
  pilot_assaulter_3 = {
    locId = "soldierClass/pilot_assaulter_3"
    getIcon = mkRankIcon(3)
    getGlyph = mkRankGlyph(3)
    rank = 3
    kind = "pilot_assaulter"
  }
  flametrooper = {
    locId = "soldierClass/flametrooper"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "flametrooper"
  }
  flametrooper_2 = {
    locId = "soldierClass/flametrooper_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "flametrooper"
  }
  engineer = {
    locId = "soldierClass/engineer"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "engineer"
  }
  tutorial_engineer = {
    locId = "soldierClass/engineer"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "engineer"
  }
  engineer_uk = {
    locId = "soldierClass/engineer"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "engineer"
  }
  engineer_it = {
    locId = "soldierClass/engineer"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "engineer"
  }
  engineer_2 = {
    locId = "soldierClass/engineer_2"
    getIcon = mkRankIcon(2)
    getGlyph = mkRankGlyph(2)
    rank = 2
    kind = "engineer"
  }
  biker = {
    locId = "soldierClass/biker"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "biker"
  }
  medic = {
    locId = "soldierClass/medic"
    getIcon = mkRankIcon(1)
    getGlyph = mkRankGlyph(1)
    rank = 1
    kind = "medic"
  }

 // FIXME looks like legacy data
//PREMIUM
  rifle_3_premium_1 = {
    locId = "soldierClass/rifle"
    getGlyph = @(_) null
    rank = 10
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_3_premium_2 = {
    locId = "soldierClass/rifle"
    getGlyph = @(_) null
    rank = 10
    kind = "rifle"
  }.__update(premiumCfg)
  radioman_2_premium_1 = {
    locId = "soldierClass/radioman"
    getGlyph = @(_) null
    rank = 10
    kind = "radioman"
  }.__update(premiumCfg)
  radioman_2_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  radioman_2_premium_1_ch = {
    locId = "soldierClass/radioman"
    getGlyph = @(_) null
    rank = 10
    kind = "radioman"
  }.__update(premiumCfg)
  radioman_2_premium_1_engineer_ch = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_1_ch = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_2 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_premium_2_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  assault_premium_3 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_1_premium_1 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_1 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_2 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_2_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_2_ch = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_2_premium_2_engineer_ch = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  assault_2_premium_2_event = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(eventCfg)
  assault_2_premium_2_event_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(eventCfg)
  assault_2_premium_2_event_anti_tank = {
    locId = "soldierClass/anti_tank"
    getGlyph = @(_) null
    rank = 10
    kind = "anti_tank"
  }.__update(eventCfg)
  assault_3_premium_1 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  assault_3_premium_2 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(premiumCfg)
  assault_3_premium_2_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_premium_1 = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_premium_1_ch = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_premium_1_legacy = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_2_premium_1 = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_2_engineer_premium_1 = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_2_event_1 = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(eventCfg)
  mgun_3_premium_1 = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  mgun_3_premium_2 = {
    locId = "soldierClass/mgun"
    getGlyph = @(_) null
    rank = 10
    kind = "mgun"
  }.__update(premiumCfg)
  mgun_3_premium_2_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  sniper_2_premium_1 = {
    locId = "soldierClass/sniper"
    getGlyph = @(_) null
    rank = 10
    kind = "sniper"
  }.__update(premiumCfg)
  sniper_2_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_1 = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_2 = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_premium_2_ch = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  engineer_2_premium_1 = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  medic_1_premium_1 = {
    locId = "soldierClass/medic"
    getGlyph = @(_) null
    rank = 10
    kind = "medic"
  }.__update(premiumCfg)
  medic_1_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  medic_2_premium_1 = {
    locId = "soldierClass/medic"
    getGlyph = @(_) null
    rank = 10
    kind = "medic"
  }.__update(premiumCfg)
  medic_2_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  flametrooper_2_premium_1 = {
    locId = "soldierClass/flametrooper"
    getGlyph = @(_) null
    rank = 10
    kind = "flametrooper"
  }.__update(premiumCfg)
  flametrooper_2_premium_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
  tanker_premium_1 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_1_premium_1 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_2 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_premium_2_flametrooper = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_2_premium_1 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_1 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_2 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_3 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_4 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  tanker_3_premium_5 = {
    locId = "soldierClass/tanker"
    getGlyph = @(_) null
    rank = 10
    kind = "tanker"
  }.__update(premiumCfg)
  pilot_fighter_premium_1 = {
    locId = "soldierClass/pilot_fighter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_premium_2 = {
    locId = "soldierClass/pilot_fighter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_2_premium_1 = {
    locId = "soldierClass/pilot_fighter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_1 = {
    locId = "soldierClass/pilot_fighter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_2 = {
    locId = "soldierClass/pilot_fighter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_fighter_3_premium_3 = {
    locId = "soldierClass/pilot_fighter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_fighter"
  }.__update(premiumCfg)
  pilot_assaulter_premium_1 = {
    locId = "soldierClass/pilot_assaulter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_2_premium_1 = {
    locId = "soldierClass/pilot_assaulter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_2_premium_2 = {
    locId = "soldierClass/pilot_assaulter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_3_premium_1 = {
    locId = "soldierClass/pilot_assaulter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  pilot_assaulter_3_premium_2 = {
    locId = "soldierClass/pilot_assaulter"
    getGlyph = @(_) null
    rank = 10
    kind = "pilot_assaulter"
  }.__update(premiumCfg)
  rifle_premium_1 = {
    locId = "soldierClass/rifle"
    getGlyph = @(_) null
    rank = 10
    kind = "rifle"
  }.__update(premiumCfg)
  rifle_2_event_1 = {
    locId = "soldierClass/rifle"
    getGlyph = @(_) null
    rank = 10
    kind = "rifle"
  }.__update(eventCfg)
  assault_event_1 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(eventCfg)
  assault_1_event_1 = {
    locId = "soldierClass/assault"
    getGlyph = @(_) null
    rank = 10
    kind = "assault"
  }.__update(eventCfg)
  assault_1_event_1_engineer = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(eventCfg)
  biker_premium_1 = {
    locId = "soldierClass/biker"
    getGlyph = @(_) null
    rank = 10
    kind = "biker"
  }.__update(premiumCfg)
  biker_engineer_premium_1 = {
    locId = "soldierClass/engineer"
    getGlyph = @(_) null
    rank = 10
    kind = "engineer"
  }.__update(premiumCfg)
})

const GLYPHS_TAG = "t"

let mkGlyphsStyle = @(params = hdpx(16)) {
  [GLYPHS_TAG] = {}.__update(tactical_font, typeof params == "table" ? params : { fontSize = params })
}

let getClassCfg = @(sClass) soldierClasses?[sClass] ?? soldierClasses.unknown

let getKindCfg = @(sKind) soldierKinds?[sKind] ?? soldierKinds.unknown

let formatGlyph = @(glyph) glyph == null ? null : $"<{GLYPHS_TAG}>{glyph}</{GLYPHS_TAG}>"

let function getClassNameWithGlyph(sClass, armyId){
  let { getGlyph, locId } = getClassCfg(sClass)
  let glyph = formatGlyph(getGlyph(armyId))
  let className = loc(locId)
  return glyph ? $"{glyph} {className}" : className
}

let soldierKindsList = soldierKinds.keys()
  .filter(@(k) k != "unknown")
  .sort(@(a, b) a <=> b)

return {
  soldierClasses
  soldierKinds
  soldierKindsList
  getClassCfg
  getKindCfg
  mkGlyphsStyle
  formatGlyph
  getClassNameWithGlyph
}
