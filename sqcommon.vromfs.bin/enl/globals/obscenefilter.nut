from "%enlSqGlob/ui_library.nut" import *

let http = require("dagor.http")
let json = require("json")
let { get_setting_by_blk_path } = require("settings")
let { encode_uri_component } = require("app")
let { logerr } = require("dagor.debug")
let { md5 } = require("hash")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { get_kongzhong_accountid } = require("auth")
let { send_counter = null } = require_optional("statsd")
let wegame = require("wegame")

let OBSCENE_FILTER_URL = get_setting_by_blk_path("obsceneFilterUrl") ?? ""

let signKey = get_setting_by_blk_path("signKey") ?? ""

let hasObsceneFilter = OBSCENE_FILTER_URL != ""

let function processObsceneFilter(response, filterCb) {
  let { status = -1, http_code = 0, body = null } = response
  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter?("obscene_filter_receive_errors", 1, { http_code })
    filterCb(null)
    return
  }
  local result
  try {
    result = json.parse(body?.as_string())?.data.replace_string
  } catch(e) {
    logerr(e)
  }
  if (result == null) {
    logerr("ObsceneFilter result is null")
    filterCb(null)
    return
  }
  filterCb(result)
}

let function requestObsceneFilter(phraseToFilter, filterCb){
  if (!hasObsceneFilter){
    filterCb(phraseToFilter)
    return
  }

  if (wegame.is_running()) {
    filterCb(wegame.filter_words(phraseToFilter))
    return
  }

  local words = phraseToFilter
  local replace_sensitive = 0
  local gameKey = "cj"
  local userId = get_kongzhong_accountid()
  local playerName = userInfo.value.name
  local playerId = userInfo.value.userId
  local areaId = 1
  local sign = md5($"words{words}replace_sensitive{replace_sensitive}userId{userId}playerName{playerName}playerId{playerId}areaId{areaId}signKey{signKey}")
  local request = {
    method = "GET"
    url = OBSCENE_FILTER_URL.subst({ words = encode_uri_component(words), replace_sensitive,
      gameKey, userId, playerName = encode_uri_component(playerName), playerId, areaId, sign })
  }
  request.callback <- @(response) processObsceneFilter(response, filterCb)
  http.request(request)
}

return requestObsceneFilter
