let SOLDIER_USSR = {
  heroIcon = "ui/squads/ussr/ussr_hero_medal_1_icon.svg"
}

let SOLDIER_USA = {
  heroIcon = "ui/squads/usa/usa_hero_medal_1_icon.svg"
}

let SOLDIER_GERMANY = {
  heroIcon = "ui/squads/germany/ger_hero_medal_1_icon.svg"
}

let SOLDIER_UK = {
  heroIcon = "ui/squads/usa/uk_hero_medal_1_icon.svg"
}

let SOLDIER_ITALY = {
  heroIcon = "ui/squads/germany/italy_hero_medal_1_icon.svg"
}

let SOLDIER_JAPAN = {
  heroIcon = "ui/squads/japan/jap_hero_medal_1_icon.svg"
}

return freeze({
  normandy_allies = SOLDIER_USA
  normandy_axis   = SOLDIER_GERMANY
  moscow_allies   = SOLDIER_USSR
  moscow_axis     = SOLDIER_GERMANY
  berlin_allies   = SOLDIER_USSR
  berlin_axis     = SOLDIER_GERMANY
  tunisia_allies  = SOLDIER_UK
  tunisia_axis    = SOLDIER_ITALY
  stalingrad_allies   = SOLDIER_USSR
  stalingrad_axis     = SOLDIER_GERMANY
  pacific_allies   = SOLDIER_USA
  pacific_axis     = SOLDIER_JAPAN
})