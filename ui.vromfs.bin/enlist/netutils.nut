from "%enlSqGlob/ui_library.nut" import *

let { matchingCall } = require("matchingClient.nut")
let {error_response_converter} = require("%enlSqGlob/netErrorConverter.nut")

let function request_nick_by_uid_batch(user_ids, cb) {
  matchingCall("mproxy.nick_server_request",
                        function(response) {
                          if (response.error != 0) {
                            cb(null)
                            return
                          }
                          let result = response?.result
                          if (typeof result != "table") {
                            cb(null)
                            return
                          }
                          cb(result)
                        },
                        { ids = user_ids })
}

let request_nick_by_uid = @(uid, cb) request_nick_by_uid_batch([uid],
                                                        @(result) result == null ? cb(result) : cb(result?[uid.tostring()]))


let function request_full_userinfo(user_id, cb) {
  matchingCall("mproxy.get_user_info", cb, { userId = user_id})
}


console_register_command(
  @(user_id) request_nick_by_uid(user_id, @(nick) console_print(nick))
  "netutils.request_nick_by_uid")

console_register_command(
  @(user_id) request_full_userinfo(user_id, @(info) console_print(info))
  "netutils.request_full_userinfo")

return {
  request_nick_by_uid = request_nick_by_uid
  request_nick_by_uid_batch = request_nick_by_uid_batch
  request_full_userinfo = request_full_userinfo
  error_response_converter = error_response_converter
}
