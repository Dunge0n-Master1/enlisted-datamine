from "%enlSqGlob/ui_library.nut" import *

let { get_time_msec } = require("dagor.time")
let { low_level_client} = require("%enlSqGlob/charClient.nut")
let CharClientEvent = require("%enlSqGlob/charClient/charClientEvent.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")

const LEADERBOARD_NO_START_LIST_INDEX = 0x7FFFFFFF
const LB_REQUEST_TIMEOUT = 45000
const LB_UPDATE_INTERVAL = 5000 //same lb update time

let curLbData = Watched(null)
let curLbSelfRow = Watched(null)
let curLbRequestData = Watched(null)
let curLbErrName = Watched(null)
local lastRequestTime = 0
local lastUpdateTime = 0


let lbHandlers = {}
let lbClient = CharClientEvent({ name = "leaderboard", client = low_level_client, handlers = lbHandlers })

let function mkSelfRequest(requestData) {
  if (requestData == null)
    return null
  let res = clone requestData
  res.start <- LEADERBOARD_NO_START_LIST_INDEX
  res.count <- 0
  return res
}

let function setLbRequestData(requestData) {
  if (isEqual(requestData, curLbRequestData.value))
    return

  if (!isEqual(mkSelfRequest(requestData), mkSelfRequest(curLbRequestData.value)))
    curLbSelfRow(null)
  curLbData(null) //should to nullify it before curLbRequestData subscribers receive event
  curLbErrName(null)
  curLbRequestData(requestData)
}

let function requestSelfRow() {
  let requestData = curLbRequestData.value
  if (requestData == null)
    return

  assert(requestData.appid >= 0)
  let selfRequest = mkSelfRequest(requestData)
  lbClient.request("cln_get_leaderboard_json:self", { data = selfRequest }, selfRequest)
}


lbHandlers["cln_get_leaderboard_json:self"] <- function(result, selfRequest) {
  if (!isEqual(selfRequest, mkSelfRequest(curLbRequestData.value)))
    return

  local newSelfRow = null
  foreach (data in result)
    if (data?._id == userInfo.value?.userId) {
      newSelfRow = data
      newSelfRow.name <- userInfo.value?.nameorig ?? ""
      break
    }
  curLbSelfRow(newSelfRow)
}


let isRequestInProgress = @() lastRequestTime > lastUpdateTime
  && lastRequestTime + LB_REQUEST_TIMEOUT > get_time_msec()

let canRefresh = @() !isRequestInProgress()
  && isLoggedIn.value
  && (!curLbData.value || (lastUpdateTime + LB_UPDATE_INTERVAL < get_time_msec()))

let function refreshLbData() {
  if (!canRefresh())
    return
  let requestData = curLbRequestData.value
  if (requestData == null) {
    curLbData([])
    curLbErrName(null)
    return
  }

  lastRequestTime = get_time_msec()
  lbClient.request("cln_get_leaderboard_json", { data = requestData }, requestData)
}


lbHandlers["cln_get_leaderboard_json"] <- function(result, requestData) {
  lastUpdateTime = get_time_msec()
  if (!isEqual(requestData, curLbRequestData.value)) {
    refreshLbData()
    return
  }

  curLbErrName(result?.result.error)

  let isSuccess = result?.result.success ?? true
  let lbTbl = isSuccess ? result : {}
  local selfRow = null
  let newLbData = []
  foreach (name, data in lbTbl) {
    if (typeof data != "table" || (data?.idx ?? -1) < 0)
      continue
    data.name <- name
    newLbData.append(data)
    if (data?._id == userInfo.value?.userId)
      selfRow = data
  }
  newLbData.sort(@(a, b)
    (b?.idx ?? -1) >= 0 <=> (a?.idx ?? -1) >= 0 || (a?.idx ?? -1) <=> (b?.idx ?? -1))

  if (selfRow)
    curLbSelfRow(selfRow)
  curLbData(newLbData)
}


return {
  curLbData
  curLbSelfRow
  curLbRequestData = Computed(@() curLbRequestData.value)
  curLbErrName = Computed(@() curLbErrName.value)

  lbHandlers
  lbClient
  setLbRequestData
  refreshLbData
  requestSelfRow
}