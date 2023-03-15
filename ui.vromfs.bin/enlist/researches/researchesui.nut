from "%enlSqGlob/ui_library.nut" import *

let researchBtnsUi = require("researchBtnsUi.nut")
let squadInfo = require("%enlist/squad/squadInfo.nut")
let researchStatusesCfg = require("researchStatuses.nut")

let { toIntegerSafe } = require("%sqstd/string.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { progressBar } = require("%enlSqGlob/ui/defComponents.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { mkLockByCampaignProgress } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { mkDisabledSectionBlock } = require("%enlist/mainMenu/disabledSections.nut")
let { curArmy, armySquadsById } = require("%enlist/soldiers/model/state.nut")
let { colFull, colPart, columnGap } = require("%enlSqGlob/ui/designConst.nut")
let {
  hasResearchesSection, tableStructure, selectedTable, selectedResearch,
  researchStatuses, armiesResearches, viewSquadId, viewArmy,
  curSquadProgress, curSquadPoints, RESEARCHED
} = require("researchesState.nut")
let {
  mkResearchPageSlot, mkResearchPageInfo, mkResearchColumn, mkResearchInfo,
  mkPointsInfo, mkWarningText, squadInfoWidth, mkPageInfoAnim, mkResearchItem,
  slotSize, slotGapSize
} = require("researchesPkg.nut")


let curSquadData = Computed(@() armySquadsById.value?[viewArmy.value][viewSquadId.value])


let miniGap = (columnGap * 0.5).tointeger()
let headerHeight = colPart(4.5)
let researchInfoWidth = colFull(5)
let columnsInScreen = Computed(function() {
  let safeAreaBordersVal = safeAreaBorders.value
  let freeWidth = sw(100) - (safeAreaBordersVal[1] + safeAreaBordersVal[2] + researchInfoWidth)
  return ((freeWidth - slotSize[0]) / (slotSize[0] + slotGapSize[0]) + 1).tointeger()
})


let researchCbCtor = @(research) @() selectedResearch(research)
let researchDoubleCbCtor = @(research) function() {
  let statuses = researchStatuses.value
  if (statuses == null || research == null)
    return

  let { research_id = null } = research
  let status = statuses?[research_id]
  let cfg = researchStatusesCfg?[status](research)

  let { onResearch = null } = cfg
  if (onResearch != null)
    onResearch()
}

let function pagesListUi() {
  let { pages = [] } = tableStructure.value
  return {
    watch = [tableStructure, selectedTable]
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children = pages.map(@(_, pageIdx) watchElemState(function(sf) {
      let isSelected = selectedTable.value == pageIdx
      return {
        behavior = Behaviors.Button
        onClick = @() selectedTable(pageIdx)
        children = mkResearchPageSlot(pageIdx, isSelected, sf & S_HOVER)
      }
    }))
  }
}

let curPage = Computed(@() (tableStructure.value?.pages ?? [])?[selectedTable.value])

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


let function pagesInfoUi() {
  let page = curPage.value
  let squadId = viewSquadId.value
  let researches = (armiesResearches.value?[curArmy.value].researches ?? [])
    .filter(@(p) p.squad_id == squadId && (p?.page_id ?? 0) == (page?.page_id ?? 0))
  let availCount = calcAvailableResearchesCount(researches)
  let statuses = researchStatuses.value
  let completed = researches.reduce(@(res, val)
    statuses?[val.research_id] == RESEARCHED ? res + 1 : res, 0)
  let statusTxt = $"{completed}/{availCount}"

  return {
    watch = [curPage, armiesResearches, researchStatuses, curArmy, viewSquadId]
    size = [flex(), SIZE_TO_CONTENT]
    children = mkResearchPageInfo(page?.name, page?.description, statusTxt)
  }
}


let function progressUi() {
  let res = {
    watch = [curSquadData, curSquadProgress, curSquadPoints]
  }
  let isSquadPremium = (curSquadData.value?.battleExpBonus ?? 0) > 0
  if (isSquadPremium)
    return res

  let { level, exp, nextLevelExp } = curSquadProgress.value
  let points = curSquadPoints.value
  return res.__update({
    size = flex()
    valign = ALIGN_BOTTOM
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = miniGap
      children = [
        mkPointsInfo(level, points)
        progressBar(exp.tofloat() / nextLevelExp)
      ]
    }
  })
}


let pagesUi = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    pagesListUi
    pagesInfoUi
    progressUi
  ]
}


let curRequirements = Computed(function() {
  let res = {}
  foreach (research in tableStructure.value.researches) {
    let { research_id, requirements = [] } = research
    if (requirements.len() > 0)
      foreach (requirementId in requirements)
        res[requirementId] <- (res?[requirementId] ?? []).append(research_id)
  }
  return res
})

let curResearchChaines = Computed(function() {
  let allRequirements = curRequirements.value
  let res = {}
  foreach (research in tableStructure.value.researches) {
    let { research_id } = research
    local nextRes = research_id

    res[research_id] <- []
    while (nextRes != null) {
      res[research_id].append(nextRes)
      nextRes = allRequirements?[nextRes]?[0]
    }
  }
  return res
})

let function isNamesSimilar(nameA, nameB) {
  let nameArrA = nameA.split("_")
  let nameArrB = nameB.split("_")
  if (nameArrA.len() != nameArrB.len() || nameArrA.len() < 2)
    return false

  if (toIntegerSafe(nameArrA.top(), -1, false) < 0 || toIntegerSafe(nameArrB.top(), -1, false) < 0)
    return false

  nameArrA.resize(nameArrA.len() - 1)
  nameArrB.resize(nameArrB.len() - 1)
  return "_".join(nameArrA) == "_".join(nameArrB)
}

let validateMainResearch = @(curRes, mainRes, chainLen)
  curRes == null ? null
    : chainLen > 1 || (chainLen == 1 && isNamesSimilar(curRes, mainRes)) ? curRes
    : null

let tableViewStructure = Computed(function() {
  let { researches } = tableStructure.value
  let allRequirements = curRequirements.value
  let allChaines = curResearchChaines.value

  let columns = []
  local hasTemplatesLine = false
  local mainRes = researches.findindex(@(r) (r?.requirements ?? []).len() == 0)
  let templateCount = {}
  while (mainRes != null) {
    let research = researches[mainRes]
    let followResearches = allRequirements?[mainRes] ?? []
    let { gametemplate = null } = research
    columns.append({
      main = mainRes
      children = []
      template = gametemplate
      tplCount = 0
    })
    if (gametemplate != null) {
      hasTemplatesLine = true
      templateCount[gametemplate] <- (templateCount?[gametemplate] ?? 0) + 1
    }

    let hasMultResearches = followResearches.findvalue(@(resId)
      (researches?[resId].multiresearchGroup ?? 0) > 0) != null

    mainRes = followResearches.len() > 1
      ? followResearches.findvalue(function(resId) {
          if ((researches?[resId].multiresearchGroup ?? 0) > 0)
            return false
          if ((allRequirements?[resId] ?? []).len() > 1)
            return true

          let currChain = allChaines?[resId] ?? []
          return currChain.len() > 2
            || (currChain.len() == 2 && (isNamesSimilar(mainRes, resId) || hasMultResearches))
        })
      : validateMainResearch(followResearches?[0], mainRes, (allChaines?[followResearches?[0]] ?? []).len())
  }

  foreach (idx, column in columns) {
    let { main } = column
    let nextMain = columns?[idx + 1].main
    foreach (resId in allRequirements?[main] ?? []) {
      if (resId == nextMain)
        continue

      let { multiresearchGroup = 0 } = researches[resId]
      if (multiresearchGroup == 0)
        column.children.append({
          multiresearchGroup
          children = allChaines?[resId] ?? []
        })
      else {
        let cIdx = column.children
          .findindex(@(r) (r?.multiresearchGroup ?? 0) == multiresearchGroup)
        if (cIdx == null)
          column.children.append({ multiresearchGroup, children = [resId] })
        else
          column.children[cIdx].children.append(resId)
      }
    }
  }

  let maxChildHeight = [0, 0]
  let childCount = []
  foreach (column in columns) {
    let { template } = column
    if (template != "" && template in templateCount) {
      column.tplCount = templateCount[template]
      delete templateCount[template]
    }
    if ("children" not in column) {
      childCount.append(0, 0)
      continue
    }

    let prevCountTop = childCount?[childCount.len() - 2] ?? 0
    let prevCountBtm = childCount?[childCount.len() - 1] ?? 0
    let childTop = column?.children[0]
    let childBtm = column?.children[1]

    let countTop = (childTop?.multiresearchGroup ?? 0) == 0
      ? min((childTop?.children ?? []).len(), 1)
      : childTop.children.len()
    let countBtm = (childBtm?.multiresearchGroup ?? 0) == 0
      ? min((childBtm ?? []).len(), 1)
      : childBtm.children.len()

    let heightTop = max(maxChildHeight[0],
      (childTop?.multiresearchGroup ?? 0) == 0 ? (childTop?.children ?? []).len() : 1)
    let heightBtm = max(maxChildHeight[1],
      (childBtm?.multiresearchGroup ?? 0) == 0 ? (childBtm?.children ?? []).len() : 1)

    if (prevCountTop + countTop < 5 && prevCountBtm + countBtm < 5) {
      childCount.append(countTop, countBtm)
      maxChildHeight[0] = heightTop
      maxChildHeight[1] = heightBtm
    }
    else {
      column.children.clear()
      column.children.append(childBtm, childTop)
      childCount.append(countBtm, countTop)
      maxChildHeight[0] = heightBtm
      maxChildHeight[1] = heightTop
    }
  }

  return { columns, maxChildHeight, hasTemplatesLine }
})


let function researchesTreeUi() {
  let { researches } = tableStructure.value
  let { research_id = null } = selectedResearch.value
  let rStatuses = researchStatuses.value
  let { columns, maxChildHeight, hasTemplatesLine } = tableViewStructure.value
  let minHeightFlex = hasTemplatesLine ? 0.1 : 1
  let columnsCount = columns.len()

  let treeObject = {
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    padding = [0, colPart(1)]
    valign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        children = columns.map(@(column, idx) mkResearchItem(column, idx == columnsCount - 1))
      }
      { size = [0, flex(maxChildHeight[1] + minHeightFlex)] }
      {
        flow = FLOW_HORIZONTAL
        children = columns.map(function(column, idx) {
          let { main, children } = column
          let rMain = researches[main]
          let rChildren = children.map(@(child) {
              multiresearchGroup = child.multiresearchGroup
              researches = child.children.map(@(c) researches[c])
            }
          )
          return mkResearchColumn(idx, rMain, rChildren, research_id, rStatuses,
            researchCbCtor, researchDoubleCbCtor)
        })
      }
      { size = [0, flex(maxChildHeight[0] + minHeightFlex)] }
    ]
  }

  return {
    watch = [tableStructure, tableViewStructure, selectedResearch, researchStatuses, columnsInScreen]
    size = flex()
    children = columnsCount > columnsInScreen.value
      ? makeHorizScroll(treeObject, {
          size = flex()
          rootBase = class {
            behavior = Behaviors.Pannable
            wheelStep = 1
          }
        })
      : {
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = treeObject
        }
  }
}

let researchInfoUi = @() {
  watch = selectedResearch
  size = [researchInfoWidth, flex()]
  flow = FLOW_VERTICAL
  children = [
    mkResearchInfo(selectedResearch.value)
    researchBtnsUi
  ]
}

let function contentUi() {
  let isBranchEmpty = (tableStructure.value?.researches ?? {}).len() == 0
  let isCampaignLevelLow = selectedResearch.value?.isLockedByCampaignLvl ?? false
  return {
    watch = [tableStructure, selectedResearch]
    size = flex()
    children = isBranchEmpty ? mkWarningText("researches/willBeAvailableSoon")
      : isCampaignLevelLow ? mkWarningText("researches/levelTooLowForWorkshop")
      : {
          size = flex()
          flow = FLOW_HORIZONTAL
          gap = columnGap
          children = [ researchInfoUi, researchesTreeUi ]
        }
  }
}


let squadInfoUi = {
  size = [squadInfoWidth, flex()]
  valign = ALIGN_BOTTOM
  children = squadInfo(true, false)
}


let headerUi = {
  size = [flex(), headerHeight]
  flow = FLOW_HORIZONTAL
  children = [
    squadInfoUi
    pagesUi
  ]
}


let researchesUi = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = colPart(0.7)
  margin = [columnGap, 0, 0, 0]
  children = [
    headerUi
    contentUi
  ]
}.__update(mkPageInfoAnim(0))


return mkLockByCampaignProgress(@() {
  watch = hasResearchesSection
  size = flex()
  halign = ALIGN_RIGHT
  children = hasResearchesSection.value
    ? researchesUi
    : mkDisabledSectionBlock({ descLocId = "menu/lockedByCampaignDesc" })
})
