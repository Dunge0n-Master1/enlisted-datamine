from "%enlSqGlob/ui_library.nut" import *

let pPointsBaseParams = {
  vitality = {
    icon = "ui/skin#perks/perk_vitality.svg"
    color = Color(255,150,150)
  }
  weapon = {
    icon = "ui/skin#perks/perk_battleskill.svg"
    color = Color(255,255,150)
  }
  speed = {
    icon = "ui/skin#perks/perk_speed.svg"
    color = Color(150,255,150)
  }
}

let pPointsList = []
foreach (pPointId, _ in pPointsBaseParams)
  pPointsList.append(pPointId)
pPointsList.sort(@(a, b) a <=> b)

return {
  pPointsList
  pPointsBaseParams
}
