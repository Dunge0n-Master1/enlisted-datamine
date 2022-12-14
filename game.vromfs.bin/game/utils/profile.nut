let rand = require("%sqstd/rand.nut")()
let isDedicated = require_optional("dedicated") != null
let {put_to_mq_raw=null, mq_gen_transactid=null} = require_optional("message_queue")
let {get_arg_value_by_name} = require("dagor.system")
let profile_server = require_optional("profile_server")
let stdlog = require("%enlSqGlob/library_logs.nut")
let logPSC = stdlog.with_prefix("[profileServerClient]")
let json = require("json")
let { get_app_id } = require("app")
let {logerr} = require("dagor.debug")

let function error_response_converter(cb, result) {
  if ("error" in result) {
    cb(result)
    return
  }

  let isSuccess = result?.response?.success ?? true
  if (!isSuccess) {
    cb( { success = false,
          error = result?.response?.error ?? "unknown error" })
    return
  }
  cb(result)
}

let lastRequest = persist("lastRequest", @() { id = rand.rint() })

let tubeName = get_arg_value_by_name("profile_tube") ?? ""
if (isDedicated)
  print($"profile_tube: {tubeName}")


let isEnabled = @() put_to_mq_raw != null && isDedicated

let function checkAndLogError(id, action, result) {
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
      err = $"(full answer dump) {json.to_string(result)}"
    logerr($"[profileServerClient] request {id}: {action} returned error: {err}")
  } else {
    logPSC($"request {id}: {action} completed without error")
  }
}


local function sendJob(action, appid, userid, data, id = null) {
  if (!isEnabled() || appid < 0) {
    logerr($"Refusing to send job {action} to profile")
    return
  }

  id = id ?? (++lastRequest.id).tostring()

  let actionEx = $"das.{action}"

  let reqData = {
    method = actionEx
    id = id
    jsonrpc = "2.0"
  }

  if (data != null)
    reqData["params"] <- data

  if (tubeName != "") {
    logPSC($"Sending request {id}, method: {actionEx} via message_queue")
    let transactid = mq_gen_transactid()
    put_to_mq_raw(tubeName, {
        action = actionEx,
        headers = {
          appid = appid
          userid = userid
          transactid = transactid
        },
        body = reqData
      })
  } else {
    logPSC($"Sending request {id}, method: {actionEx} via http")
    profile_server.request({
        action = actionEx,
        headers = {
          appid = get_app_id()
          userid = userid
        },
        data = reqData
      },
      @(result) error_response_converter(
        @(r) checkAndLogError(id, actionEx, r),
        result))
  }
}

return {
  isEnabled
  sendJob
}
