from "%enlSqGlob/ui_library.nut" import *

let json = require("json")
let http = require("dagor.http")
let ps4 = require("ps4")
let {logerr} = require("dagor.debug")
let {get_circuit_conf} = require("app")
let statsd = require("statsd")
let eventbus = require("eventbus")

let AUTH_FRIENDS_URL = get_circuit_conf()?.psnFriendsUrl
let AUTH_DATA_SUB_ID = "ps4.auth_data_friends"

// for make unqie event id, this variable will be reseted on script reload, but that
// no problem because all request will be aborted on script reload
local requestNum = 0

let function request_auth_contacts(game, include_unknown, callback) {
  if (!AUTH_FRIENDS_URL) {
    logerr("Invalid AUTH_FRIENDS_URL. To work with PS4 circuit needs to have psnFriendsUrl configured in network.blk")
    callback([])
    return
  }

  // make unqie event id for prevent duplicate auth token
  let eventId = $"{AUTH_DATA_SUB_ID}.{requestNum}"
  log($"[AuthFriends]: Send request with id: {eventId}")
  requestNum++
  let function on_auth_data(auth_data) {
    if (!auth_data?.error) {
      let fmt_args = {
        code = auth_data.auth_code
        issuer = auth_data.issuer
        lang = auth_data.lang
        game = game
        unknown = include_unknown ? 1 : 0
      }
      let post_data = "code={code}&issuer={issuer}&lang={lang}&game={game}&unknown={unknown}".subst(fmt_args)
      log($"[AuthFriends]: eventId: {eventId} : POST data: {post_data}")
      let req_params = {
        method = "POST"
        url = AUTH_FRIENDS_URL
        data = post_data
        callback = function(response) {
          if (response.status != http.SUCCESS || !response?.body ||
              response.http_code < 200 || response.http_code >= 300) {
            statsd.send_counter("psn_auth_friends_request_error", 1, {http_code = response.http_code})
            log($"[AuthFriends]: request failed ({response.http_code}), body {response?.body}")
            return
          }
          let response_body = response.body.as_string()
          let response_log_max_length = 1024 // First 1KB
          let response_log_length = response_body.len() > response_log_max_length ? response_log_max_length : response_body.len()
          log("[AuthFriends]: \n\n", response_body.slice(0, response_log_length))
          let parsed = json.parse(response_body)
          if (parsed?.status != "OK") {
            logerr("get_auth_friends failed")
            return
          }
          callback({ friends = parsed?.friends,
                     blocklist = parsed?.blocklist} )
        }
      }
      http.request(req_params)
    }
  }
  eventbus.subscribe_onehit(eventId, on_auth_data)
  ps4.get_auth_data_async(eventId)
}

return {
  request_auth_contacts
}
