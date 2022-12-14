from "%enlSqGlob/ui_library.nut" import *

let userstat = require_optional("userstats")
if (userstat==null)
  return require("userstatSecondary.nut") //ui VM, receive all data by cross call instead of host

let loginState = require("%enlSqGlob/login_state.nut")
let CharClientEvent = require("%enlSqGlob/charClient/charClientEvent.nut")

let logUs = require("%enlSqGlob/library_logs.nut").with_prefix("[USERSTAT] ")
let { split_by_chars } = require("string")
let { debug } = require("dagor.debug")
let { debounce } = require("%sqstd/timers.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { get_time_msec } = require("dagor.time")
let {error_response_converter} = require("%enlSqGlob/netErrorConverter.nut")
let {globalWatched} = require("%dngscripts/globalState.nut")
let eventbus = require("eventbus")
let matchingNotifications = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { get_app_id } = require("app")
let { arrayByRows } = require("%sqstd/underscore.nut")

let { appId, gameLanguage } = require("%enlSqGlob/clientState.nut")
let time = require("serverTime.nut")
let { serverTimeUpdate } = require("serverTimeUpdate.nut")

let handlers  = {}
let executors = {}
let clientUserStats = CharClientEvent({name   = "userStats",
                                         client = userstat,
                                         handlers,
                                         executors})


let adminHandlers   = {}
let adminUserStats  = CharClientEvent({name     = "userStats.admin",
                                         client   = userstat,
                                         handlers = adminHandlers})

const STATS_REQUEST_TIMEOUT = 45000
const STATS_UPDATE_INTERVAL = 300000 //unlocks progress update interval
const MAX_DELAY_FOR_MASSIVE_REQUEST_SEC = 60 //random delay up to this value when all player want the same config simultaneously.

let chardToken = keepref(Computed(@() userInfo.value?.token))
let userId = keepref(Computed(@() userInfo.value?.userId))

local needSyncSteamAchievements = false
userId.subscribe(@(_v) needSyncSteamAchievements = loginState.isSteamRunning.value)

let errorLogMaxLen = 10
let errorLog = mkWatched(persist, "errorLog", [])
let lastSuccessTime = mkWatched(persist, "lastSuccessTime", 0)

let function checkError(actionId, result) {
  if (result?.error == null)
    return
  errorLog.mutate(function(l) {
    l.append({ action = actionId, result = result, time = get_time_msec() })
    if (l.len() > errorLogMaxLen)
      l.remove(0)
  })
}

let function doRequest(request, cb) {
  userstat.request(request, @(result) error_response_converter(cb, result))
}


let syncSteamAchievements = @() clientUserStats.request("SyncUnlocksWithSteam")

handlers["SyncUnlocksWithSteam"] <- @(_)null


let function makeUpdatable(persistName, request, watches, defValue) {
  let dataKey = $"userstat.{persistName}"
  let lastTimeKey = $"userstat.{persistName}.lastTime"
  let dataS = globalWatched(dataKey, @() defValue)
  let lastTimeS = globalWatched(lastTimeKey, @() { request = 0, update = 0 })
  let data = dataS[dataKey]
  let dataUpdate = dataS[$"{dataKey}Update"]
  let lastTime = lastTimeS[lastTimeKey]
  let lastTimeUpdate = lastTimeS[$"{lastTimeKey}Update"]
  let isRequestInProgress = @() lastTime.value.request > lastTime.value.update
    && lastTime.value.request + STATS_REQUEST_TIMEOUT > get_time_msec()
  let canRefresh = @() !isRequestInProgress()
    && (!lastTime.value.update || (lastTime.value.update + STATS_UPDATE_INTERVAL < get_time_msec()))

  let function processResult(result, cb) {
    checkError(persistName, result)
    if (cb)
      cb(result)

    serverTimeUpdate(1000 * (result?.response.timestamp ?? 0), lastTime.value.request)
    if (result?.error) {
      dataUpdate(defValue)
      logUs($"Failed to update {persistName}")
      logUs(result)
      return
    }
    lastSuccessTime(get_time_msec())
    dataUpdate(result?.response ?? defValue)

    if (needSyncSteamAchievements) {
      syncSteamAchievements()
      needSyncSteamAchievements = false
    }
  }

  let function prepareToRequest() {
    lastTimeUpdate(lastTime.value.__merge({request = get_time_msec()}))
  }

  let function refresh(cb = null) {
    if (!chardToken.value || appId.value < 0) {
      dataUpdate(defValue)
      if (cb)
        cb({ error = "not logged in" })
      return
    }
    if (!canRefresh())
      return

    prepareToRequest()

    request(function(result){
      processResult(result, cb)
    })
  }

  let function forceRefresh(cb = null) {
    lastTimeUpdate(lastTime.value.__merge({ update = 0, request = 0}))
    refresh(cb)
  }

  foreach (w in watches)
    w.subscribe(function(_v) {
      lastTimeUpdate(lastTime.value.__merge({update = 0}))
      dataUpdate(defValue)
      forceRefresh()
    })

  if (lastTime.value.request > lastTime.value.update)
    forceRefresh()

  return {
    id = persistName
    data
    refresh
    forceRefresh
    processResult
    prepareToRequest
    lastUpdateTime = Computed(@() lastTime.value.update)
  }
}


let descListUpdatable = makeUpdatable("GetUserStatDescList",
  @(cb) doRequest({
    headers = {
      appid = appId.value,
      token = chardToken.value,
      language = loc("steam/languageName", gameLanguage).tolower()
    },
    action = "GetUserStatDescList"
  }, cb),
  [appId, chardToken],
  {})

let statsFilter = mkWatched(persist, "statsFilter", {
  //tables = [ "global" ]
  modes = [ "solo", "duo", "group" ]
  //stats  = [ "winRating", "killRating", "battles" ]
})

let unlocksFilter = mkWatched(persist, "unlocksFilter", {})

let function setUnlocksFilter(uFilter) {
  unlocksFilter(uFilter)
}

let toTable = @(arr) arr.reduce(@(res, v) res.rawset(v, true), {})

let function isEqualUnordered(arr1, arr2) {
  let tbl1 = toTable(arr1)
  let tbl2 = toTable(arr2)
  if (tbl1.len() != tbl2.len())
    return false
  foreach (val, _ in tbl1)
    if (val not in tbl2)
      return false
  return true
}

let function setStatsModes(modes) {
  let curModes = statsFilter.value.modes
  if (!isEqualUnordered(curModes, modes))
    statsFilter.mutate(function(v) { v.modes = modes })
}

let statsUpdatable = makeUpdatable("GetStats",
  @(cb) doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
      },
      action = "GetStats"
      data = statsFilter.value,
    }, cb),
  [appId, chardToken, statsFilter],
  {})

let unlocksUpdatable = makeUpdatable("GetUnlocks",
  @(cb) doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
      },
      action = "GetUnlocks"
      data = unlocksFilter.value,
    }, cb),
  [appId, chardToken, unlocksFilter],
  {})

let lastMassiveRequestTime = mkWatched(persist, "lastMassiveRequestTime", 0)
let massiveRefresh = debounce(
  function(checkTime) {
    logUs("Massive update start")
    foreach (data in [statsUpdatable, descListUpdatable, unlocksUpdatable])
      if (data.lastUpdateTime.value < checkTime) {
        logUs($"Update {data.id}")
        data.forceRefresh()
      }
    lastMassiveRequestTime(checkTime)
  }, 0, MAX_DELAY_FOR_MASSIVE_REQUEST_SEC)

let nextMassiveUpdateTime = mkWatched(persist, "nextMassiveUpdateTime", 0)
statsUpdatable.data.subscribe(function(stats) {
  local nextUpdate = 0
  let curTime = time.value
  foreach (tbl in stats?.inactiveTables ?? {}) {
    let startsAt = tbl?["$startsAt"] ?? 0
    if (startsAt > curTime)
      nextUpdate = nextUpdate > 0 ? min(nextUpdate, startsAt) : startsAt
  }
  foreach (tbl in stats?.stats ?? {}) {
    let endsAt = tbl?["$endsAt"] ?? 0
    if (endsAt > curTime)
      nextUpdate = nextUpdate > 0 ? min(nextUpdate, endsAt) : endsAt
  }
  nextMassiveUpdateTime(nextUpdate)
})

let lastMassiveRequestQueued = mkWatched(persist, "lastMassiveRequestQueued", 0)
if (lastMassiveRequestQueued.value > lastMassiveRequestTime.value)
  massiveRefresh(lastMassiveRequestQueued.value) //if reload script while wait for the debounce
let function queueMassiveUpdate() {
  logUs("Queue massive update")
  lastMassiveRequestQueued(nextMassiveUpdateTime.value)
  massiveRefresh(nextMassiveUpdateTime.value)
}

let function startMassiveUpdateTimer() {
  if (nextMassiveUpdateTime.value <= lastMassiveRequestTime.value)
    return
  gui_scene.clearTimer(queueMassiveUpdate)
  gui_scene.setTimeout(nextMassiveUpdateTime.value - time.value, queueMassiveUpdate)
}
startMassiveUpdateTimer()
nextMassiveUpdateTime.subscribe(@(_) startMassiveUpdateTimer())


let function regeneratePersonalUnlocks(context = null) {
  clientUserStats.request("RegeneratePersonalUnlocks", {}, context)
}


handlers["RegeneratePersonalUnlocks"] <- function(result, context) {
  if ("console_print" in context)
    console_print(result)
  if (result?.error)
    return
  unlocksUpdatable.forceRefresh()
  statsUpdatable.forceRefresh()
}


let function generatePersonalUnlocks(context = null) {
  clientUserStats.request("GeneratePersonalUnlocks", {data = {table = "daily"}}, context)
}

handlers["GeneratePersonalUnlocks"] <- function(result, context) {
  if ("console_print" in context)
    console_print(result)
  if (!result?.error)
    unlocksUpdatable.forceRefresh()
}


//config = { <unlockId> = <stage> }
let function setLastSeen(config) {
  clientUserStats.request("SetLastSeenUnlocks", {data = config})
}

handlers["SetLastSeenUnlocks"] <- function(result) {
  if (!result?.error)
    unlocksUpdatable.forceRefresh()
}

let unlockRewardsInProgress = Watched({})
let function receiveRewards(unlockName, stage, context = null) {
  if (unlockName in unlockRewardsInProgress.value)
    return
  logUs($"receiveRewards {unlockName}={stage}", context)
  unlockRewardsInProgress.mutate(@(u) u[unlockName] <- true)
  clientUserStats.request("GrantRewards",
    {data = {unlock = unlockName, stage = stage}},
    (context ?? {}).__merge({ unlockName }))
}

handlers["GrantRewards"] <- function(result, context) {
  let { unlockName  = null } = context
  if (unlockName in unlockRewardsInProgress.value)
    unlockRewardsInProgress.mutate(@(v) delete v[unlockName])
  logUs("GrantRewards result:", result)
  if ("error" in result)
    return
  unlocksUpdatable.forceRefresh()
  statsUpdatable.forceRefresh()
}


let function resetPersonalUnlockProgress(unlockName, context = null) {
  adminUserStats.request("AdmResetPersonalUnlockProgress", {
    headers = { token = chardToken.value, userId = userId.value },
    data = { unlock = unlockName }
  },
  context)
}

adminHandlers["AdmResetPersonalUnlockProgress"] <- function(result, context) {
  if ("console_print" in context)
    console_print(result)
  if (!result?.error)
    unlocksUpdatable.forceRefresh()
}


let function rerollUnlock(unlockName, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value },
    data = { unlock = unlockName }
    action = "RerollPersonalUnlock"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(cb)
    statsUpdatable.forceRefresh()
  })
}

let function selectUnlockRewards(unlockName, selectedArray, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value },
    data = { unlock = unlockName, selection = selectedArray }
    action = "SelectRewards"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(cb)
  })
}


let function changeStat(stat, mode, amount, shouldSet, cb = null) {
  local errorText = null
  if (typeof amount != "integer" && typeof amount != "float")
    errorText = $"Amount must be numeric (current = {amount})"
  else if (descListUpdatable.data.value?.stats?[stat] == null) {
    errorText = $"Stat {stat} does not exist."
    let similar = []
    let parts = split_by_chars(stat, "_", true)
    foreach (s, _v in descListUpdatable.data.value?.stats ?? {})
      foreach (part in parts)
        if (s.indexof(part) != null) {
          similar.append(s)
          break
        }
    let statsText = "\n      ".join(["  Similar stats:"].extend(arrayByRows(similar, 8).map(@(v) " ".join(v))))
    errorText = "\n  ".join([errorText, statsText], true)
  }

  if (errorText != null) {
    cb?({ error = errorText })
    return
  }

  doRequest({
      headers = {
        appid = appId.value,
        token = chardToken.value
        userId = userId.value
      },
      data = {
        [stat] = shouldSet ? { "$set": amount } : amount,
        ["$mode"] = mode
      }
      action = "ChangeStats"
    },
    function(result) {
      cb?(result)
      if (!result?.error) {
        unlocksUpdatable.forceRefresh()
        statsUpdatable.forceRefresh()
      }
    })
}


let function addStat(stat, mode, amount, cb = null) {
  changeStat(stat, mode, amount, false, cb)
}


let function setStat(stat, mode, amount, cb = null) {
  changeStat(stat, mode, amount, true, cb)
}


let function sendPsPlus(havePsPlus, token, cb = null) {
  let haveTxt = havePsPlus ? "present" : "absent"
  debug($"Sending PS+: {haveTxt}")
  doRequest({
      headers = {
        appid = get_app_id(),
        token = token
      },
      data = {
        ["have_ps_plus"] = havePsPlus ? true : false
      },
      action = "SetPsPlus"
    },
    function(result) {
      if (cb)
        cb({})
      if (result?.error)
        debug($"Failed to send PS+: {result.error}")
      else
        debug("Succesfully sent PS+")
    })
}


let function getStatsSum(tableName, statName) {
  local res = 0
  let tbl = statsUpdatable.data.value?.stats?[tableName]
  if (tbl)
    foreach (modeTbl in tbl)
      res += modeTbl?[statName] ?? 0
  return res
}


let function buyUnlock(unlockName, stage, currency, price, cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value}
    data = { name = unlockName, stage = stage, price = price, currency = currency },
    action = "BuyUnlock"
  },
  function(result) {
    if (result?.error) {
      if (cb)
        cb(result)
      return
    }
    unlocksUpdatable.forceRefresh(function(_res) {
      statsUpdatable.forceRefresh(cb)
    })
  })
}

let seasonRewards = mkWatched(persist, "seasonRewards", null)
let function updateSeasonRewards(cb = null) {
  doRequest({
    headers = { appid = appId.value, token = chardToken.value}
    action = "GetSeasonRewards"
  },
  function(result) {
    if (!result?.error)
      seasonRewards(result?.response)
    cb?(result)
  })
}

let function clnChangeStats(data, cb = null) {
  statsUpdatable.prepareToRequest()
  unlocksUpdatable.prepareToRequest()
  data["$filter"] <- statsFilter.value
  doRequest({
    headers = { appid = appId.value, token = chardToken.value}
    data = data
    action = "ClnChangeStats"
  },
  function(result) {
    statsUpdatable.processResult(result, cb)
    unlocksUpdatable.processResult(result, cb)
  })
}

let function clnAddStat(mode, stat, amount, cb = null) {
  let data = {
      [stat] = amount,
      ["$mode"] = mode
  }

  clnChangeStats(data, cb)
}

let function clnSetStat(mode, stat, amount, cb = null) {
  let statData = {
    ["$set"] = amount
  }

  let data = {
      [stat] = statData,
      ["$mode"] = mode
  }

  clnChangeStats(data, cb)
}

let function markUserLogsAsSeen(userlogs) {
  doRequest({
    headers = {
      appid = appId.value,
      token = chardToken.value
    },
    action = "SetLastSeenUserLogs"
    data = { userlogs },
  }, function(result) {
    if ("error" not in result) {
      unlocksUpdatable.forceRefresh()
      statsUpdatable.forceRefresh()
    }
  })
}

matchingNotifications.subscribe("userStat",
  @(ev) ev?.func == "updateConfig" ? queueMassiveUpdate() : unlocksUpdatable.forceRefresh())


let function requestAnoPlayerStats(uid, cb){
  doRequest({
    headers = {
      appid = appId.value,
      token = chardToken.value
      userId = uid
    },
    action = "AnoGetStats"
    allow_other = true
    data = statsFilter.value
  }, cb)
}

let debugRecursive = @(v) log.debugTableData(v, { recursionLevel = 7, printFn = debug })
console_register_command(@() descListUpdatable.forceRefresh(console_print), "userstat.get_desc_list")
console_register_command(@() debugRecursive(descListUpdatable.data.value) ?? console_print("Done"),
  "userstat.debug_desc_list")
console_register_command(@() statsUpdatable.forceRefresh(console_print), "userstat.get_stats")
console_register_command(@() debugRecursive(statsUpdatable.data.value) ?? console_print("Done"),
  "userstat.debug_stats")
console_register_command(@() unlocksUpdatable.forceRefresh(console_print), "userstat.get_unlocks")
console_register_command(@() regeneratePersonalUnlocks({console_print = true}), "userstat.reset_personal")
console_register_command(@() updateSeasonRewards(@(v) debugRecursive(v?.response ?? v) ?? console_print("Done")), "userstat.get_season_rewards")
console_register_command(@(unlockName) resetPersonalUnlockProgress(unlockName, {console_print = true}), "userstat.reset_unlock_progress")
console_register_command(@() generatePersonalUnlocks({console_print = true}), "userstat.generate_personal")
console_register_command(@() debugRecursive(unlocksUpdatable.data.value?.personalUnlocks), "userstat.debug_personal")
console_register_command(@(stat, mode, amount) addStat(stat, mode, amount, console_print), "userstat.add_stat")
console_register_command(@(stat, mode, amount) setStat(stat, mode, amount, console_print), "userstat.set_stat")
console_register_command(@() syncSteamAchievements(), "userstat.sync_steam_achievements")
console_register_command(@(have_psplus) sendPsPlus(have_psplus, chardToken.value), "userstat.set_ps_plus")
console_register_command(@(mode, stat, amount) clnAddStat(mode, stat, amount, console_print), "userstat.cln_add_stat")
console_register_command(@(mode, stat, amount) clnSetStat(mode, stat, amount, console_print), "userstat.cln_set_stat")
console_register_command(@() nextMassiveUpdateTime(time.value + 1), "userstat.test_massive_update")
console_register_command(@(amount) addStat("monthly_challenges", "solo", amount, console_print), "unlocks.add")

console_register_command(@(userlogs) markUserLogsAsSeen(userlogs), "unlocks.markUserLogsAsSeen")


let dbgUserstatFailed = Watched(false)
console_register_command(@() dbgUserstatFailed(!dbgUserstatFailed.value), "userstat.fail")

let cmdList = {
  setLastSeenCmd = @(d) setLastSeen(d?.p ?? d)
  refreshStats = @(_d = null) statsUpdatable.refresh()
  forceRefreshUnlocks = @(_d = null) unlocksUpdatable.forceRefresh()
}

eventbus.subscribe("userstat.cmd", @(d) cmdList?[d.cmd]?(d))
let isUserstatFailedGetData = Computed(
    @() dbgUserstatFailed.value || (errorLog.value.len() > 0
      && (lastSuccessTime.value <= 0 || errorLog.value.top().time > lastSuccessTime.value)))

return {
  buyUnlock,
  userstatStats = statsUpdatable.data
  userstatUnlocks = unlocksUpdatable.data
  userstatTime = time
  userstatDescList = descListUpdatable.data
  userstatErrorLog = errorLog
  userstatExecutors = executors
  isUserstatFailedGetData
  setLastSeenUnlocks = setLastSeen
  getUserstatsSum = getStatsSum
  receiveUnlockRewards = receiveRewards
  setUserstat = clnSetStat
  sendPsPlusStatusToUserstatServer = sendPsPlus
  selectUnlockRewards = selectUnlockRewards
  rerollUnlock = rerollUnlock
  updateSeasonRewards
  seasonRewards
  forceRefreshUnlocks = cmdList.forceRefreshUnlocks
  setLastSeenUnlocksCmd = cmdList.setLastSeenCmd
  refreshUserstats = cmdList.refreshStats
  forceRefreshUserstats = @() statsUpdatable.forceRefresh()
  setStatsModes
  setUnlocksFilter
  markUserLogsAsSeen

  requestAnoPlayerStats

  unlockRewardsInProgress
}
