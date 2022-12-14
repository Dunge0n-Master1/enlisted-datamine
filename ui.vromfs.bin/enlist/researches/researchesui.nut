from "%enlSqGlob/ui_library.nut" import *

let researchIcons = require("%enlSqGlob/ui/researchIcons.nut")
let researchBtnsUi = require("researchBtnsUi.nut")
let squadInfo = require("%enlist/squad/squadInfo.nut")

let { progressBar } = require("%enlSqGlob/ui/defComponents.nut")
let { makeVertScroll, styling } = require("%ui/components/scrollbar.nut")
let { mkLockByCampaignProgress } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { mkDisabledSectionBlock } = require("%enlist/mainMenu/disabledSections.nut")
let { curArmy, armySquadsById } = require("%enlist/soldiers/model/state.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let { colFull, colPart, columnGap } = require("%enlSqGlob/ui/designConst.nut")
let {
  hasResearchesSection, tableStructure, selectedTable, selectedResearch,
  researchStatuses, armiesResearches, viewSquadId, viewArmy,
  curSquadProgress, curSquadPoints, RESEARCHED
} = require("researchesState.nut")
let {
  mkResearchPageSlot, mkResearchPageInfo, mkResearchColumn, mkResearchInfo,
  mkPointsInfo, mkWarningText, squadInfoWidth, mkPageInfoAnim
} = require("researchesPkg.nut")


let curSquadData = Computed(@() armySquadsById.value?[viewArmy.value][viewSquadId.value])


let miniGap = (columnGap * 0.5).tointeger()
let headerHeight = colPart(5)
let researchInfoWidth = colFull(5)
let progressWidth = colFull(7)
let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })


let researchCbCtor = @(research) @() selectedResearch(research)


let function pagesListUi() {
  let { pages = [] } = tableStructure.value
  return {
    watch = [tableStructure, selectedTable]
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children = pages.map(function(page, pageIdx) {
      let isSelected = selectedTable.value == pageIdx
      let onClick = @() selectedTable(pageIdx)
      let iconPath = researchIcons?[page?.icon_id]
      return mkResearchPageSlot(iconPath, isSelected, onClick)
    })
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
    size = [progressWidth, flex()]
    flow = FLOW_VERTICAL
    gap = miniGap
    valign = ALIGN_BOTTOM
    children = [
      mkPointsInfo(level, points)
      progressBar(exp.tofloat() / nextLevelExp)
    ]
  })
}


let pagesUi = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    pagesListUi
    pagesInfoUi
    progressUi
  ]
}

let function calcResearchesStructure(researches) {
  let allRequirements = {}
  let allDependences = {}
  foreach (research in researches) {
    let { research_id, requirements = [] } = research
    if (requirements.len() == 0)
      continue
    allDependences[research_id] <- requirements
    foreach (requirementId in requirements)
      allRequirements[requirementId] <- true
  }

  let columns = []
  local main = allRequirements.findindex(@(_, req) req not in allDependences)
  while (main != null) {
    let researchColumn = { main }
    let children = []
    foreach (depId, reqList in allDependences) {
      if (depId in allRequirements)
        continue
      if (reqList.contains(main)) {
        let { multiresearchGroup = 0 } = researches[depId]
        if (multiresearchGroup == 0)
          children.append(depId)
        else {
          let idx = children
            .findindex(@(r) (r?.multiresearchGroup ?? 0) == multiresearchGroup)
          if (idx == null)
            children.append({ multiresearchGroup, children = [depId] })
          else
            children[idx].children.append(depId)
        }
      }
    }
    columns.append(researchColumn.__update({ children }))
    main = allRequirements.findindex(@(_, req)
      allDependences?[req].contains(main) ?? false)
  }

  return columns
}


let function researchesTreeUi() {
  let { researches } = tableStructure.value
  let { research_id = null } = selectedResearch.value
  let rStatuses = researchStatuses.value
  let columns = calcResearchesStructure(researches)
  return {
    watch = [tableStructure, selectedResearch, researchStatuses]
    size = flex()
    children = makeVertScroll({
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      padding = [0, colPart(1)]
      valign = ALIGN_CENTER
      children = columns.map(function(column, idx) {
        let { main, children } = column
        let rMain = researches[main]
        let rChildren = children.map(@(child)
          type(child) == "string" ? [researches[child]]
            : type(child) == "table" ? child.children.map(@(c) researches[c])
            : null
        )
        return mkResearchColumn(idx, rMain, rChildren, research_id, rStatuses, researchCbCtor)
      })
    }, {
      size = flex()
      rootBase = class {
        behavior = Behaviors.Pannable
        wheelStep = 1
      }
      styling = scrollStyle
    })
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
  gap = columnGap
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    @() {
      watch = curSquadData
      children = mkSquadIcon(curSquadData.value?.icon)
    }
    squadInfo()
  ]
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
  gap = colPart(1)
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
