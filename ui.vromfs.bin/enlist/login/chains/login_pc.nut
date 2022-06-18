from "%enlSqGlob/ui_library.nut" import *

let steam = require("steam")
let epic = require("epic")
let wegame  = require("wegame")
let { disableNetwork } = require("%enlSqGlob/login_state.nut")
let { get_arg_value_by_name } = require("dagor.system")
let login_cb = require("%enlist/login/login_cb.nut")
let login_epic_cb = require("%enlist/login/login_cb_epic.nut")
let login_steam_cb = require("%enlist/login/login_cb_steam.nut")
let login_wegame_cb = require("%enlist/login/login_cb_wegame.nut")

let auth_result = require("%enlist/login/stages/auth_result.nut")
let char_stage = require("%enlist/login/stages/char.nut")
let online_settings = require("%enlist/login/stages/online_settings.nut")
let eula = require("%enlist/login/stages/eula.nut")
let matching = require("%enlist/login/stages/matching.nut")
let fake_login = require("%enlist/login/stages/fake.nut")
let dmm_login = require("%enlist/login/stages/dmm.nut")
let go_login = require("%enlist/login/stages/go.nut")
let save_login = require("%enlist/login/stages/save_login_data.nut")
let steam_stages = require("%enlist/login/stages/steam_stages.nut")
let epic_login = require("%enlist/login/stages/epic.nut")
let wegame_login = require("%enlist/login/stages/wegame.nut")

if (disableNetwork) {
  return {
    stages = [fake_login]
    onSuccess = login_cb.onSuccess
    onInterrupt = login_cb.onInterrupt
  }
}

let isDMMLogin = get_arg_value_by_name("dmm_user_id") != null

if (isDMMLogin){
  return {
    stages = [
      dmm_login
      auth_result
      char_stage
      online_settings
      eula
      matching
    ]
    onSuccess = login_cb.onSuccess
    onInterrupt = login_cb.onInterrupt
  }
}

if (epic.is_running()) {
  return {
    stages = [
      epic_login
      auth_result
      char_stage
      online_settings
      eula
      matching
    ]
    onSuccess = login_epic_cb.onSuccess
    onInterrupt = login_epic_cb.onInterrupt
  }
}

if (steam.is_running()) {
  return {
    stages = [].extend(steam_stages).append(
      auth_result
      char_stage
      online_settings
      eula
      matching
    )
    onSuccess = login_steam_cb.onSuccess
    onInterrupt = login_steam_cb.onInterrupt
  }
}


if (wegame.is_running()) {
  return {
    stages = [
      wegame_login
      auth_result
      char_stage
      online_settings
      eula
      matching
    ]
    onSuccess = login_wegame_cb.onSuccess
    onInterrupt = login_wegame_cb.onInterrupt
  }
}

return {
  stages = [
    go_login
    auth_result
    char_stage
    online_settings
    eula
    matching
    save_login
  ]
  onSuccess = login_cb.onSuccess
  onInterrupt = login_cb.onInterrupt
}

