const DEFAULT_SQUAD_GER = "balkenkreuz.svg"
const DEFAULT_SQUAD_USSR = "ussr.svg"
const DEFAULT_SQUAD_USA = "usaf.svg"
const SMALL_SQUAD_GER = "army_icons/germany_color_small.svg"
const SMALL_SQUAD_USSR = "army_icons/ussr_color_small.svg"
const SMALL_SQUAD_USA = "army_icons/usa_color_small.svg"
const PREM_SQUAD_GER = "!ui/squads/germany/prem_squad_ger.svg"
const PREM_SQUAD_USSR = "!ui/squads/ussr/prem_squad_ussr.svg"
const PREM_SQUAD_USA = "!ui/squads/ussr/prem_squad_ussr.svg" // TODO probably needed different icon for USA

return freeze({
  normandy_allies = {
    promoImage = "ui/soldiers/usa/usa_normandy_rifle_1_image.jpg"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_normandy_solo"
  }
  normandy_axis = {
    promoImage  = "ui/soldiers/germany/ger_normandy_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_normandy_solo"
  }
  moscow_allies = {
    promoImage = "ui/soldiers/ussr/ussr_moscow_radioman_1_image.jpg"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_moscow_solo"
  }
  moscow_axis = {
    promoImage = "ui/soldiers/germany/ger_moscow_mgun_1_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_moscow_solo"
  }
  berlin_allies = {
    promoImage = "ui/soldiers/ussr/ussr_berlin_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_berlin_solo_ger"
  }
  berlin_axis = {
    promoImage = "ui/soldiers/germany/ger_berlin_assault_2_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_berlin_solo_ger"
  }
  tunisia_allies = {
    promoImage = "ui/soldiers/usa/allies_tunisia_assault_1_image.jpg"
    icon = DEFAULT_SQUAD_USA
    smallIcon = SMALL_SQUAD_USA
    premIcon = PREM_SQUAD_USA
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_tunisia_solo"
  }
  tunisia_axis = {
    promoImage = "ui/soldiers/germany/axis_tunisia_engineer_1_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_tunisia_solo"
  }
  stalingrad_allies = {
    promoImage = "ui/soldiers/ussr/allies_stalingrad_radioman_1_image.jpg"
    icon = DEFAULT_SQUAD_USSR
    smallIcon = SMALL_SQUAD_USSR
    premIcon = PREM_SQUAD_USSR
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_stalingrad_solo"
  }
  stalingrad_axis = {
    promoImage = "ui/soldiers/germany/axis_stalingrad_mgun_1_image.jpg"
    icon = DEFAULT_SQUAD_GER
    smallIcon = SMALL_SQUAD_GER
    premIcon = PREM_SQUAD_GER
    tutorialImage = "ui/game_mode_tutorial_2"
    tutorialTankImage = "ui/game_mode_tutorial_tank"
    practiceImage = "ui/game_mode_practice"
    customGameImage = "ui/game_mode_stalingrad_solo"
  }
})
