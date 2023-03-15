from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let tooltipCtor = require("%ui/style/tooltipCtor.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { READY } = require("%enlSqGlob/readyStatus.nut")
let { mkSquadPremIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { kindIcon, kindName } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let freeVehicleSeats = require("%enlist/squad/freeVehicleSeats.nut")
let { curSquadId, curSquad, curSquadParams } = require("%enlist/soldiers/model/state.nut")
let { vehicleCapacity } = require("%enlist/soldiers/model/squadInfoState.nut")
let { curSoldiersDataList } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { curSquadSoldiersStatus } = require("%enlist/soldiers/model/readySoldiers.nut")
let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let {
  colPart, squadInfoColor, titleTxtColor, smallPadding, colFull, bigPadding, miniPadding
} = require("%enlSqGlob/ui/designConst.nut")


let defTxtStyle = { color = squadInfoColor }.__update(fontSmall)
let headerTxtStyle = { color = titleTxtColor }.__update(fontMedium)


let maxSquadVehicleSize = Computed(function() {
  let { size = 1 } = curSquadParams.value
  let vCapacity = vehicleCapacity.value
  return vCapacity > 0 ? min(size, vCapacity) : size
})


let mkSClassLimitsComp = Computed(function() {
  let res = []
  let { maxClasses = {} } = curSquadParams.value
  if (maxClasses.len() == 0)
    return res

  let soldierStatus = curSquadSoldiersStatus.value
  let usedClasses = {}
  foreach (soldier in curSoldiersDataList.value) {
    if (soldierStatus?[soldier.guid] != READY)
      continue
    let { sKind = "" } = soldier
    usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
  }

  let fillerClass = curSquad.value?.fillerClass
  foreach (sKind, total in maxClasses)
    res.append({
      sKind = sKind
      total = total
      used = usedClasses?[sKind] ?? 0
      isFiller = sKind == fillerClass
    })
  res.sort(@(a, b) a.isFiller <=> b.isFiller || b.total <=> a.total || a.sKind <=> b.sKind)
  return res
})


let squadClassLimits = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = colFull(6)
  text = loc("hint/squadClassLimits")
}.__update(defTxtStyle)


let mkClassLine = @(sClass) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      size = [colPart(0.4), SIZE_TO_CONTENT]
      text = $"{sClass.used}/{sClass.total}"
      halign = ALIGN_RIGHT
    }.__update(defTxtStyle)
    kindIcon(sClass.sKind, colPart(0.4))
    kindName(sClass.sKind).__update(defTxtStyle)
  ]
}

let classAmountHint = @() {
  watch = mkSClassLimitsComp
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [squadClassLimits]
    .extend(mkSClassLimitsComp.value.map(mkClassLine))
}


let mkClassAmount = @(sClass) {
  size = [colPart(0.4), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    kindIcon(sClass.sKind, colPart(0.4), null, squadInfoColor)
    {
      size = [SIZE_TO_CONTENT, colPart(0.25)]
      rendObj = ROBJ_TEXT
      text = $"{sClass.used}/{sClass.total}"
    }.__update(defTxtStyle)
  ]
}


let gapWithLine = {
  size = [colPart(0.3), flex(0.8)]
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [
    [VECTOR_WIDTH, hdpx(1)],
    [VECTOR_COLOR, squadInfoColor],
    [VECTOR_LINE, 50, 0, 50, 100]
  ]
}


let squadClassesUi = @() {
  watch = mkSClassLimitsComp
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gapWithLine
  children = mkSClassLimitsComp.value
    .filter(@(c) c.total > 0)
    .map(mkClassAmount)
}


let sizeHint = @(bAmount, maxAmount) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(500)
  color = squadInfoColor
  text = loc("hint/maxSquadSize", {
    battle = bAmount
    max = maxAmount
  })
}


let squadSizeUi = @(battleAmount) function() {
  let res = { watch = [battleAmount, maxSquadVehicleSize] }
  let amount = maxSquadVehicleSize.value
  if (amount <= 0)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(!on ? null : tooltipCtor(sizeHint(battleAmount.value, amount)))
    skipDirPadNav = true
    valign = ALIGN_BOTTOM
    children = [
      faComp("user", { fontSize = colPart(0.2), color = squadInfoColor })
      {
        size = [SIZE_TO_CONTENT, fontSmall.fontSize]
        rendObj = ROBJ_TEXT
        text = loc("membersCount", { count = $"{battleAmount.value}/{amount}"})
      }.__update(defTxtStyle)
    ]
  })
}


let infoBlock = @(squad) {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    mkSquadPremIcon(squad?.premIcon)
    {
      rendObj = ROBJ_TEXT
      text = loc(squad?.titleLocId)
    }.__update(headerTxtStyle)
  ]
}


let mkSquadLevel = @(level) {
  rendObj = ROBJ_TEXT
  text = loc("levelInfo", { level = level + 1 })
}.__update(defTxtStyle)


let function squadHeader(needIcon = false, needVehicleSeatsInfo = true) {
  let battleAmount = Computed(@() curSoldiersDataList.value.reduce(@(res, s)
    curSquadSoldiersStatus.value?[s.guid] == READY ? res + 1 : res, 0))

  return function() {
    let res = { watch = [curSquad, curSquadSoldiersStatus] }
    let squad = curSquad.value
    if (!squad)
      return res

    return res.__update({
      flow = FLOW_VERTICAL
      gap = bigPadding
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(on ? tooltipCtor(classAmountHint) : null)
      skipDirPadNav = true
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          valign = ALIGN_CENTER
          children = [
            needIcon ? mkSquadIcon(curSquad.value?.icon, { size = [colPart(1.1), colPart(1.1)] }) : null
            {
              flow = FLOW_VERTICAL
              gap = miniPadding
              children = [
                {
                  flow = FLOW_HORIZONTAL
                  gap = gapWithLine
                  children = [
                    squadSizeUi(battleAmount)
                    @() {
                      watch = [allSquadsLevels, curSquadId]
                      children = mkSquadLevel(allSquadsLevels.value?[curSquadId.value] ?? 0)
                    }
                  ]
                }
                needVehicleSeatsInfo ? freeVehicleSeats : null
                squadClassesUi
              ]
            }
          ]
        }
        infoBlock(squad)
      ]
    })
  }
}


return squadHeader