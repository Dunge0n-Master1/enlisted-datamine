from "%enlSqGlob/ui_library.nut" import *

let campaignTitle = require("campaign_title_small.ui.nut")
let { mkArmyIcon, mkArmyName } = require("%enlist/soldiers/components/armyPackage.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")

let curArmyComp = @(){
  flow = FLOW_HORIZONTAL
  children = [
    mkArmyIcon(curArmy.value)
    mkArmyName(curArmy.value, true, 0)
  ]
}

return {
  flow = FLOW_VERTICAL
  children = [campaignTitle, curArmyComp ]
}
