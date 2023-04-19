from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let tooltipCtor = require("%ui/style/tooltipCtor.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { kindIcon, kindName } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let freeVehicleSeats = require("%enlist/squad/freeVehicleSeats.nut")
let { curSquadId, curSquad, curArmy, soldiersBySquad } = require("%enlist/soldiers/model/state.nut")
let squadsParams = require("%enlist/soldiers/model/squadsParams.nut")
let { vehicleCapacity } = require("%enlist/soldiers/model/squadInfoState.nut")
let { curSquadSoldiersStatus } = require("%enlist/soldiers/model/readySoldiers.nut")
let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let { colPart, titleTxtColor, smallPadding, colFull, bigPadding, midPadding,
  defTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let sClassesConfig = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let { getObjectsByLinkSorted } = require("%enlSqGlob/ui/metalink.nut")
let { curCampSoldiers } = require("%enlist/meta/profile.nut")
let { selectedSquad, selectedSquadId } = require("%enlist/soldiers/model/chooseSquadsState.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let headerTxtStyle = { color = titleTxtColor }.__update(fontMedium)

let squadIdToShow = Computed(@() selectedSquadId.value ?? curSquadId.value)
let squadToShow = Computed(@() selectedSquad.value ?? curSquad.value)

let curSquadParams = Computed(@()
  squadsParams.value?[curArmy.value][squadIdToShow.value])


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

  let soldiers = soldiersBySquad.value?[squadToShow.value.guid] ?? []
  let usedClasses = {}
  foreach (soldier in soldiers) {
    let { sClass = "" } = soldier
    let sKind = sClassesConfig.value[sClass]?.kind
    if (sKind == null)
      continue
    usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
  }

  let fillerClass = squadToShow.value?.fillerClass
  foreach (sKind, total in maxClasses)
    res.append({
      sKind
      total
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
    kindIcon(sClass.sKind, colPart(0.4), null, defTxtColor)
    {
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
    [VECTOR_COLOR, defTxtColor],
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
  text = loc("hint/maxSquadSize", {
    battle = bAmount
    max = maxAmount
  })
}.__update(defTxtStyle)


let squadSizeUi = @(squadGuid) function() {
  let battleAmount = getObjectsByLinkSorted(curCampSoldiers.value, squadGuid, "squad").len()
  let res = { watch = [maxSquadVehicleSize, curCampSoldiers] }
  let amount = maxSquadVehicleSize.value
  if (amount <= 0)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(!on ? null : tooltipCtor(sizeHint(battleAmount, amount)))
    skipDirPadNav = true
    valign = ALIGN_BOTTOM
    children = [
      faComp("user", { fontSize = colPart(0.2), color = defTxtColor })
      {
        size = [SIZE_TO_CONTENT, fontSmall.fontSize]
        rendObj = ROBJ_TEXT
        text = loc("membersCount", { count = $"{battleAmount}/{amount}"})
      }.__update(defTxtStyle)
    ]
  })
}


let infoBlock = @(squad) {
  size = [flex(), SIZE_TO_CONTENT]
  gap = smallPadding
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(squad?.titleLocId)
}.__update(headerTxtStyle)


let mkSquadLevel = @(level) {
  rendObj = ROBJ_TEXT
  text = loc("levelInfo", { level = level + 1 })
}.__update(defTxtStyle)


let function squadInfo(needIcon = false, needVehicleSeatsInfo = true) {
  return function() {
    let res = { watch = [squadToShow, curSquadSoldiersStatus, curArmy] }
    let squad = squadToShow.value
    if (!squad)
      return res

    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(on ? tooltipCtor(classAmountHint) : null)
      skipDirPadNav = true
      vplace = ALIGN_CENTER
      gap = midPadding
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = midPadding
          valign = ALIGN_CENTER
          children = [
            needIcon ? mkSquadIcon(squad?.icon, { size = [colPart(1.1), colPart(1.1)] })
              : null
            {
              flow = FLOW_VERTICAL
              gap = midPadding
              children = [
                squadClassesUi
                {
                  flow = FLOW_HORIZONTAL
                  gap = gapWithLine
                  children = [
                    squadSizeUi(squad.guid)
                    @() {
                      watch = [allSquadsLevels, curSquadId]
                      children = mkSquadLevel(allSquadsLevels.value?[curSquadId.value] ?? 0)
                    }
                  ]
                }
                needVehicleSeatsInfo ? freeVehicleSeats : null
              ]
            }
          ]
        }
        infoBlock(squad)
      ]
    })
  }
}


let mkLockedClassAmount = @(sClass, amount) {
  size = [colPart(0.4), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    kindIcon(sClass, colPart(0.4), null, defTxtColor)
    {
      size = [SIZE_TO_CONTENT, colPart(0.25)]
      rendObj = ROBJ_TEXT
      text = amount
    }.__update(defTxtStyle)
  ]
}



let reserveSquadClassesUi = @(data) @() {
  watch = sClassesConfig
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gapWithLine
  children = data
    .reduce(function(res, soldier) {
      let sKind = sClassesConfig.value?[soldier.sClass].kind
      if (sKind != null)
        res[sKind] <- (res?[sKind] ?? 0) + 1
      return res
    }, {})
    .reduce(@(res, count, sKind) res.append(mkLockedClassAmount(sKind, count)), [])
}


let lockedSquadInfo = @(squadCfg) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  skipDirPadNav = true
  children = [
    reserveSquadClassesUi(squadCfg.startSoldiers)
    infoBlock(squadCfg)
  ]
}


return {
  squadInfo
  lockedSquadInfo
}