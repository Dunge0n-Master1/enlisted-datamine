from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let contactsGameId = get_setting_by_blk_path("contactsGameId")

let {char_request} = require("%enlSqGlob/charClient.nut")
let sysinfo = require_optional("sysinfo")
let {version, build_number} = require("%dngscripts/appInfo.nut")
let {tostring_r} = require("%sqstd/string.nut")

let {dgs_get_settings} = require("dagor.system")

let function char_login(auth_token, user_cb) {
  let request = {
    game =  contactsGameId
  }

  if (sysinfo) {
    local si = sysinfo.get_user_system_info()
    si.game_version <- version.value
    si.game_build <- build_number.value
    si.graphicsQuality <- (dgs_get_settings()?.graphics?.preset ?? "medium")
    request["sysinfo"] <- si
  }

  char_request?("cln_cs_login", request,
    function(result) {
      if ( typeof result != "table" ) {
        log("ERROR: invalid cln_cs_login result\n")
        user_cb({error = "INTERNAL_SERVER_ERROR"})
        return
      }

      if ("result" in result)
        result = result.result

      if ( "error" in result ) {
        log("ERROR: cln_cs_login result: {0}".subst(tostring_r(result)))
        user_cb(result)
        return
      }

      log("char_login performed for user")
      user_cb({
        penaltiesJwt = result?.penaltiesJwt
        clientPermJwt = result?.clientPermJwt
        dedicatedPermJwt = result?.dedicatedPermJwt
        chard_token = result.chardToken
        externalid = result?.externalid ?? []
      })

    },
    auth_token)
}

return {
  id = "char"
  action = function(login_state, cb) {
    assert(contactsGameId!=null, "contactsGameId is not set in settings.blk!")
    char_login(login_state.stageResult.auth_result.token, cb)
  }
}
