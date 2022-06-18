from "%enlSqGlob/ui_library.nut" import *

let { body_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let { multySquadPanelSize, listCtors, bigGap, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { txtColor } = listCtors
let { curArmy, curSquadId, setCurSquadId, curChoosenSquads, curUnlockedSquads
} = require("model/state.nut")
let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let { notChoosenPerkSquads } = require("model/soldierPerks.nut")
let { unseenSquadsWeaponry } = require("model/unseenWeaponry.nut")
let { unseenSquadsVehicle } = require("%enlist/vehicles/unseenVehicles.nut")
let { unseenSquads } = require("model/unseenSquads.nut")
let blinkingIcon = require("%enlSqGlob/ui/blinkingIcon.nut")
let { openChooseSquadsWnd } = require("model/chooseSquadsState.nut")
let { squadBgColor } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { needSoldiersManageBySquad } = require("model/reserve.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")(0.7)
let { curUnseenUpgradesBySquad, isUpgradeUsed } = require("model/unseenUpgrades.nut")
let { armySlotDiscount } = require("%enlist/shop/armySlotDiscount.nut")
let mkNotifier = require("%enlist/components/mkNotifier.nut")

let function newPerksArmyIcon(squad) {
  let count = Computed(function() {
    let unseenUpgradesCount = (isUpgradeUsed.value ?? false) ? 0
      : (curUnseenUpgradesBySquad.value?[squad.guid] ?? 0)
    return max(notChoosenPerkSquads.value?[curArmy.value][squad.squadId] ?? 0,
      unseenSquadsWeaponry.value?[squad.guid] ?? 0)
    + (unseenSquadsVehicle.value?[squad.guid].len() ? 1 : 0)
    + unseenUpgradesCount
  })

  return function () {
    let res = { watch = count }
    if (count.value > 0)
      res.__update(blinkingIcon("user", count.value, false))
    return res
  }
}

let squadAlertIcon = @(squad) function() {
  let ret = { watch = needSoldiersManageBySquad }
  let needManage = needSoldiersManageBySquad.value?[squad.guid] ?? false
  return needManage ? ret.__update(unseenSignal) : ret
}

let restSquadsCount = Computed(@()
  max(curUnlockedSquads.value.len() - curChoosenSquads.value.len(), 0))

let curSquadsList = Computed(@() (curChoosenSquads.value ?? [])
  .map(@(squad) squad.__merge({
    addChild = @() { //function need only to notcreate computed direct in computed. Maybe it will be allowed in future
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [
        squadAlertIcon(squad)
        newPerksArmyIcon(squad)
      ]
    }
    level = allSquadsLevels.value?[squad.squadId] ?? 0
  })))


let managementIcon = @(sf, sizeArr = [hdpx(40), hdpx(20)]) {
  rendObj = ROBJ_IMAGE
  size = sizeArr
  keepAspect = true
  image = Picture("!ui/squads/squad_manage.svg:{0}:{1}:K".subst(sizeArr[0], sizeArr[1]))
  color = txtColor(sf)
}

let unseeSquadsIcon = @() {
  watch = [unseenSquads, curArmy]
  hplace = ALIGN_RIGHT
  children = (unseenSquads.value?[curArmy.value] ?? {}).findindex(@(v) v)
    ? unseenSignal
    : null
}

let squadManageButton = watchElemState(function(sf) {
  let rest = restSquadsCount.value
  return {
    watch = [restSquadsCount, armySlotDiscount]
    rendObj = ROBJ_SOLID
    size = [multySquadPanelSize[0], SIZE_TO_CONTENT]
    minHeight = (multySquadPanelSize[1] * 0.5).tointeger()
    margin = [bigGap, 0, 0, 0]
    padding = smallPadding
    gap = smallPadding
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    color = squadBgColor(sf, false)
    onClick = @() openChooseSquadsWnd(curArmy.value, curSquadId.value)
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          {
            flow = FLOW_HORIZONTAL
            gap = hdpx(2)
            children = managementIcon(sf, [hdpx(45), hdpx(30)])
          }
          rest < 1 ? null : {
            rendObj = ROBJ_TEXT
            color = txtColor(sf)
            text = $"+{rest}"
            padding = smallPadding
          }.__update(body_txt)
          unseeSquadsIcon
        ]
      }
      armySlotDiscount.value <= 0 ? null : mkNotifier(loc("shop/discount",
        { percents = armySlotDiscount.value }), {}, { color = 0xffff313b }, tiny_txt)
    ]
  }
})

return mkCurSquadsList({
  curSquadsList
  curSquadId
  setCurSquadId
  addedObj = squadManageButton
})
