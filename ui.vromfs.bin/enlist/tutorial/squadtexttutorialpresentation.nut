from "%enlSqGlob/ui_library.nut" import *

let tutorials = freeze({
  anti_tank = [
    {
      text   = "anti_tank_available_controls_hint_01"
      image  = "ui/game_mode_tutorial_anti_tank_01.avif"
    }
    {
      text   = "anti_tank_available_controls_hint_02"
      image  = "ui/game_mode_tutorial_anti_tank_01.avif"
    }
    {
      hotkey = ["Human.WeaponNext"]
      text   = "anti_tank_available_controls_hint_03"
      image  = "ui/game_mode_tutorial_anti_tank_02.avif"
    }
    {
      hotkey = ["Human.SightNext"]
      text   = "anti_tank_available_controls_hint_04"
      image  = "ui/game_mode_tutorial_anti_tank_03.avif"
    }
    {
      hotkey = ["Human.Shoot"]
      text   = "anti_tank_available_controls_hint_05"
      image  = "ui/game_mode_tutorial_anti_tank_04.avif"
    }
    {
      text   = "anti_tank_available_controls_hint_06"
      image  = "ui/game_mode_tutorial_anti_tank_05.avif"
    }
  ]

  mortarman = [
    {
      text   = "mortarman_available_controls_hint_01"
      image  = "ui/game_mode_tutorial_mortarman_01.avif"
    }
    {
      hotkey = ["Human.WeaponNext"]
      text   = "mortarman_available_controls_hint_02"
      image  = "ui/game_mode_tutorial_mortarman_02.avif"
    }
    {
      hotkey = ["Human.Aim"]
      text   = "mortarman_available_controls_hint_03"
      image  = "ui/game_mode_tutorial_mortarman_03.avif"
    }
    {
      hotkey = ["Human.Shoot"]
      text   = "mortarman_available_controls_hint_04"
      image  = "ui/game_mode_tutorial_mortarman_04.avif"
    }
    {
      text   = "mortarman_available_controls_hint_05"
      image  = "ui/game_mode_tutorial_mortarman_05.avif"
    }
    {
      text   = "mortarman_available_controls_hint_06"
      image  = "ui/game_mode_tutorial_mortarman_06.avif"
    }
  ]

  radioman = [
    {
      text   = "radioman_available_controls_hint_01"
      image  = "ui/game_mode_tutorial_radioman_01.avif"
    }
    {
      hotkey = ["Human.ArtilleryStrike"]
      text   = "radioman_available_controls_hint_02"
      image  = "ui/game_mode_tutorial_radioman_02.avif"
    }
    {
      hotkey = ["Human.Shoot"]
      text   = "radioman_available_controls_hint_04"
      image  = "ui/game_mode_tutorial_radioman_03.avif"
    }
    {
      text   = "radioman_available_controls_hint_05"
      image  = "ui/game_mode_tutorial_radioman_04.avif"
    }
  ]
})

let getTutorial = @(squadType) tutorials?[squadType] ?? []

return {
  getTutorial
  tutorials
}