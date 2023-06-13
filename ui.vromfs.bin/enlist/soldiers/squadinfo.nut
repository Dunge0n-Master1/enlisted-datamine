from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let tooltipCtor = require("%ui/style/tooltipCtor.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { kindIcon, kindName } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { curSquadId, curSquad, curArmy, soldiersBySquad } = require("%enlist/soldiers/model/state.nut")
let squadsParams = require("%enlist/soldiers/model/squadsParams.nut")
let { vehicleCapacity } = require("%enlist/soldiers/model/squadInfoState.nut")
let { curSquadSoldiersStatus } = require("%enlist/soldiers/model/readySoldiers.nut")
let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let { colPart, titleTxtColor, smallPadding, colFull, midPadding,
  miniPadding, defTxtColor, darkTxtColor, hoverSlotBgColor, defItemBlur
} = require("%enlSqGlob/ui/designConst.nut")
let sClassesConfig = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let { getObjectsByLinkSorted, getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { curCampSoldiers } = require("%enlist/meta/profile.nut")
let { selectedSquad, selectedSquadId } = require("%enlist/soldiers/model/chooseSquadsState.nut")

let defTxtStyle = freeze({ color = defTxtColor }.__update(fontSmall))
let hoverTxtStyle = freeze({ color = darkTxtColor }.__update(fontSmall))
let headerTxtStyle = freeze({ color = titleTxtColor }.__update(fontMedium))

let squadIdToShow = Computed(@() selectedSquadId.value ?? curSquadId.value)
let squadToShow = Computed(@() selectedSquad.value ?? curSquad.value)

let curSquadParams = Computed(@()
  squadsParams.value?[curArmy.value][squadIdToShow.value])


let maxSquadVehicleSize = Computed(function() {
  let { size = 1 } = curSquadParams.value
  let vCapacity = vehicleCapacity.value
  return vCapacity > 0 ? min(size, vCapacity) : size
})


let mkSquadLimitsState = @(squad) Computed(function() {
  let res = []
  if (squad == null)
    return res

  let armyId = getLinkedArmyName(squad)
  let { guid, squadId } = squad
  let { maxClasses = {} } = squadsParams.value?[armyId][squadId]
  if (maxClasses.len() == 0)
    return res

  let soldiers = soldiersBySquad.value?[guid] ?? []
  let usedClasses = {}
  foreach (soldier in soldiers) {
    let sKind = sClassesConfig.value[soldier?.sClass ?? ""]?.kind
    if (sKind != null)
      usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
  }

  let fillerClass = squad?.fillerClass
  foreach (sKind, total in maxClasses) {
    let used = usedClasses?[sKind] ?? 0
    let isFiller = sKind == fillerClass
    res.append({ sKind, total, used, isFiller })
  }
  res.sort(@(a, b) a.isFiller <=> b.isFiller || b.total <=> a.total || a.sKind <=> b.sKind)
  return res
})


let squadClassLimits = freeze({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = colFull(6)
  text = loc("hint/squadClassLimits")
}.__update(defTxtStyle))


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

let mkClassAmountHint = @(limits)
  @() {
    watch = limits
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [squadClassLimits]
      .extend(limits.value.map(mkClassLine))
  }


let mkClassAmount = @(sClass, txtStyle, iconColor) {
  size = [colPart(0.3), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    kindIcon(sClass.sKind, colPart(0.3), null, iconColor)
    {
      rendObj = ROBJ_TEXT
      text = $"{sClass.used}/{sClass.total}"
    }.__update(txtStyle)
  ]
}


let mkGapWithLine = @(color) {
  size = [colPart(0.24), flex(0.7)]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [
    [VECTOR_WIDTH, hdpx(1)],
    [VECTOR_COLOR, color],
    [VECTOR_LINE, 50, 0, 50, 100]
  ]
}


let squadClassesFrame = {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR
  fillColor = hoverSlotBgColor
  color = defItemBlur
  padding = [smallPadding, 0, miniPadding, 0]
}

let function mkSquadClassesUi(limits, hasFrame = false) {
  let txtStyle = hasFrame ? hoverTxtStyle : defTxtStyle
  let iconColor = hasFrame ? darkTxtColor : defTxtColor
  return @() {
    watch = limits
    flow = FLOW_HORIZONTAL
    gap = mkGapWithLine(iconColor)
    children = limits.value
      .filter(@(c) c.total > 0)
      .map(@(c) mkClassAmount(c, txtStyle, iconColor))
  }.__update(hasFrame ? squadClassesFrame : {})
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


let mkSquadSizeUi = @(squadGuid) function() {
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


let infoBlock = memoize(@(titleLocId)  freeze({
  size = [flex(), SIZE_TO_CONTENT]
  minWidth = colFull(6)
  gap = smallPadding
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(titleLocId)
}.__update(headerTxtStyle)))


let mkSquadLevel = memoize(@(level) freeze({
  rendObj = ROBJ_TEXT
  text = loc("levelInfo", { level = level + 1 })
}.__update(defTxtStyle)))

let gap = mkGapWithLine(defTxtColor)
let squadLevel = @() {
  watch = [allSquadsLevels, curSquadId]
  children = mkSquadLevel(allSquadsLevels.value?[curSquadId.value] ?? 0)
}


let function squadInfo() {
  let res = { watch = [squadToShow, curSquadSoldiersStatus, curArmy] }
  let squad = squadToShow.value
  if (!squad)
    return res

  return res.__update({
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(on ? tooltipCtor(mkClassAmountHint(mkSquadLimitsState(squad))) : null)
    skipDirPadNav = true
    vplace = ALIGN_CENTER
    gap = midPadding
    children = [
      infoBlock(squad?.titleLocId)
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          {
            flow = FLOW_VERTICAL
            gap = midPadding
            children = [
              mkSquadClassesUi(mkSquadLimitsState(squad))
              {
                flow = FLOW_HORIZONTAL
                gap
                children = [
                  mkSquadSizeUi(squad.guid)
                  squadLevel
                ]
              }
            ]
          }
        ]
      }
    ]
  })
}


return { squadInfo }
