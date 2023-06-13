from "%enlSqGlob/ui_library.nut" import *

let armySelectUi = require("army_select.ui.nut")
let { mkSquadsList } = require("%enlist/soldiers/squads_list.ui.nut")
let { mkSquadInfo } = require("squad_info.ui.nut")
let mkSoldierInfo = require("mkSoldierInfo.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let gotoResearchUpgradeMsgBox = require("researchUpgradeMsgBox.nut")
let { promoWidget } = require("%enlist/components/mkPromoWidget.nut")
let { bigPadding, contentOffset } = require("%enlSqGlob/ui/designConst.nut")


let function mkSoldiersUi(){
  let squad_info = mkSquadInfo()
  let squads_list = mkSquadsList()

  let mainContent = {
    size = flex()
    flow = FLOW_VERTICAL
    margin = [contentOffset,0,0,0]
    gap = bigPadding
    children = [
      armySelectUi
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          squads_list
          squad_info
          mkSoldierInfo({ soldierInfoWatch = curSoldierInfo, onResearchClickCb = gotoResearchUpgradeMsgBox})
          {
            size = flex()
            halign = ALIGN_RIGHT
            children = promoWidget("soldier_equip", "soldier_inventory")
          }
        ]
      }
    ]
  }

  return mainContent
}

return {mkSoldiersUi}
