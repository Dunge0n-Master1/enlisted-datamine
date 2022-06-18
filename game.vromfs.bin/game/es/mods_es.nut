import "%dngscripts/ecs.nut" as ecs
let dedicated = require_optional("dedicated")

if (dedicated == null)
  return

let http = require("dagor.http")
let logGM = require("%sqstd/log.nut")().with_prefix("[CustomGameMod] ")
let { EventTeamRoundResult } = require("dasevents")
let { get_arg_value_by_name } = require("dagor.system")
let { get_matching_invite_data } = require("app")

let isResultSend = persist("isResultSend", @() { value = false })

ecs.register_es("mods_send_postback_es",
  {
    [EventTeamRoundResult] = function (_evt, _eid, _comp) {
      if (isResultSend.value)
        return
      isResultSend.value = true

      let apiKey = get_arg_value_by_name("sandbox_api_key") ?? ""
      let modId = get_matching_invite_data()?.mode_info.modId ?? ""
      logGM("modId", modId)
      if (modId == "" || apiKey == "") {
        logGM("Can't send mod postback empty modId or apiKey")
        return
      }

      http.request({
        method = "POST"
        url = "https://enlisted-sandbox.gaijin.net/api/post/launched/"
        data = $"apiKey={apiKey}&id={modId}"
        callback = @(response) logGM("Mod postback response", response?.body?.as_string())
      })
    }
  },
  { },
  { tags="server" })
