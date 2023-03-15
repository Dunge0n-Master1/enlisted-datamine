from "%enlSqGlob/ui_library.nut" import *

#explicit-this

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let { txt, progressBar } = require("%enlSqGlob/ui/defcomps.nut")
let { statusIconLocked } =  require("%enlSqGlob/ui/style/statusIcon.nut")
let { ModalBgTint, TextHighlight } = require("%ui/style/colors.nut")
let {buttonSound} = require("%ui/style/sounds.nut")
let cursors = require("%ui/style/cursors.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let colorize = require("%ui/components/colorize.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let campaignTitle = require("%enlist/campaigns/campaign_title_small.ui.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(72) })
let { bigPadding, smallPadding, bigGap, researchHeaderIconHeight, researchListTabBorder,
  researchListTabPadding, isWide, activeTxtColor, defTxtColor, multySquadPanelSize,
  tablePadding, researchItemSize
} = require("%enlSqGlob/ui/viewConst.nut")
let { allSquadsPoints, viewArmy, armiesResearches, viewSquadId,
  closestTargets, selectedTable, tableStructure, isBuyLevelInProgress,
  selectedResearch, researchStatuses, curSquadPoints,
  curArmySquadsProgress, curSquadProgress, buySquadLevel, hasResearchesSection,
  LOCKED, DEPENDENT, RESEARCHED, GROUP_RESEARCHED, BALANCE_ATTRACT_TRIGGER
} = require("researchesState.nut")
let { researchToShow } = require("researchesFocus.nut")
let { mkActiveBlock, mkCardText, mkSquadPremIcon
} = require("%enlSqGlob/ui/squadsUiComps.nut")
let researchDetailsPopup = require("researchDetailsPopup.ui.nut")
let tableElement = require("researchTableElement.ui.nut")
let { curArmy, curUnlockedSquads, armySquadsById, maxCampaignLevel
} = require("%enlist/soldiers/model/state.nut")
let { seenResearches } = require("unseenResearches.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { safeAreaSize, safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { iconByGameTemplate } = require("%enlSqGlob/ui/itemsInfo.nut")
let researchIcons = require("%enlSqGlob/ui/researchIcons.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { attractToImage } = require("%enlist/components/hoverImage.nut")
let { currencyBtn } = require("%enlist/currency/currenciesComp.nut")
let { onlinePurchaseStyle, smallStyle, Bordered } = require("%ui/components/textButton.nut")
let { mkDisabledSectionBlock } = require("%enlist/mainMenu/disabledSections.nut")
let { sound_play } = require("sound")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { mkLockByCampaignProgress } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { disableSquadExp } = require("%enlist/campaigns/campaignConfig.nut")

let colorBranchAvailable = Color(205, 205, 220)
let levelAndExpColor = Color(255, 178, 0)
let pageWidth = min(sw(100) - safeAreaBorders.value[1] - safeAreaBorders.value[3], hdpx(1826))
let tableBoxWidth = (pageWidth - bigPadding * 3 - multySquadPanelSize[0]) * 0.45
let lineVertDistance = hdpx(200)
let tabIconBlockSize = researchHeaderIconHeight + bigPadding * 3
let researchesTableHeight = Computed(@() safeAreaSize.value[1] - hdpx(250)) // FIXME magic summ of sections, armies and squads bar heights
let tblScrollHandler = ScrollHandler()

let closestCurrentResearch = Computed(@() closestTargets.value?[selectedTable.value])
let isResearchListVisible = Watched(false)
let needScrollClosest = Watched(true)
let unseenIcon = blinkUnseenIcon()
let smallUnseenIcon = blinkUnseenIcon(0.7)

let curSquadData = Computed(@() armySquadsById.value?[viewArmy.value][viewSquadId.value])

let curSquadNameLocId = Computed(function() {
  let res = armiesResearches.value?[curArmy.value].squads[viewSquadId.value].name ?? ""
  return res != "" ? res : curSquadData.value?.manageLocId
})

const TWO_COLUMNS_AREA = 66.66

let tableStructureCalculator = @(tableStruct) {
  tiersTotal = tableStruct.tiersTotal
  rowsTotal = tableStruct.rowsTotal
  minTier = tableStruct.minTier

  cX = function(point) {
    let {tiersTotal, minTier} = this
    if (tiersTotal == 1)
      return 50.00

    let tableWidth = tableBoxWidth
    let totalPercents = (tiersTotal == 2 ? TWO_COLUMNS_AREA : 100.00) * ((tableWidth - tablePadding * 2) / tableWidth)
    return (100.00 - totalPercents) / 2 + totalPercents * (point.tier - minTier) / (tiersTotal - 1)
  }

  cY = function(point) {
    let {rowsTotal} = this
    if (rowsTotal == 1)
      return 50.00

    let tableHeight = rowsTotal * lineVertDistance + tablePadding * 2
    let totalPercents = 100.00 * ((tableHeight - tablePadding * 2) / tableHeight)
    return (100.00 - totalPercents) / 2 + totalPercents * (point.line - 1) / (rowsTotal - 1)
  }
}

let function scrollToResearch(curResearch) {
  if (curResearch == null)
    return tblScrollHandler.scrollToY(0)

  let TSC = tableStructureCalculator(tableStructure.value)
  let tableHeight = tableStructure.value.rowsTotal * lineVertDistance + tablePadding * 2
  let pos = (TSC.cY(curResearch) / 100) * tableHeight - researchesTableHeight.value / 2
  tblScrollHandler.scrollToY(pos)
}

closestCurrentResearch.subscribe(@(_) needScrollClosest(true))

let needAttractToResearch = keepref(Computed(@() isResearchListVisible.value
  && (researchToShow.value != null || needScrollClosest.value)))

needAttractToResearch.subscribe(function(v) {
  if (!v)
    return
  let curResearch = researchToShow.value ?? (needScrollClosest.value ? closestCurrentResearch.value : null)
  if (curResearch == null)
    return

  scrollToResearch(curResearch)
  // because scrolling is not momentary
  gui_scene.setTimeout(0.1, function() {
    if (researchToShow.value != null)
      attractToImage(curResearch.research_id)
    researchToShow(null)
    needScrollClosest(false)
  })
})

let lineWidth = hdpx(9)
let mkLine = @(x, y, x2, y2) [VECTOR_LINE, x, y, x2, y2]
let mkDashedLine = @(x, y, x2, y2) [VECTOR_LINE_DASHED, x, y, x2, y2, 4 * lineWidth, 3 * lineWidth]
let mkPointsLine = @(x, y, x2, y2) [VECTOR_LINE_DASHED, x, y, x2, y2, 0, 4 * lineWidth]

let getLinesLayer = @(tableHeight, structure) function() {
  let commands = []
  let TSC = tableStructureCalculator(structure)
  let researches = structure.researches
  let bgColor = structure.pages?[selectedTable.value].bg_color ?? ModalBgTint
  let selResearch = selectedResearch.value
  foreach (toId, research in researches) {
    let status = researchStatuses.value?[toId] ?? DEPENDENT
    if (status == GROUP_RESEARCHED)
      continue
    let to = research
    let curColor = status == DEPENDENT || status == LOCKED
      ? mul_color(bgColor, 0.6) | 0xff000000
      : colorBranchAvailable
    let lineCtor = (to?.multiresearchGroup ?? 0) <= 0 || status == RESEARCHED || toId == selResearch?.research_id ? mkLine
      : selResearch?.multiresearchGroup == to.multiresearchGroup ? mkPointsLine
      : mkDashedLine
    foreach (fromId in research?.requirements ?? []) {
      let from = researches[fromId]
      commands.append([VECTOR_COLOR, curColor])
      commands.append(lineCtor(TSC.cX(from), TSC.cY(from), TSC.cX(to), TSC.cY(to)))
    }
  }

  return {
    watch = [selectedTable, researchStatuses, selectedResearch]
    rendObj = ROBJ_VECTOR_CANVAS
    size = [tableBoxWidth, tableHeight]
    lineWidth
    commands
  }
}

let itemsLayer = @(tableHeight) function() {
  let TSC = tableStructureCalculator(tableStructure.value)
  let armyId = tableStructure.value.armyId
  let children = []

  foreach (tableItem in tableStructure.value.researches) {
    let posX = (TSC.cX(tableItem) / 100) * tableBoxWidth
    let posY = (TSC.cY(tableItem) / 100) * tableHeight
    children.append(tableElement(armyId, tableItem, posX, posY))
  }

  return {
    watch = [tableStructure]
    size = [tableBoxWidth, tableHeight]
    children = children
    behavior = Behaviors.RecalcHandler
  }
}

let function researchInfoPlace() {
  local needScroll = selectedResearch.value != null
  let res = {}

  let objectId = "researchDetailsPopupView"
  return res.__update({
    size = flex()
    children = researchDetailsPopup
    behavior = Behaviors.RecalcHandler
    onRecalcLayout = function(_initial) {
      if (needScroll && selectedResearch.value) {
        tblScrollHandler.scrollToChildren(@(comp) comp?.key == objectId, 5, false, true)
        needScroll = false
      }
    }
  })
}

let squadResearchesInfo = Computed(function() {
  let researches = (armiesResearches.value?[curArmy.value].researches ?? [])
    .filter(@(research) research.squad_id == viewSquadId.value)
  let completed = researches
    .filter(@(research) researchStatuses.value?[research.research_id] == RESEARCHED)
  return {
    total = researches.len()
    completed = completed.len()
  }
})

let mkSkillPoints = @(hasCompleted) @() {
  watch = curSquadPoints
  uid = $"skillPoints{curSquadPoints.value}"
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Button]

  color = defTxtColor

  text = hasCompleted ? ""
    : loc("research/skillPoints", { skillPoints = colorize(activeTxtColor, curSquadPoints.value) })

  onHover = @(on) cursors.setTooltip(!on ? null : loc("research/skillPoints/hint"))
  skipDirPadNav = true

  transform = { pivot=[0.5, 0.5] }
  animations = [
    { trigger = BALANCE_ATTRACT_TRIGGER, prop = AnimProp.scale,
      from =[1.0, 1.0], to = [1.2, 1.2], duration = 0.3, easing = CosineFull } // TODO: need fix - animation does not play
    { trigger = BALANCE_ATTRACT_TRIGGER, prop = AnimProp.color,
      from = TextHighlight, to = statusIconLocked, duration = 1.0 easing = Blink }
  ]
}.__update(body_txt)

let iconSquadPoints = {
  rendObj = ROBJ_IMAGE
  size = array(2, hdpx(20))
  image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(hdpx(20)))
}

let function buySquadLevelMsg() {
  let { levelCost = 0, level = 0 } = curSquadProgress.value
  purchaseMsgBox({
    price = levelCost
    currencyId = "EnlistedGold"
    title = loc("squadLevel", { level = level + 2 })
    description = loc("buy/squadLevelConfirm")
    purchase = @() buySquadLevel(function(isSuccess) {
      if (isSuccess)
        sound_play("ui/purchase_level_squad")
    })
    srcComponent = "buy_researches_level"
  })
}

let buyLevelStyle = onlinePurchaseStyle.__merge(smallStyle)
  .__update({ margin = [0, bigPadding] })

let function buyLevelBtn() {
  let cost = curSquadProgress.value?.levelCost ?? 0
  return {
    watch = [curSquadProgress, isBuyLevelInProgress]
    children = cost <= 0 ? null
      : isBuyLevelInProgress.value ? spinner
      : currencyBtn({
          btnText = loc("btn/buy")
          currencyId = "EnlistedGold"
          price = cost
          cb = buySquadLevelMsg
          style = buyLevelStyle.__merge({
            hotkeys = [[ "^J:Y", { description = {skip = true}} ]]
          })
        })
  }
}

let function getProgressTooltip(curLvl, maxLvl, curExp, expToNextLvl, accColor){
    let lvlBlock = colorize(accColor, $"{curLvl + 1}/{maxLvl + 1}")
    let expBlock = colorize(accColor, $"{curExp}/{expToNextLvl}")
    return $"{lvlBlock} {loc("research/squad_level")} \n {loc("research/sqaud_next_level")} {expBlock}"
}

let function squadProgressBlock() {
  let res = { watch = [curSquadData, curSquadProgress, squadResearchesInfo, disableSquadExp] }
  if ((curSquadData.value?.battleExpBonus ?? 0) > 0)
    return res
  let { level, maxLevel, exp, nextLevelExp } = curSquadProgress.value
  let pageInfo = squadResearchesInfo.value
  let hasCompleted = pageInfo.completed >= pageInfo.total
  return res.__update({
    behavior = Behaviors.Button
    onHover = @(on) cursors.setTooltip(on
      ? getProgressTooltip(level, maxLevel, exp, nextLevelExp, levelAndExpColor)
      : null)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = defTxtColor
        text = loc("levelInfo", { level = colorize(activeTxtColor, level + 1) })
      }.__update(body_txt)
      nextLevelExp <= 0 ? null : progressBar({
        value = exp.tofloat() / nextLevelExp, width = hdpx(125), height = hdpx(10)
      }).__merge({ margin = hdpx(5) })
      mkSkillPoints(hasCompleted)
      !hasCompleted ? iconSquadPoints : null
      !hasCompleted && !disableSquadExp.value
        ? buyLevelBtn
        : null
    ]
  })
}

let squadNameBlock = @() {
  watch = [curSquadData, curSquadNameLocId]
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    mkSquadPremIcon(curSquadData.value?.premIcon)
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = activeTxtColor
      text = curSquadNameLocId.value ? loc(curSquadNameLocId.value) : null
    }.__update(body_txt)
  ]
}

let wndHeader = {
  size = flex()
  padding = [0 , bigGap]
  gap = bigGap
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [SIZE_TO_CONTENT, flex()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      squadNameBlock
      squadProgressBlock
    ]
  }
}

let function table() {
  let TSC = tableStructureCalculator(tableStructure.value)
  let tableHeight = (TSC.rowsTotal > 0 ? TSC.rowsTotal : 2) * lineVertDistance + tablePadding * 2
  return {
    key = {}
    watch = tableStructure
    size = [flex(), tableHeight]
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 5.0
      isViewport = true
    })
    children = [
      getLinesLayer(tableHeight, tableStructure.value)
      itemsLayer(tableHeight)
    ]
  }
}

let function calcAvailableResearchesCount(researches) {
  let existingResearches = {}

  return researches.reduce(function(count, research){
    let { multiresearchGroup = 0 } = research
    if (multiresearchGroup == 0 || multiresearchGroup not in existingResearches) {
      existingResearches[multiresearchGroup] <- 0
      return count + 1
    }
    return count
  }, 0)
}

let currentTableResearchCounter = @(idx, bgColor) function() {
  let researches = (armiesResearches.value?[curArmy.value].researches ?? [])
    .filter(@(r) r.squad_id == viewSquadId.value && (r?.page_id ?? 0) == idx)
  let availableResearchesCount = calcAvailableResearchesCount(researches)
  let completed = researches.filter(@(researchDef) researchStatuses.value?[researchDef.research_id] == RESEARCHED)
  let hasPageCompleted = completed.len() >= availableResearchesCount
  return {
    watch = [researchStatuses, viewSquadId]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = availableResearchesCount > 0
      ? [
          txt({
            text = $"{completed.len()}/{availableResearchesCount}"
            color = bgColor
            brightness = 0.7
          })
          hasPageCompleted
            ? faComp("check-circle", {color = bgColor, brightness = 0.7})
            : null
        ]
      : null
  }
}

let function unseenInPageIcon(squadId, pageId) {
  let hasUnseen = Computed(function() {
    let researches = armiesResearches.value?[viewArmy.value].researches ?? {}
    let unseen = seenResearches.value?.unseen[viewArmy.value]
    return researches.findindex(@(r)
      r.research_id in unseen && r.squad_id == squadId && (r?.page_id ?? 0) == pageId) != null
  })
  return @() {
    watch = hasUnseen
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    children = hasUnseen.value ? unseenIcon : null
  }
}

let mkImageByTemplate = kwarg(function(width, templateId, templateOverride = null) {
  local tmplParams = templateOverride ?? {}
  let scale = tmplParams?.scale ?? 1.0
  tmplParams = tmplParams.__merge({
    width = width * scale
    height = width * scale
    shading = "silhouette"
    silhouette = [255, 255, 255, 255]
  })
  return iconByGameTemplate(templateId, tmplParams)
})

let getSquarePicture = @(image, size) (image ?? "") == "" ? null
  : Picture(image.endswith(".svg") ? $"!{image}:{size.tointeger()}:{size.tointeger()}:K" : $"{image}?Ac")

let mkImageByIcon = kwarg(function(width, height, iconPath, iconOverride = null) {
  let iconSize = min(width, height)
  let resized = (iconSize * (iconOverride?.scale ?? 1.0)).tointeger()
  let pos = iconOverride?.pos ?? [0, 0]
  return {
    size = [iconSize, iconSize]
    children = {
      rendObj = ROBJ_IMAGE
      size = [resized, resized]
      image = getSquarePicture(iconPath, resized)
      pos = [(iconSize - resized) * pos[0],  (iconSize - resized) * pos[1]]
    }
  }
})

let function mkPageIcon(closestResearchDef, page) {
  let width = researchItemSize[0]
  let height = researchItemSize[1]
  return function() {
    let researchDef = closestResearchDef.value
    let templateId = researchDef?.gametemplate ?? ""
    let iconPath = researchIcons?[researchDef?.icon_id]
      ?? (templateId == "" ? researchIcons?[page?.icon_id] : null)
    return {
      watch = closestResearchDef
      rendObj = ROBJ_SOLID
      size = [tabIconBlockSize, tabIconBlockSize]
      padding = smallPadding
      color = Color(100, 100, 100, 100)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        templateId == "" ? null : mkImageByTemplate({
          width = width
          templateId = templateId
          templateOverride = researchDef?.templateOverride
        })
        iconPath == null ? null : mkImageByIcon({
          width = width
          height = height
          iconPath = iconPath
          iconOverride = researchDef?.iconOverride
        })
        currentTableResearchCounter(page?.page_id ?? 0, page.bg_color)
      ]
    }
  }
}

let mkPageInfoText = @(page, isSelected) {
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = tabIconBlockSize
  flow = FLOW_VERTICAL
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(page.name)
      color = isSelected ? activeTxtColor : defTxtColor
    }.__update(isWide ?  h2_txt : body_txt)
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(page.description)
      color = isSelected ? activeTxtColor : defTxtColor
    }.__update(sub_txt)
  ]
}

let function upgradePageTab(page, pageId) {
  let stateFlags = Watched(0)
  let unseenTabIcon = unseenInPageIcon(page.squad_id, pageId)
  let closestResearchDef = Computed(@() closestTargets.value?[pageId])

  return function() {
    let isSelected = selectedTable.value == pageId
    let isHovered = stateFlags.value & S_HOVER
    return {
      size = [flex(), SIZE_TO_CONTENT]
      maxHeight = hdpx(220)
      watch = [stateFlags, selectedTable]
      rendObj = ROBJ_BOX
      borderWidth = isSelected || isHovered ? researchListTabBorder : 0

      borderColor = Color(205, 205, 220, 255)
      padding = researchListTabPadding
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = bigGap
      fillColor = page.bg_color

      behavior = Behaviors.Button
      sound = buttonSound
      onClick = @() selectedTable(pageId)
      onElemState = @(sf) stateFlags.update(sf)

      children = [
        mkPageIcon(closestResearchDef, page)
        mkPageInfoText(page, isSelected)
        unseenTabIcon
      ]
    }
  }
}

let function researchesPageBranch() {
  return makeVertScroll(table, {
    scrollHandler = tblScrollHandler
    rootBase = class {
      size = flex()
      behavior = Behaviors.Pannable
      wheelStep = 1.58
      skipDirPadNav = true
    }
    barStyle = @(_has_scroll) class {
      _width = fsh(1)
      _height = fsh(1)
      skipDirPadNav = true
    }
    knobStyle = class {
      skipDirPadNav = true
      hoverChild = function(sf) {
        return {
          rendObj = ROBJ_BOX
          size = [hdpx(8), flex()]
          borderWidth = [hdpx(6), hdpx(2), hdpx(6), hdpx(1)]
          borderColor = Color(0, 0, 0, 0)
          fillColor = (sf & S_ACTIVE) ? Color(255,255,255)
              : (sf & S_HOVER)  ? Color(110, 120, 140, 80)
                                : Color(110, 120, 140, 160)
        }
      }
    }
  })
}

let emptyResearchesText = {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  text = loc("researches/willBeAvailableSoon")
}.__update(body_txt)

let lowCampaignLevelText = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("researches/levelTooLowForWorkshop")
    }.__update(body_txt)
    Bordered(loc("menu/campaignRewards"), jumpToArmyProgress, {
        hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
      }
    )
  ]
}

let function researchesTable() {
  let res = {
    size = flex()
    watch = [tableStructure, maxCampaignLevel, selectedTable]
    onAttach = @() isResearchListVisible(true)
    onDetach = @() isResearchListVisible(false)
  }
  let pagesAmount = (tableStructure.value?.pages ?? []).len()
  let isBranchEmpty = (tableStructure.value?.researches ?? {}).len() == 0
  let isCampaignLevelLow = selectedResearch.value?.isLockedByCampaignLvl ?? false
  let isLocked = isBranchEmpty || isCampaignLevelLow

  if (pagesAmount == 0)
    return res.__update({
      rendObj = ROBJ_SOLID
      color = ModalBgTint
      children = emptyResearchesText
    })

  let listSize = [isLocked ? flex() : pw(45), flex()]
  let listColor = tableStructure.value.pages?[selectedTable.value].bg_color ?? ModalBgTint

  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      {
        size = [pw(30), flex()]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = tableStructure.value.pages.map(upgradePageTab)
      }
      {
        rendObj = ROBJ_SOLID
        size = listSize
        color = listColor
        children = isBranchEmpty ? emptyResearchesText
          : isCampaignLevelLow ? lowCampaignLevelText
          : researchesPageBranch
      }
      isLocked ? null : researchInfoPlace
    ]
  })
}

let mkSquadExp = function(squadId) {
  let exp = Computed(@() allSquadsPoints.value?[squadId] ?? 0)
  return @(sf, selected) @() mkActiveBlock(sf, selected, [
    mkCardText(exp.value, sf, selected)
    iconSquadPoints
  ]).__update({
    watch = exp
    valign = ALIGN_CENTER
    gap = hdpx(3)
  })
}

let function unseenInSquadIcon(squadId) {
  let hasUnseen = Computed(function() {
    let researches = armiesResearches.value?[viewArmy.value].researches ?? {}
    let unseen = seenResearches.value?.unseen[viewArmy.value]
    return researches.findindex(@(r) r.research_id in unseen && r.squad_id == squadId) != null
  })
  return @() {
    watch = hasUnseen
    hplace = ALIGN_RIGHT
    children = hasUnseen.value ? smallUnseenIcon : null
  }
}

let mkSquadMkChild = @(squadId) @(sf, selected) {
  hplace = ALIGN_RIGHT
  margin = smallPadding
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    mkSquadExp(squadId)(sf, selected)
    unseenInSquadIcon(squadId)
  ]
}

let researchesSquads = Computed(@() (curUnlockedSquads.value ?? [])
  .map(@(s) s.__merge({
    mkChild = mkSquadMkChild(s.squadId)
    level = curArmySquadsProgress.value?[s.squadId].level ?? 0
  })))

let researches = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        armySelectUi
        wndHeader
        campaignTitle
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      size = [pageWidth, flex()]
      gap = bigPadding
      children = [
        mkCurSquadsList({
          curSquadsList = researchesSquads
          curSquadId = viewSquadId
          setCurSquadId = @(squadId) viewSquadId(squadId)
        })
        researchesTable
      ]
    }
  ]
}

return mkLockByCampaignProgress(@() {
  watch = hasResearchesSection
  size = flex()
  halign = ALIGN_RIGHT
  children = hasResearchesSection.value
    ? researches
    : mkDisabledSectionBlock({ descLocId = "menu/lockedByCampaignDesc" })
})
