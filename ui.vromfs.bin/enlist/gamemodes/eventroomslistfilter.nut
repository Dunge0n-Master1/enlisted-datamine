from "%enlSqGlob/ui_library.nut" import *
let { logerr } = require("dagor.debug")
let { unique } = require("%sqstd/underscore.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { createEventRoomCfg, allModes, getValuesFromRule } = require("createEventRoomCfg.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { availableClusters, clusterLoc } = require("%enlist/clusterState.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let {
  isCrossplayOptionNeeded, crossnetworkPlay, CrossplayState, availableCrossplayOptions,
  CrossPlayStateWeight
} = require("%enlSqGlob/crossnetwork_state.nut")

const OPT_SWITCH = "switch"
const OPT_MULTISELECT = "multiselect"
const OPT_RADIO = "radioselect"

const SAVE_ID = "eventRoomFilter"
const MODE_ID = "public/mode"
let saved = Computed(@() settings.value?[SAVE_ID])
let function save(key, value) {
  if (saved.value?[key] != value)
    settings.mutate(@(s) s[SAVE_ID] <- (s?[SAVE_ID] ?? {}).__merge({ [key] = value }))
}
let function clearFilters() {
  if (saved.value != null)
    settings.mutate(@(s) delete s[SAVE_ID])
}
let isFiltersChanged = Computed(@() (saved.value?.len() ?? 0) != 0)
let curModes = Computed(@() (saved.value?[MODE_ID] ?? []).filter(@(m) allModes.value.contains(m)))

let mkSave = @(key) @(value) save(key, value)

let function getValuesByRule(rule, curValues) {
  let { values } = getValuesFromRule(rule)
  let { override = [] } = rule

  let res = []

  if (type(override) != "array") {
    logerr($"Error in getValuesByRule. Override property must have array type.")
    return res;
  }

  local canApplyDefault = true
  for(local i = override.len() - 1; i >= 0; i--) {
    let ovr = override[i]
    let ovrValues = getValuesFromRule(ovr).values
    if (ovrValues.len() == 0)
      continue

    local isFit = true
    local isOverrideDefault = false
    foreach (fName, fValue in ovr?.applyIf ?? {}) {
      if (fName not in curValues)
        return null //not all values are ready to check filters
      local val = curValues[fName]
      if (type(val) == "array")
        val = val.len() == 1 ? val[0] : null //filter values only when single value selected. Filters no need to be too complex
      isFit = val == null || fValue == val
      if (isFit)
        isOverrideDefault = isOverrideDefault || val != null
      else
        break
    }
    if (isFit) {
      res.extend(ovrValues)
      canApplyDefault = canApplyDefault && !isOverrideDefault
    }
  }
  if (canApplyDefault)
    res.extend(values)
  return unique(res)
}

let function updateValues(toTbl, fromTbl) {
  foreach (key, list in fromTbl)
    if (key in toTbl)
      toTbl[key].extend(list)
    else
      toTbl[key] <- clone list
}

let prevIfEqual = @(newValue, prevValue) isEqual(newValue, prevValue) ? prevValue : newValue
let prepareMergedValues = @(newTbl, prevTbl)
  newTbl.map(@(list, key) prevIfEqual(unique(list), prevTbl?[key]))

let optionsConfig = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = { curValues = {}, availValues = {} }

  let curValues = {}
  let availValues = {}

  let modesList = curModes.value.len() > 0 ? curModes.value : allModes.value
  foreach (mode in modesList) {
    let { rules = {} } = createEventRoomCfg.value?[mode]
    let modeCurValues = {}
    let modeAvailValues = {}
    let leftKeys = rules.keys()
    while(leftKeys.len() > 0) {
      let leftKeysOnCycleStart = leftKeys.len()
      for(local i = leftKeys.len() - 1; i >= 0; i--) {
        let name = leftKeys[i]
        let values = getValuesByRule(rules[name], modeCurValues)
        if ((values?.len() ?? 0) == 0)
          continue

        modeCurValues[name] <- (saved.value?[name] ?? []).filter(@(v) values.contains(v))
        modeAvailValues[name] <- values
        leftKeys.remove(i)
      }

      if (leftKeysOnCycleStart == leftKeys.len())
        break //no need logerr here, because we will have it by room options already.
    }

    updateValues(curValues, modeCurValues)
    updateValues(availValues, modeAvailValues)
  }

  return {
    curValues = prepareMergedValues(curValues, prev.curValues)
    availValues = prepareMergedValues(availValues, prev.availValues)
  }
})

let mkToggleValue = @(id, curValues) function toggleValue(value, isChecked) {
  local res = saved.value?[id]
  if (type(res) != "array")
    res = curValues.value
  let idx = res.indexof(value)
  if ((idx != null) == isChecked)
    return
  res = clone res
  if (isChecked)
    res.append(value)
  else
    res.remove(idx)
  save(id, res)
}

let function mkOption(id, locId, valToString = @(v) v) {
  let allValues = Computed(@() optionsConfig.value.availValues?[id])
  let curValues = Computed(@() optionsConfig.value.curValues?[id] ?? [])
  return {
    id
    optType = OPT_MULTISELECT
    locId
    valToString
    allValues
    curValues
    setValue = mkSave(id)
    toggleValue = mkToggleValue(id, curValues)
  }
}

let optionLoc = @(v) loc($"options/{v}", v)
let filterByList = @(res, filterList)
  res?.filter(@(v) filterList.contains(v))

//****************************************************************//
//********************** FILTER OPTIONS **************************//
//****************************************************************//

let optDifficulty = mkOption("public/difficulty", "options/difficulty", optionLoc)

let optCrossplay = mkOption("public/crossplay", "options/crossplay", @(v) loc($"option/crossplay/{v}"))
let function updateOptCrossplay(val) {
  if (!val)
    optCrossplay.__update({ allValues = Watched(null) })
  else {
    let cpAVBase = optCrossplay.allValues
    let cpCVBase = optCrossplay.curValues
    let cpAllValues = Computed(function() {
      let values = cpAVBase.value
      if (values == null
          || crossnetworkPlay.value == CrossplayState.OFF
          || availableCrossplayOptions.value.findvalue(@(v) !values.contains(v)) != null)
        return null //crossplay option has incorrect format
      let curWeight = CrossPlayStateWeight?[crossnetworkPlay.value] ?? 100
      return availableCrossplayOptions.value.filter(@(v) (CrossPlayStateWeight?[v] ?? 100) <= curWeight)
    })
    let cpCurValues = Computed(function() {
      let all = cpAllValues.value
      let defaultValue = [crossnetworkPlay.value]
      if (all == null)
        return defaultValue
      let value = cpCVBase.value.filter(@(v) all.contains(v))
      return value.len() > 0 ? value : defaultValue
    })
    optCrossplay.__update({ allValues = cpAllValues, curValues = cpCurValues, optType = OPT_RADIO })
  }
}

isCrossplayOptionNeeded.subscribe(updateOptCrossplay)
updateOptCrossplay(isCrossplayOptionNeeded.value)

let optMode = mkOption(MODE_ID, "current_mode", loc)
optMode.__update({ allValues = allModes, curValues = curModes })

let optCampaigns = mkOption("public/campaigns", "options/campaigns",
  @(c) loc(gameProfile.value?.campaigns[c]?.title ?? c))
let campAllValuesBase = optCampaigns.allValues
let campCurValuesBase = optCampaigns.curValues
optCampaigns.__update({
  allValues = Computed(@() filterByList(campAllValuesBase.value, unlockedCampaigns.value))
  curValues = Computed(@() filterByList(campCurValuesBase.value, unlockedCampaigns.value))
})

let optClusterId = "cluster"
let curClusters = Computed(@() filterByList(saved.value?[optClusterId] ?? [], availableClusters.value))
let optCluster = {
  id = optClusterId
  optType = OPT_MULTISELECT
  locId = "quickMatch/Server"
  valToString = clusterLoc
  allValues = availableClusters
  curValues = curClusters
  setValue = mkSave(optClusterId)
  toggleValue = mkToggleValue(optClusterId, curClusters)
}

let locOn = loc($"option/on")
let locOff = loc($"option/off")

let optFullRoomsId = "fullRooms"
let optFullRooms = {
  id = optFullRoomsId
  optType = OPT_SWITCH
  locId = "rooms/HideFull"
  valToString = @(v) v ? locOn : locOff
  curValue = Computed(@() saved.value?[optFullRoomsId] ?? false)
  setValue = mkSave(optFullRoomsId)
}

let optModRoomsId = "ModRooms"
let optModRooms = {
  id = optModRoomsId
  optType = OPT_SWITCH
  locId = "rooms/HideMods"
  valToString = @(v) v ? locOn : locOff
  curValue = Computed(@() saved.value?[optModRoomsId] ?? false)
  setValue = mkSave(optModRoomsId)
}

let optPasswordRoomsId = "PasswordRooms"
let optPasswordRooms = {
  id = optPasswordRoomsId
  optType = OPT_SWITCH
  locId = "rooms/HidePasswordRooms"
  valToString = @(v) v ? locOn : locOff
  curValue = Computed(@() saved.value?[optPasswordRoomsId] ?? false)
  setValue = mkSave(optPasswordRoomsId)
}

console_register_command(clearFilters, "customRooms.resetFilter")

return {
  OPT_MULTISELECT
  OPT_RADIO
  OPT_SWITCH
  isFiltersChanged
  clearFilters

  optMode
  optDifficulty
  optCrossplay
  optCampaigns
  optCluster
  optFullRooms
  optModRooms
  optPasswordRooms
}