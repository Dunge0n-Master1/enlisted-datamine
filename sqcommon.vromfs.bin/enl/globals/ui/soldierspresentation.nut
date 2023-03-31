const SOLDIER_USSR = "ui/squads/ussr/ussr_hero_medal_1_icon.svg"
const SOLDIER_USA = "ui/squads/usa/usa_hero_medal_1_icon.svg"
const SOLDIER_GERMANY = "ui/squads/germany/ger_hero_medal_1_icon.svg"
const SOLDIER_UK = "ui/squads/usa/uk_hero_medal_1_icon.svg"
const SOLDIER_ITALY = "ui/squads/germany/italy_hero_medal_1_icon.svg"
const SOLDIER_JAPAN = "ui/squads/japan/jap_hero_medal_1_icon.svg"

return freeze({
  // FIXME backward compatibility for debriefing data from old server
  normandy_allies   = SOLDIER_USA
  normandy_axis     = SOLDIER_GERMANY
  moscow_allies     = SOLDIER_USSR
  moscow_axis       = SOLDIER_GERMANY
  berlin_allies     = SOLDIER_USSR
  berlin_axis       = SOLDIER_GERMANY
  tunisia_allies    = SOLDIER_UK
  tunisia_axis      = SOLDIER_ITALY
  stalingrad_allies = SOLDIER_USSR
  stalingrad_axis   = SOLDIER_GERMANY
  pacific_allies    = SOLDIER_USA
  pacific_axis      = SOLDIER_JAPAN

  britain     = SOLDIER_UK
  germany     = SOLDIER_GERMANY
  italy       = SOLDIER_ITALY
  japan       = SOLDIER_JAPAN
  morocco     = SOLDIER_UK // probably this country have no heroes
  usa         = SOLDIER_USA
  ussr        = SOLDIER_USSR
  ussr_female = SOLDIER_USSR
})