from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
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
let { openChooseSquadsWnd } = require("model/chooseSquadsState.nut")
let { squadBgColor } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { needSoldiersManageBySquad } = require("model/reserve.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { armySlotDiscount } = require("%enlist/shop/armySlotDiscount.nut")
let { mkNotifierBlink } = require("%enlist/components/mkNotifier.nut")
let {
  mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN, REQ_MANAGE_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { soundDefault } = require("%ui/components/textButton.nut")


let unseenIcon = blinkUnseenIcon(0.7)

let mkManageAlert = @(guid) mkAlertIcon(REQ_MANAGE_SIGN, Computed(@()
  needSoldiersManageBySquad.value?[guid] ?? false))

let mkUnseenAlert = @(guid) mkAlertIcon(ITEM_ALERT_SIGN, Computed(@()
  (unseenSquadsWeaponry.value?[guid] ?? 0) > 0
    || (unseenSquadsVehicle.value?[guid].len() ?? 0) > 0
))

let mkPerksAlert = @(squadId) mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
  (notChoosenPerkSquads.value?[curArmy.value][squadId] ?? 0) > 0))

let managementIcon = @(sf, sizeArr = [hdpxi(40), hdpxi(20)]) {
  rendObj = ROBJ_IMAGE
  size = sizeArr
  keepAspect = KEEP_ASPECT_FIT
  image = Picture("!ui/squads/squad_manage.svg:{0}:{1}:K".subst(sizeArr[0], sizeArr[1]))
  color = txtColor(sf)
}

let function mkSlotAlertsComponent(squad){
  return @() {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = [
      mkManageAlert(squad.guid)
      mkUnseenAlert(squad.guid)
      mkPerksAlert(squad.squadId)
    ]
  }
}

let unseenSquadsIcon = @() {
  watch = [unseenSquads, curArmy]
  hplace = ALIGN_RIGHT
  children = (unseenSquads.value?[curArmy.value] ?? {}).findindex(@(v) v)
    ? unseenIcon
    : null
}

let function mkSquadManagementBtn(restSquadsCount=null, size = null, margin = null ){
  let squadManageButtonStateFlags = Watched(0)

  let squadManageButton = watchElemState(function(sf) {
    let rest = restSquadsCount?.value ?? 0
    return {
      watch = [restSquadsCount, armySlotDiscount]
      rendObj = ROBJ_SOLID
      size = size ?? [multySquadPanelSize[0], SIZE_TO_CONTENT]
      minHeight = (multySquadPanelSize[1] * 0.5).tointeger()
      margin = margin ?? [bigGap, 0, 0, 0]
      padding = smallPadding
      gap = smallPadding
      behavior = Behaviors.Button
      xmbNode = XmbNode()
      color = squadBgColor(sf, false)
      onClick = @() openChooseSquadsWnd(curArmy.value, curSquadId.value)
      onDetach = @() squadManageButtonStateFlags(0)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      sound = soundDefault
      children = [
        {
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            {
              flow = FLOW_HORIZONTAL
              gap = hdpx(2)
              children = managementIcon(sf, [hdpxi(45), hdpxi(30)])
            }
            rest < 1 ? null : {
              rendObj = ROBJ_TEXT
              color = txtColor(sf)
              text = $"+{rest}"
              padding = smallPadding
            }.__update(body_txt)
            unseenSquadsIcon
          ]
        }
        armySlotDiscount.value <= 0 ? null : mkNotifierBlink(loc("shop/discount",
          { percents = armySlotDiscount.value }), {}, { color = 0xffff313b })
      ]
    }
  }, {stateFlags = squadManageButtonStateFlags})
  return squadManageButton
}

let function mkSquadsList() {
  let restSquadsCount = Computed(@()
    max(curUnlockedSquads.value.len() - curChoosenSquads.value.len(), 0))

  let squadManageButton = mkSquadManagementBtn(restSquadsCount)

  let curSquadsList = Computed(@() (curChoosenSquads.value ?? [])
    .map(@(squad) squad.__merge({
      addChild = mkSlotAlertsComponent(squad)
      level = allSquadsLevels.value?[squad.squadId] ?? 0
    })))



  return mkCurSquadsList({
    curSquadsList
    curSquadId
    setCurSquadId
    addedObj = squadManageButton
  })
}
return {
  mkSquadsList
  mkSlotAlertsComponent
  openChooseSquadsWnd
  managementIcon
  mkSquadManagementBtn = kwarg(mkSquadManagementBtn)
}