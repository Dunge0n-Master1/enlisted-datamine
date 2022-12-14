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
    promoImage = "ui/soldiers/usa/usa_normandy_rifle_1_image.jpg"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_normandy_solo.jpg"
  }
  normandy_axis = {
    promoImage  = "ui/soldiers/germany/ger_normandy_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_normandy_solo.jpg"
  }
  moscow_allies = {
    promoImage = "ui/soldiers/ussr/ussr_moscow_radioman_1_image.jpg"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_moscow_solo.jpg"
  }
  moscow_axis = {
    promoImage = "ui/soldiers/germany/ger_moscow_mgun_1_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_moscow_solo.jpg"
  }
  berlin_allies = {
    promoImage = "ui/soldiers/ussr/ussr_berlin_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_berlin_solo_ger.jpg"
  }
  berlin_axis = {
    promoImage = "ui/soldiers/germany/ger_berlin_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_berlin_solo_ger.jpg"
  }
  tunisia_allies = {
    promoImage = "ui/soldiers/usa/allies_tunisia_assault_1_image.jpg"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_tunisia_solo.jpg"
  }
  tunisia_axis = {
    promoImage = "ui/soldiers/germany/axis_tunisia_engineer_1_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_tunisia_solo.jpg"
  }
  stalingrad_allies = {
    promoImage = "ui/soldiers/ussr/allies_stalingrad_radioman_1_image.jpg"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_stalingrad_solo.jpg"
  }
  stalingrad_axis = {
    promoImage = "ui/soldiers/germany/axis_stalingrad_mgun_1_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_stalingrad_solo.jpg"
  }
  pacific_allies = {
    promoImage = "ui/soldiers/usa/allies_pacific_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_pacific_solo.jpg"
  }
  pacific_axis = {
    promoImage = "ui/soldiers/japan/axis_pacific_mgun_1_image.jpg"
    icon = DEFAULT_SQUAD_JAP
    smallIcon = SMALL_SQUAD_JAP
    premIcon = PREM_SQUAD_JAP
    tutorialImage = "ui/game_mode_tutorial_2.jpg"
    tutorialTankImage = "ui/game_mode_tutorial_tank.jpg"
    practiceImage = "ui/game_mode_practice.jpg"
    customGameImage = "ui/game_mode_pacific_solo.jpg"
  }
})
