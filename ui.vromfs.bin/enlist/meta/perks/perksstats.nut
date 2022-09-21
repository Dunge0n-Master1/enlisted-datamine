from "%enlSqGlob/ui_library.nut" import *

let serverConfigs = require("%enlist/meta/configs.nut")

const RECOMMENDED_PERKS_COUNT = 5

let CLASSES = {
  NONE     = 0x00
  VITALITY = 0x01
  WEAPON   = 0x02
  SPEED    = 0x04
}

let classesConfig = {
  [CLASSES.NONE] = { image = "ui/skin#perks/perk_empty.svg"},
  [CLASSES.VITALITY] = { image = "ui/skin#perks/perk_vitality.svg"},
  [CLASSES.WEAPON] = { image = "ui/skin#perks/perk_battleskill.svg"},
  [CLASSES.SPEED] = { image = "ui/skin#perks/perk_speed.svg"},
  [CLASSES.VITALITY | CLASSES.WEAPON] = { image = "ui/skin#perks/perk_vitality_battleskill.svg"},
  [CLASSES.VITALITY | CLASSES.SPEED] = { image = "ui/skin#perks/perk_vitality_speed.svg"},
  [CLASSES.WEAPON | CLASSES.SPEED] = { image = "ui/skin#perks/perk_speed_battleskill.svg"},
  [CLASSES.VITALITY | CLASSES.WEAPON | CLASSES.SPEED] = { image = "ui/skin#perks/perk_vitality_speed_battleskill.svg"}
}


let stats = persist("stats", @() {})
serverConfigs.configs.subscribe(
  function(v) {
    let perkStats = v?.perks?.stats
    if (perkStats == null)
      return

    stats.clear()
    stats.__update(perkStats)
})

return {
  stats
  classesConfig
  fallBackImage = classesConfig[CLASSES.NONE]
  RECOMMENDED_PERKS_COUNT
}