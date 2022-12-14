from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let { round_by_value } = require("%sqstd/math.nut")
let { do_research, change_research, buy_change_research, buy_squad_exp, add_army_squad_exp_by_id
} = require("%enlist/meta/clientApi.nut")
let servResearches = require("%enlist/meta/profile.nut").researches
let { configs } = require("%enlist/meta/configs.nut")
let { curArmiesList, armySquadsById, curSquadId, curArmy, maxCampaignLevel, armyItemCountByTpl,
  curCampItems
} = require("%enlist/soldiers/model/state.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let squadsPresentation = require("%enlSqGlob/ui/researchSquadsPresentation.nut")
let prepareResearch = require("researchesPresentation.nut")
let recalcMultiResearchPos = require("recalcMultiResearchPos.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let { disabledSectionsData } = require("%enlist/mainMenu/disabledSections.nut")
let { isResearchesOpened } = require("%enlist/mainMenu/sectionsState.nut")
let { get_setting_by_blk_path } = require("settings")
let hideLockedResearches = get_setting_by_blk_path("hideLockedResearches") ?? false

const WORKSHOP_UNLOCK_LEVEL = 3
const WORKSHOP_PAGE_ID = 2
const CHANGE_RESEARCH_TPL = "research_change_order"

let hasResearchesSection = Computed(@() !(disabledSectionsData.value?.RESEARCHES ?? false))

let isBuyLevelInProgress = Watched(false)
let isResearchInProgress = Watched(false)
let viewSquadId = Watched(curSquadId.value)
curSquadId.subscribe(@(squadId) viewSquadId(squadId))
isResearchesOpened.subscribe(@(val) val ? viewSquadId(curSquadId.value) : null)


let changeResearchBalance = Computed(@() armyItemCountByTpl.value?[CHANGE_RESEARCH_TPL] ?? 0)
let changeResearchGoldCost = Computed(@() configs.value?.gameProfile.changeResearchGoldCost ?? 0)

let configResearches = Computed(function() {
  let src = configs.value?.researches ?? {}
  let res = {}
  foreach (armyId, armyConfig in src) {
    let presentList = squadsPresentation?[armyId]
    let armyPages = {}
    res[armyId] <- {
      squads = armyConfig?.squads
      pages = armyPages
    }
    foreach (squadId, pageList in armyConfig?.pages ?? {})
      armyPages[squadId] <- pageList.map(function(page, idx) {
        page = (page ?? {}).__merge(presentList?[idx] ?? {})
        if ("tables" not in page)
          page.tables <- {}
        return page
      })
  }
  return res
})

let armiesResearches = Computed(function() {
  let res = {}
  foreach (armyId, armyConfig in configResearches.value) {
    let researchesMap = {}
    foreach (squadPages in armyConfig.pages)
      foreach (page in squadPages)
        foreach (research in page.tables)
          if (!hideLockedResearches || !(research?.isLocked ?? false))
            researchesMap[research.research_id] <- research

    res[armyId] <- {
      squads = armyConfig.squads
      pages = armyConfig.pages //pages by squadId
      researches = researchesMap
    }
  }
  return res
})

let stateResearches = Computed(@() servResearches.value.map(@(data) {
    guid = data.guid
    researched = data.researched ?? {}
    squadProgress = data.squadProgress ?? {}
  }))

let selectedResearch = Watched(null)
let selectedTable = mkWatched(persist,"selectedTable", 0)

let LOCKED_BY_CAMPAIGN_LVL = 0
let LOCKED = 1
let DEPENDENT = 2
let NOT_ENOUGH_EXP = 3
let GROUP_RESEARCHED = 4
let CAN_RESEARCH = 5
let RESEARCHED = 6

let squadResearches = Computed(function() {
  let armyId = curArmy.value
  local { researches = null } = armiesResearches.value?[armyId]
  if (!researches)
    return null

  let squadId = viewSquadId.value
  return researches
    .filter(@(r) r.squad_id == squadId)
    .reduce(function(res, r) {
      let { page_id = 0 } = r
      while (res.len() <= page_id)
        res.append([])
      res[page_id].append(r)
      return res
    }, [])
    .map(function(lst) {
      let pageContext = {
        armyId
        squadId
        squadsCfg = squadsCfgById.value
        alltemplates = allItemTemplates.value
      }
      lst.sort(@(a, b) a.line <=> b.line || a.tier <=> b.tier)
      lst = lst
        .map(@(research) prepareResearch(research, pageContext))
        .reduce(function(res, r) {
          res[r.research_id] <- r
          return res
        }, {})
      recalcMultiResearchPos(lst)
      return lst
    })
})

let tableStructure = Computed(function() {
  let armyId = curArmy.value
  let squadId = viewSquadId.value
  let curResearches = armiesResearches.value?[armyId]
  let ret = {
    armyId = armyId
    squadId = squadId
    tiersTotal = 0
    minTier = 0
    rowsTotal = 0
    researches = {}
    pages = []
  }

  if (!curResearches)
    return ret

  let pages = curResearches.pages?[squadId]
  if (pages == null)
    return ret

  ret.pages = pages
  ret.researches = squadResearches.value?[selectedTable.value] ?? {}

  local minTier = -1
  local maxTier = -1
  local rowsTotal = 0
  foreach (def in ret.researches) {
    let tier = round_by_value(def.tier, 1)
    minTier = minTier < 0 ? tier : min(tier, minTier)
    maxTier = max(tier, maxTier)
    rowsTotal = max(def.line, rowsTotal)
  }
  ret.__update({ minTier, tiersTotal = maxTier - minTier + 1, rowsTotal })
  return ret
})

let isOpenResearch = @(research, researched)
  (research?.requirements ?? []).findindex(@(id) !researched?[id]) == null

let function isResearched(research, researched) {
  return researched?[research.research_id] ?? false
}

let function calcResearchedGroups(researches, researched) {
  let res = {}
  foreach (rId, val in researched) {
    if (!val)
      continue
    let { squad_id = "", page_id = 0, multiresearchGroup = 0 } = researches?[rId]
    if (multiresearchGroup <= 0)
      continue
    if (squad_id not in res)
      res[squad_id] <- {}
    if (page_id not in res[squad_id])
      res[squad_id][page_id] <- {}
    res[squad_id][page_id][multiresearchGroup] <- true
  }
  return res
}

let isCampaignLevelLow = @(campLevel, pageId)
  campLevel < WORKSHOP_UNLOCK_LEVEL && pageId == WORKSHOP_PAGE_ID

let allResearchStatus = Computed(function() {
  let res = {}
  let campLevel = maxCampaignLevel.value
  foreach (armyId in curArmiesList.value) {
    let researches = armiesResearches.value?[armyId].researches ?? {}
    let researched = stateResearches.value?[armyId].researched ?? {}
    let squadProgress = stateResearches.value?[armyId].squadProgress
    let squads = armySquadsById.value?[armyId] ?? {}
    let groups = calcResearchedGroups(researches, researched)
    res[armyId] <- researches.map(@(research)
      isResearched(research, researched) ? RESEARCHED
        : isCampaignLevelLow(campLevel, research?.page_id ?? 0) ? LOCKED_BY_CAMPAIGN_LVL
        : (research?.isLocked ?? false) ? LOCKED
        : (research?.multiresearchGroup ?? 0) > 0
            && (groups?[research.squad_id][research?.page_id ?? 0][research.multiresearchGroup] ?? false)
          ? GROUP_RESEARCHED
        : squads?[research.squad_id] == null || !isOpenResearch(research, researched) ? DEPENDENT
        : (research?.price ?? 0) <= (squadProgress?[research.squad_id].points ?? 0) ? CAN_RESEARCH
        : NOT_ENOUGH_EXP)
  }
  return res
})

let allResearchProgress = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value) {
    let researches = armiesResearches.value?[armyId].researches ?? {}
    let researched = stateResearches.value?[armyId].researched ?? {}
    res[armyId] <- researched.reduce(@(cnt, val, key)
      val && (researches?[key].price ?? 0) > 0 ? cnt + 1 : cnt, 0)
  }
  return res
})

let researchStatuses = Computed(@() allResearchStatus.value?[curArmy.value] ?? {})
let curArmySquadsProgress = Computed(@() stateResearches.value?[curArmy.value].squadProgress)
let allSquadsPoints = Computed(@() (curArmySquadsProgress.value ?? {}).map(@(p) p.points))
let allSquadsLevels = Computed(@() (curArmySquadsProgress.value ?? {}).map(@(p) p.level))
let curSquadPoints = Computed(@() allSquadsPoints.value?[viewSquadId.value] ?? 0)

let curSquadProgress = Computed(function() {
  let squadCfg = armiesResearches.value?[curArmy.value].squads[viewSquadId.value]
  let { levels  = [] } = squadCfg
  let res = {
    level = 0
    exp = 0
    points = 0
    nextLevelExp = 0
    levelCost = 0
    maxLevel = levels.len()
  }.__update(curArmySquadsProgress.value?[viewSquadId.value] ?? {})

  let levelExp = levels?[res.level].exp ?? 0
  let levelCost = levels?[res.level].levelCost ?? 0
  let needExp = levelExp - res.exp

  res.nextLevelExp = levelExp
  if (levelExp > 0 && needExp > 0 && levelCost > 0)
    res.levelCost = max(levelCost * needExp / levelExp, 1)

  return res
})

let function addArmySquadExp(armyId, exp, squadId) {
  if (!(armyId in stateResearches.value)) {
    logerr($"Unable to charge exp for army {armyId}")
    return
  }

  add_army_squad_exp_by_id(armyId, exp, squadId)
}

let function research(researchId) {
  if (isResearchInProgress.value || researchStatuses.value?[researchId] != CAN_RESEARCH)
    return
  isResearchInProgress(true)
  do_research(tableStructure.value.armyId, researchId, @(_) isResearchInProgress(false))
}

let function changeResearch(researchFrom, researchTo) {
  if (isResearchInProgress.value
      || researchStatuses.value?[researchTo] != GROUP_RESEARCHED
      || researchStatuses.value?[researchFrom] != RESEARCHED)
    return
  let payData = getPayItemsData({ [CHANGE_RESEARCH_TPL] = 1 }, curCampItems.value)
  if (payData == null)
    return
  isResearchInProgress(true)
  change_research(tableStructure.value.armyId, researchFrom, researchTo, payData,
    @(_) isResearchInProgress(false))
}

let function buyChangeResearch(researchFrom, researchTo) {
  if (isResearchInProgress.value
      || researchStatuses.value?[researchTo] != GROUP_RESEARCHED
      || researchStatuses.value?[researchFrom] != RESEARCHED)
  isResearchInProgress(true)
  buy_change_research(tableStructure.value.armyId, researchFrom, researchTo, changeResearchGoldCost.value,
    @(_) isResearchInProgress(false))
}

let closestTargets = Computed(function() {
  let list = squadResearches.value
  if (!list)
    return null

  return list.map(function(researches) {
    local pageTop = null
    foreach (r in researches) {
      let status = researchStatuses.value?[r.research_id]
      if (status != CAN_RESEARCH && status != NOT_ENOUGH_EXP)
        continue

      let { line, tier } = r
      if (pageTop == null || line < pageTop.line || (line == pageTop.line && tier < pageTop.tier))
        pageTop = r
    }
    return pageTop
  })
})

let function buySquadLevel(cb = null) {
  if (isBuyLevelInProgress.value)
    return

  let { nextLevelExp = 0, exp = 0, levelCost = 0 } = curSquadProgress.value
  let needExp = nextLevelExp - exp
  if (needExp <= 0 || levelCost <= 0)
    return

  isBuyLevelInProgress(true)
  buy_squad_exp(curArmy.value, viewSquadId.value, needExp, levelCost,
    function(res) {
      isBuyLevelInProgress(false)
      cb?(res?.error == null)
    })
}

let function findAndSelectClosestTarget(...) {
  let tableResearches = tableStructure.value.researches
    .values()
    .sort(@(a, b) a.line <=> b.line || a.tier <=> b.tier)
  local isLockedByCampaignLvl = false
  foreach (val in tableResearches) {
    let status = researchStatuses.value?[val.research_id]
    if (status == CAN_RESEARCH || status == NOT_ENOUGH_EXP) {
      selectedResearch(val)
      return
    }
    if (status == LOCKED_BY_CAMPAIGN_LVL)
      isLockedByCampaignLvl = true
  }
  selectedResearch({
    isLockedByCampaignLvl
    research_id = ""
    name = "researches/allResearchesResearchedName"
    description = "researches/allResearchesResearchedDescription"
  })
}
researchStatuses.subscribe(findAndSelectClosestTarget)
tableStructure.subscribe(findAndSelectClosestTarget)
findAndSelectClosestTarget()

console_register_command(
  function(exp) {
    if (curArmy.value && viewSquadId.value != null) {
      addArmySquadExp(curArmy.value, exp, viewSquadId.value)
      log_for_user($"Add exp for {curArmy.value} / {viewSquadId.value}")
    } else
      log_for_user("Army or squad is not selected")
  },
  "meta.addCurSquadExp")

return {
  hasResearchesSection
  closestTargets
  configResearches
  armiesResearches
  selectedTable
  tableStructure
  selectedResearch
  viewArmy = curArmy
  viewSquadId

  allResearchStatus
  allResearchProgress
  researchStatuses
  allSquadsLevels
  allSquadsPoints
  curSquadPoints
  curArmySquadsProgress
  curSquadProgress
  changeResearchBalance
  changeResearchGoldCost

  research
  changeResearch
  buyChangeResearch
  isResearchInProgress
  isBuyLevelInProgress
  addArmySquadExp
  buySquadLevel

  LOCKED
  DEPENDENT
  NOT_ENOUGH_EXP
  GROUP_RESEARCHED
  CAN_RESEARCH
  RESEARCHED

  CHANGE_RESEARCH_TPL
  BALANCE_ATTRACT_TRIGGER = "army_balance_attract"
}
