let { isNewDesign } = require("%enlSqGlob/designState.nut")

let DEFAULT_SQUAD_GER = isNewDesign.value
  ? "army_icons/germany_army.svg"
  : "balkenkreuz.svg"
let DEFAULT_SQUAD_USSR = isNewDesign.value
  ? "army_icons/ussr_army.svg"
  : "ussr.svg"
let DEFAULT_SQUAD_USA = isNewDesign.value
  ? "army_icons/usa_army.svg"
  : "usaf.svg"
let DEFAULT_SQUAD_JAP = isNewDesign.value
  ? "army_icons/jap_army.svg"
  : "japan.svg"
const SMALL_SQUAD_GER = "army_icons/germany_color_small.svg"
const SMALL_SQUAD_USSR = "army_icons/ussr_color_small.svg"
const SMALL_SQUAD_USA = "army_icons/usa_color_small.svg"
const SMALL_SQUAD_JAP = "army_icons/japan_color_small.svg"
let PREM_SQUAD_GER = isNewDesign.value
  ? "!ui/squads/germany/squad_prem_ger.svg"
  : "!ui/squads/germany/prem_squad_ger.svg"
let PREM_SQUAD_USSR = isNewDesign.value
  ? "!ui/squads/ussr/squad_prem_ussr.svg"
  : "!ui/squads/ussr/prem_squad_ussr.svg"
let PREM_SQUAD_USA = isNewDesign.value
  ? "!ui/squads/ussr/squad_prem_ussr.svg"
  : "!ui/squads/ussr/prem_squad_ussr.svg" // TODO probably needed different icon for USA
let PREM_SQUAD_JAP = isNewDesign.value
  ? "!ui/squads/japan/squad_prem_jap.svg"
  : "!ui/squads/japan/prem_squad_jap.svg"

return freeze({
  normandy_allies = {
    promoImage = "ui/soldiers/usa/usa_normandy_rifle_1_image.avif"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_normandy_solo.avif"
  }
  normandy_axis = {
    promoImage  = "ui/soldiers/germany/ger_normandy_assault_2_image.avif"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_normandy_solo.avif"
  }
  moscow_allies = {
    promoImage = "ui/soldiers/ussr/ussr_moscow_radioman_1_image.avif"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_moscow_solo.avif"
  }
  moscow_axis = {
    promoImage = "ui/soldiers/germany/ger_moscow_mgun_1_image.avif"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_moscow_solo.avif"
  }
  berlin_allies = {
    promoImage = "ui/soldiers/ussr/ussr_berlin_assault_2_image.avif"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_berlin_solo_ger.avif"
  }
  berlin_axis = {
    promoImage = "ui/soldiers/germany/ger_berlin_assault_2_image.avif"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_berlin_solo_ger.avif"
  }
  tunisia_allies = {
    promoImage = "ui/soldiers/usa/allies_tunisia_assault_1_image.avif"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_tunisia_solo.avif"
  }
  tunisia_axis = {
    promoImage = "ui/soldiers/germany/axis_tunisia_engineer_1_image.avif"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_tunisia_solo.avif"
  }
  stalingrad_allies = {
    promoImage = "ui/soldiers/ussr/allies_stalingrad_radioman_1_image.avif"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_stalingrad_solo.avif"
  }
  stalingrad_axis = {
    promoImage = "ui/soldiers/germany/axis_stalingrad_mgun_1_image.avif"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_stalingrad_solo.avif"
  }
  pacific_allies = {
    promoImage = "ui/soldiers/usa/allies_pacific_assault_2_image.avif"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_pacific_solo.avif"
  }
  pacific_axis = {
    promoImage = "ui/soldiers/japan/axis_pacific_mgun_1_image.avif"
    icon = DEFAULT_SQUAD_JAP
    smallIcon = SMALL_SQUAD_JAP
    premIcon = PREM_SQUAD_JAP
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_pacific_solo.avif"
  }
})
