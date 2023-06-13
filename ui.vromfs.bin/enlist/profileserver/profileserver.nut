from "%enlSqGlob/ui_library.nut" import *

let profile_server = require("profile_server")
let { error_response_converter } = require("%enlSqGlob/netErrorConverter.nut")
let { appId } = require("%enlSqGlob/clientState.nut")
let stdlog = require("%enlSqGlob/library_logs.nut")
let logPSC = stdlog.with_prefix("[profileServerClient]")
let { json_to_string } = require("json")
let userInfo = require("%enlSqGlob/userInfo.nut")

let function checkAndLogError(id, action, cb, result) {
  if ("error" in result) {
    local err = result.error
    if (typeof err == "table") {
      if ("message" in err) {
        if ("code" in err)
          err = $"{err.message} (code: {err.code})"
        else
          err = err.message
      }
    }
    if (typeof err != "string")
      err = $"(full answer dump) {json_to_string(result)}"
    stdlog.log($"[profileServerClient] request {id}: {action} returned error: {err}")
  } else {
    logPSC($"request {id}: {action} completed without error")
  }
  cb?(result, result?.id ?? id)
}


local function doRequest(action, params, args, id, cb, token = null) {
  token = token ?? userInfo.value?.token
  if (!token) {
    logPSC($"Skip action {action}, no token")
    cb?({ error = "No token" }, id)
    return
  }

  let actionEx = $"das.{action}"
  let reqData = {
    method = actionEx
    id = id
    jsonrpc = "2.0"
  }

  if (params != null)
    reqData["params"] <- params

  let request = args.__merge({
    headers = {
      token = token
      appid = appId.value
    }
    action = actionEx
    data = reqData
  })

  logPSC($"Sending request {id}, method: {action}")
  profile_server.request(request, @(result)
    error_response_converter(@(r) checkAndLogError(id, action, cb, r), result))
}


return {
  doRequest
}
