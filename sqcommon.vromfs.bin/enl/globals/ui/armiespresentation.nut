let DEFAULT_SQUAD_GER = "balkenkreuz.svg"
let DEFAULT_SQUAD_USSR = "ussr.svg"
let DEFAULT_SQUAD_USA = "usaf.svg"
let DEFAULT_SQUAD_JAP = "japan.svg"
const SMALL_SQUAD_GER = "army_icons/germany_army.svg"
const SMALL_SQUAD_USSR = "army_icons/ussr_army.svg"
const SMALL_SQUAD_USA = "army_icons/usa_army.svg"
const SMALL_SQUAD_JAP = "army_icons/japan_army.svg"
const SMALL_COLOR_SQUAD_GER = "army_icons/germany_color_small.svg"
const SMALL_COLOR_SQUAD_USSR = "army_icons/ussr_color_small.svg"
const SMALL_COLOR_SQUAD_USA = "army_icons/usa_color_small.svg"
const SMALL_COLOR_SQUAD_JAP = "army_icons/japan_color_small.svg"
let PREM_SQUAD_GER = "!ui/squads/germany/prem_squad_ger.svg"
let PREM_SQUAD_USSR = "!ui/squads/ussr/prem_squad_ussr.svg"
let PREM_SQUAD_USA = "!ui/squads/ussr/prem_squad_ussr.svg" // TODO probably needed different icon for USA
let PREM_SQUAD_JAP = "!ui/squads/japan/prem_squad_jap.svg"

return freeze({
  normandy_allies = {
    promoImage = "ui/soldiers/usa/usa_normandy_rifle_1_image.avif"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    smallColorIcon = SMALL_COLOR_SQUAD_USA
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
    smallColorIcon = SMALL_COLOR_SQUAD_GER
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
    smallColorIcon = SMALL_COLOR_SQUAD_USSR
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
    smallColorIcon = SMALL_COLOR_SQUAD_GER
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
    smallColorIcon = SMALL_COLOR_SQUAD_USSR
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
    smallColorIcon = SMALL_COLOR_SQUAD_GER
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
    smallColorIcon = SMALL_COLOR_SQUAD_USA
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
    smallColorIcon = SMALL_COLOR_SQUAD_GER
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
    smallColorIcon = SMALL_COLOR_SQUAD_USSR
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
    smallColorIcon = SMALL_COLOR_SQUAD_GER
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
    smallColorIcon = SMALL_COLOR_SQUAD_USA
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
    smallColorIcon = SMALL_COLOR_SQUAD_JAP
    premIcon = PREM_SQUAD_JAP
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_pacific_solo.avif"
  }
  common_ussr = {
    promoImage = "ui/soldiers/ussr/ussr_moscow_radioman_1_image.avif"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    smallColorIcon = SMALL_COLOR_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_moscow_solo.avif"
  }
  common_usa = {
    promoImage = "ui/soldiers/usa/usa_normandy_rifle_1_image.avif"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    smallColorIcon = SMALL_COLOR_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_normandy_solo.avif"
  }
  common_ger = {
    promoImage = "ui/soldiers/germany/ger_berlin_assault_2_image.avif"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    smallColorIcon = SMALL_COLOR_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_berlin_solo_ger.avif"
  }
  common_jap = {
    promoImage = "ui/soldiers/japan/axis_pacific_mgun_1_image.avif"
    icon = DEFAULT_SQUAD_JAP
    smallIcon = SMALL_SQUAD_JAP
    smallColorIcon = SMALL_COLOR_SQUAD_JAP
    premIcon = PREM_SQUAD_JAP
    tutorialImage = "ui/game_mode_tutorial_2.avif"
    tutorialTankImage = "ui/game_mode_tutorial_tank.avif"
    practiceImage = "ui/game_mode_practice.avif"
    customGameImage = "ui/game_mode_pacific_solo.avif"
  }
})
