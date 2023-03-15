from "%enlSqGlob/ui_library.nut" import *
let { platformAlias } = require("%dngscripts/platform.nut")
let { logerr } = require("dagor.debug")
let matching_errors = require("matching.errors")
let getMissionInfo = require("getMissionInfo.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { availableClusters, clusterLoc, oneOfSelectedClusters } = require("%enlist/clusterState.nut")
let { createEventRoomCfg, allModes, getValuesFromRule
} = require("createEventRoomCfg.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { createRoom, changeAttributesRoom, room, isInRoom, roomPasswordToJoin
} = require("%enlist/state/roomState.nut")
let { getValInTblPath, setValInTblPath } = require("%sqstd/table.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { isCrossplayOptionNeeded, crossnetworkPlay, availableCrossplayOptions, CrossplayState
} = require("%enlSqGlob/crossnetwork_state.nut")
let saveCrossnetworkPlayValue = require("%enlist/options/crossnetwork_save.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { receivedModInfos, modPath, getModPathToStart } = require("sandbox/customMissionState.nut")
let { set_matching_invite_data } = require("app")
let gameLauncher = require("%enlist/gameLauncher.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")

let consoleAliases = ["sony", "xbox"]
let allAliases = ["pc", "sony", "xbox", "mobile"]
let selectedCampaignsFilters = Watched([])
let currentPassword = Watched("")

const OPT_EDITBOX = "editbox"
const OPT_LIST = "list"
const OPT_CHECKBOX = "checkbox"
const OPT_MULTISELECT = "multiselect"
const MODDED_CONFIG_POSTFIX = "_MODDED"
const PASSWORD_MAX_LENGTH = 16

const SAVE_ID = "eventRoomParams"
let saved = Computed(@() settings.value?[SAVE_ID])
let function save(key, value) {
  if (saved.value?[key] != value)
    settings.mutate(@(s) s[SAVE_ID] <- (s?[SAVE_ID] ?? {}).__merge({ [key] = value }))
}
let mkSave = @(key) @(value) save(key, value)

let isAnyModEnabled = @() modPath.value != ""

let availableModes = Computed(function() {
  if (isAnyModEnabled()) {
    let modMode = receivedModInfos.value?[modPath.value].room_params.defaults.public.mode
    if (modMode != null)
      return [modMode]
  }
  return allModes.value
})

let curMode = Computed(function() {
  let val = saved.value?.mode ?? "SQUADS"
  return availableModes.value.contains(val) ? val
    : (availableModes.value?[0] ?? "")
})

let curCfgName = Computed(function() {
  let moddedPostfix = modPath.value == "" ? "" : MODDED_CONFIG_POSTFIX
  let cfgName = $"{curMode.value}{moddedPostfix}"
  let availableConfigs = createEventRoomCfg.value.keys()
  return availableConfigs.contains(cfgName)
    ? cfgName
    : availableConfigs.contains(curMode.value)
      ? curMode.value
      : (availableConfigs?[0] ?? "")
})

let curCfg = Computed(@() createEventRoomCfg.value?[curCfgName.value])

let isEditEventRoomOpened = mkWatched(persist, "isEditEventRoomOpened", false)
let isEditInProgress = Watched(false)
room.subscribe(function(v) { if (v != null) isEditEventRoomOpened(false) })

let function getValuesByRule(rule, curValues) {
  let { override = [] } = rule
  local { values, isMultival } = getValuesFromRule(rule)
  foreach (ovr in override) {
    local isFit = true
    foreach (fName, fValue in ovr?.applyIf ?? {}) {
      if (fName not in curValues)
        return null //not all values are ready to check filters
      if (curValues[fName] != fValue) {
        isFit = false
        break
      }
    }
    if (!isFit)
      continue
    let ovrValues = getValuesFromRule(ovr).values
    if (ovrValues.len() > 0)
      values = ovrValues
  }
  return { values, isMultival }
}

let function parseMatchingError(loc_base, response) {
  if (response.error != matching_errors.SERVER_ERROR_GENERIC)
    return loc(loc_base, { responce_error = matching_errors.error_string(response.error)}) // 'responce' is a typo. 'response' is a correct spelling for this word

  let errorId = response.error_id
  let errorInfo = response?.info
  let errorIdStr = loc(loc_base, { responce_error = errorId})
  if (errorInfo == null)
    return errorIdStr

  return $"{errorIdStr}\nparam: {errorInfo?.param}\n{errorInfo?.detail}"
}

let getDefValue = @(defaults, id) getValInTblPath(defaults, id.split("/"))
let prevIfEqual = @(newValue, prevValue)
  isEqual(newValue, prevValue) ? prevValue : newValue

let optionsConfig = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = { curValues = {}, optionsInfo = {} }

  let curValues = {}
  let optionsInfo = {}
  let { defaults = {} } = curCfg.value
  let rules = (curCfg.value?.rules ?? {}).__merge(
    receivedModInfos.value?[modPath.value].room_params.rules ?? {})
  let leftKeys = rules.keys()
  while(leftKeys.len() > 0) {
    let leftKeysOnCycleStart = leftKeys.len()
    for(local i = leftKeys.len() - 1; i >= 0; i--) {
      let name = leftKeys[i]
      let rule = rules[name]
      let { values = null, isMultival = false } = getValuesByRule(rule, curValues)
      if (values == null)
        continue

      if (values.len() == 0) {
        //empty list or not supported rule, or string rule
        if ("max_strlen" in rule) {
          let optInfo = {
            optType = OPT_EDITBOX
            maxChars = rule.max_strlen
          }
          optionsInfo[name] <- prevIfEqual(optInfo, prev.optionsInfo?[name])
        }
        leftKeys.remove(i)
        continue
      }

      local curValue = saved.value?[name]
      let valueType = rule?.type ?? type(values[0])
      if (isMultival)
        curValue = prevIfEqual(
          type(curValue) == "array" ? curValue.filter(@(v) values.contains(v))
            : values.contains(curValue) ? [curValue]
            : (getDefValue(defaults, name) ?? values),
          prev.curValues?[name])
      else if (!values.contains(curValue)) {
        let newVal = getDefValue(defaults, name)
        curValue = values.contains(newVal) ? newVal : values?[0]
      }
      if (curValue == null) {
        logerr($"Create room param {name} does not have default value. (mode = {curCfgName.value})")
        continue
      }

      curValues[name] <- curValue
      let optInfo = {
        values
        optType = isMultival ? OPT_MULTISELECT
          : valueType == "bool" ? OPT_CHECKBOX
          : OPT_LIST
      }
      optionsInfo[name] <- prevIfEqual(optInfo, prev.optionsInfo?[name])
      leftKeys.remove(i)
    }

    if (leftKeysOnCycleStart == leftKeys.len()) {
      let txt = ", ".join(leftKeys)
      logerr($"Unable to process create room options because of bad filters in override or empty values list. (mode = {curCfgName.value}) [{txt}]")
      break
    }
  }

  return {
    curValues
    optionsInfo
  }
})

let mkToggleValue = @(id, cfg, curValue) function toggleValue(value, isChecked) {
  if (cfg.value?.optType != OPT_MULTISELECT) {
    logerr($"Try to call addValue/removeValue for not multiselect option: {id}")
    return
  }
  local res = saved.value?[id]
  if (type(res) != "array")
    res = curValue.value
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

let function mkOption(id, locId, valToString = @(v) v, typeToString = @(v) v) {
  let staticInfo = { locId }
  let cfg = Computed(@() optionsConfig.value.optionsInfo?[id].__merge(staticInfo))
  let curValue = Computed(@() optionsConfig.value.curValues?[id])
  return {
    id
    cfg
    curValue
    setValue = mkSave(id)
    valToString
    typeToString
    toggleValue = mkToggleValue(id, cfg, curValue)
  }
}

let optionLoc = @(v) loc($"options/{v}", v)
let getBoolText = @(value) value ? loc("quickchat/yes") : loc("quickchat/no")

//*********************************************************//
//********************** OPTIONS **************************//
//*********************************************************//

let optIsPrivate = mkOption("public/isPrivate", "options/private")
let optDifficulty = mkOption("public/difficulty", "options/difficulty", optionLoc)
let optMaxPlayers = mkOption("public/maxPlayers", "options/maxPlayers")
let optBotCount = mkOption("public/botpop", "options/botCount")
let optTeamArmies = mkOption("public/teamArmies", "options/teamArmies", optionLoc)

let teamArmies = optTeamArmies.curValue
let optVoteToKick = mkOption("public/voteToKick", "options/voteToKick", getBoolText)

let optModeId = "mode"
let optMode = {
  id = optModeId
  cfg = Computed(@() { locId = "current_mode", optType = OPT_LIST, values = availableModes.value })
  curValue = curMode
  isEditAllowed = false
  setValue = mkSave(optModeId)
  valToString = loc
}

let optPasswordId = "password"
let optPassword = {
  id = optPasswordId
  cfg = Computed(@() {
    locId = "options/password",
    optType = OPT_EDITBOX,
    maxChars = curCfg.value?.rules[optPasswordId].max_strlen ?? PASSWORD_MAX_LENGTH
    isHidden = !(hasPremium.value || isInRoom.value)
  })
  curValue = currentPassword
  isEditAllowed = false
  password = true
  charMaskTypes = "lat; integer"
  setValue = currentPassword
  optDummy = loc("password_access")
  placeholder = loc("create_pass")
}

let optClusterId = "public/cluster"
let optCluster = {
  id = optClusterId
  cfg = Computed(@() { locId = "quickMatch/Server", optType = OPT_LIST, values = availableClusters.value })
  curValue = Computed(function() {
    let res = saved.value?[optClusterId]
    return availableClusters.value.contains(res) ? res : oneOfSelectedClusters.value
  })
  setValue = mkSave(optClusterId)
  valToString = clusterLoc
}

let optCampId = "public/campaigns"
let optCampStatic = { locId = "options/campaigns" }
let campCfg = Computed(function() {
  let res = optionsConfig.value.optionsInfo?[optCampId]
  if (res == null)
    return res
  let unlocked = unlockedCampaigns.value
  return res.__merge(optCampStatic, { values = res.values.filter(@(c) unlocked.contains(c)) })
})

let campaigns = Computed(function() {
  let unlocked = unlockedCampaigns.value
  return optionsConfig.value.curValues?[optCampId].filter(@(c) unlocked.contains(c))
})
let optCampaigns = {
  id = optCampId
  cfg = campCfg
  curValue = campaigns
  setValue = mkSave(optCampId)
  toggleValue = mkToggleValue(optCampId, campCfg, campaigns)
  valToString = @(c) loc(gameProfile.value?.campaigns[c]?.title ?? c)
}

let optMissionsId = "public/scenes"
let optMissionsCfg = Computed(@() optionsConfig.value.optionsInfo?[optMissionsId]
  .__merge({ locId = "options/missions" }))
let optMissionsCurValue = Computed(function() {
  let res = optionsConfig.value.curValues?[optMissionsId]
  return typeof res == "table" ? [] : res
})
let optMissions = {
  id = optMissionsId
  cfg = optMissionsCfg
  curValue = optMissionsCurValue
  setValue = mkSave(optMissionsId)
  typeToString = @(s) loc(getMissionInfo(s).typeLocId)
  toggleValue = mkToggleValue(optMissionsId, optMissionsCfg, optMissionsCurValue)
  valToString = @(s) loc(getMissionInfo(s).locId)
}


let mCurValueBase = optMissions.curValue
let mCfgBase = optMissions.cfg
let mCfg = Computed(function(prev) {
  let cfg = mCfgBase.value
  if (cfg == null)
    return cfg

  let isHistorical = teamArmies.value == "historical"
  let campaignsV = selectedCampaignsFilters.value.len() > 0
    ? selectedCampaignsFilters.value
    : unlockedCampaigns.value ?? []

  let isAnyCampaign = campaignsV.len() == 0
  if (!isHistorical && isAnyCampaign)
    return cfg

  let values = cfg.values
    .map(function(blk) {
      let info = getMissionInfo(blk)
      info.blk <- blk
      return info
    })
    .filter(@(m) m.campaign == ""
      ? !isHistorical
      : (isAnyCampaign || campaignsV.contains(m.campaign)))
    .sort(@(a, b) a.type <=> b.type
      || a.id <=> b.id)
    .map(@(c) c.blk)

  return isEqual(values, prev?.values ?? []) ? prev : cfg.__merge({ values })
})

let missions = Computed(function(prev) {
  let { values = [], optType = null } = mCfg.value
  if (optType != OPT_MULTISELECT)
    return mCurValueBase.value

  let res = (mCurValueBase.value ?? []).filter(@(m) values.contains(m))
  return prevIfEqual(res, prev)
})

optMissions.__update({
  curValue = missions
  cfg = mCfg
})

let cpId = "public/crossplay"
let cpLocId = "options/crossplay"
let optCrossplay = mkOption(cpId, cpLocId, @(v) loc($"option/crossplay/{v}"))
let cpCfgBase = optCrossplay.cfg
optCrossplay.__update({ isEditAllowed = false })

let function updateOptCrossplay(val) {
  if (!val)
    optCrossplay.__update({ cfg = Watched(null) })
  else {
    let cpCfg = Computed(function() {
      let { optType = null, values = null } = cpCfgBase.value
      if (optType != OPT_LIST
          || availableCrossplayOptions.value.findvalue(@(v) !values.contains(v)) != null)
        return null //crossplay option has incorrect format
      return cpCfgBase.value.__merge({ values = availableCrossplayOptions.value })
    })
    optCrossplay.__update({
      cfg = cpCfg
      curValue = crossnetworkPlay
      setValue = saveCrossnetworkPlayValue
    })
  }
}

isCrossplayOptionNeeded.subscribe(updateOptCrossplay)
updateOptCrossplay(isCrossplayOptionNeeded.value)

let function getCrossPlatformsList() {
  let all = optionsConfig.value.optionsInfo?["public/crossPlatform"].values
  if (all == null)
    return []
  let allowTbl = {}
  let curCP = crossnetworkPlay.value
  let aliasesList = curCP == CrossplayState.ALL ? allAliases
    : curCP == CrossplayState.CONSOLES ? consoleAliases
    : platformAlias
  foreach (alias in aliasesList)
    allowTbl[$"{alias}_{curCP}"] <- true
  return all.filter(@(p) p in allowTbl)
}


let function isScenesNull() {
  local scenes = missions.value ?? []
  if (scenes.len() == 0) {
    scenes = optMissions.cfg.value?.values ?? []
    if (scenes.len() == 0) {
      return true
    }
  }
  return false
}

let function isModsNull() {
  let mods = receivedModInfos.value ?? []
  return mods.len() == 0
}

let function createEventRoom() {
  if (isEditInProgress.value)
    return

  if (isModsNull() && isScenesNull()) {
    logerr("Can't create room because missions list and mods list is empty")
    return
  }

  let roomParams = {
    lobby_template = curCfgName.value
    public = {
      cTime = serverTime.value
    }
  }

  foreach (opt in [
    optIsPrivate
    optDifficulty
    optMaxPlayers
    optBotCount
    optTeamArmies
    optVoteToKick
    optCrossplay
    optCluster
    optMissions
    optCampaigns
    optPassword
  ])
    if (opt.cfg.value != null && opt.curValue.value != "")
      setValInTblPath(roomParams, opt.id.split("/"),
        type(opt.curValue.value) == "array" && opt.curValue.value.len() == 0
          ? opt.cfg.value.values
          : opt.curValue.value)

  roomParams.public.creatorId <- userInfo.value.userIdStr
  let modInfo = receivedModInfos.value?[modPath.value]
  let modHash = modInfo?.content[0].hash // Only one file support now(blk with scene)
  let modId = modInfo?.id
  let modName = modInfo?.title
  let modDescription = modInfo?.description
  let modVersion = modInfo?.version

  if (isAnyModEnabled() && modHash != null)
    roomParams.public.__update({ modId, modHash, modName, modDescription, modVersion })

  let crossPlatform = getCrossPlatformsList()
  if (crossPlatform.len() > 0)
    roomParams.public.crossPlatform <- crossPlatform

  isEditInProgress(true)
  if (modPath.value != "" && optMaxPlayers.curValue.value <= 1) {
    set_matching_invite_data({ mode_info = roomParams.public })
    gameLauncher.startGame({ scene = getModPathToStart(), modId = modId })
    isEditInProgress(false)
    return
  }

  createRoom(roomParams,
    function onResult(response) {
      isEditInProgress(false)
      isEditEventRoomOpened(false)
      if (response.error != 0)
        msgbox.show({ text = parseMatchingError("customRoom/failCreate", response) })
      if (response?.public.hasPassword ?? false){
        let password = optPassword.curValue.value
        let roomId = response.roomId
        roomPasswordToJoin.mutate(@(v) v[roomId] <- password)
      }
    })
}

let function updateAttributesEventRoom() {
  if (isEditInProgress.value)
    return

  if (isModsNull() && isScenesNull()) {
    logerr("Can't change room's attributes because missions list and mods list is empty")
    return
  }

  let roomParams = {
    lobby_template = curCfgName.value
    public = {
      cTime = serverTime.value
    }
  }

  foreach (opt in [
    optIsPrivate
    optDifficulty
    optMaxPlayers
    optBotCount
    optTeamArmies
    optVoteToKick
    optCrossplay
    optCluster
    optMissions
    optCampaigns
    optPassword
  ])
    if (opt.cfg.value != null && (opt?.isEditAllowed ?? true)) {
      let path = opt.id.split("/")
      let newParam = type(opt.curValue.value) == "array" && opt.curValue.value.len() == 0
        ? opt.cfg.value.values
        : opt.curValue.value
      let oldParam = getValInTblPath(room.value, path)

      if (!isEqual(oldParam, newParam))
        setValInTblPath(roomParams, path, newParam)
    }

  if (roomParams.len() == 0)
    return isEditEventRoomOpened(false)

  isEditInProgress(true)
  changeAttributesRoom(roomParams,
    function onResult(response) {
      isEditInProgress(false)
      if (response.error != 0)
        return msgbox.show({ text = parseMatchingError("customRoom/failChange", response) })
      isEditEventRoomOpened(false)
    })
}

let editEventRoom = @() isInRoom.value ? updateAttributesEventRoom() : createEventRoom()

console_register_command(@() isEditEventRoomOpened(!isEditEventRoomOpened.value), "openCreateEventRoomWnd")

return {
  OPT_EDITBOX
  OPT_LIST
  OPT_CHECKBOX
  OPT_MULTISELECT

  optIsPrivate
  optMode
  optDifficulty
  optMaxPlayers
  optBotCount
  optTeamArmies
  optVoteToKick
  optCrossplay
  optMissions
  optCluster
  optCampaigns
  optPassword

  isInRoom
  isEditInProgress
  isEditEventRoomOpened
  editEventRoom
  selectedCampaignsFilters
  currentPassword
}
