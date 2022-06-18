import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *
let charactions = require("charactions")
let {get_setting_by_blk_path} = require("settings")
let contactsGameId = get_setting_by_blk_path("contactsGameId")

let dedicated = require_optional("dedicated")
if (dedicated == null)
  return

let char = require("char")
let {CmdGetUserstats} = require("dasevents")

let {INVALID_USER_ID} = require("matching.errors")


let function onCmdGetUserStats(eid, comp) {
  if (comp.userid == INVALID_USER_ID)
    return

  let request = {
    headers = {
      userid = comp.userid
      game = contactsGameId
      appid = comp.appId
    },
    action = "hst_get_chat_data"
  }


  log("request hst_get_chat_data", comp.userid, comp.appId)

  char.request(request, function(result) {
    if (result) {
      let bestPenalty = result?.bestPenalty ?? ""

      let errorMsg = result?.error
      if (errorMsg)
        log("hst_get_chat_data of", comp.userid, "returns error", errorMsg)

      log("bestPenalty of", comp.userid, "is", bestPenalty)

      ecs.obsolete_dbg_set_comp_val(eid, "ban_status", bestPenalty)
    }
    else {
      ecs.obsolete_dbg_set_comp_val(eid, "ban_status", "")
      log("hst_get_chat_data return NO result")
    }
  })
}



ecs.register_es("contacts_es", {
    [CmdGetUserstats] = onCmdGetUserStats,
  },
  {
    comps_rw = [
      ["ban_status", ecs.TYPE_STRING]
    ]
    comps_ro = [
      ["userid", ecs.TYPE_UINT64],
      ["appId", ecs.TYPE_INT]
    ]
  },
  {tags = "server"}
)


let function CmdSendComplaint(evt, _eid, comp) {

  if (comp.userid == INVALID_USER_ID)
    return

  let offender_userid = evt[0]
  let category = evt[1]
  let user_comment = evt[2]
  let details_json = evt[3]
  let chat_log = evt[4]
  let lang = evt[5]


  log("CmdSendComplaint", comp.userid, comp.appId, offender_userid,
        category, user_comment, details_json, chat_log, lang)

  let matchingModeInfo = dedicated.get_matching_mode_info()
  let sessionId = matchingModeInfo?.sessionId ?? 0

  let request = {
    headers = {
      userid = comp.userid,
      appid = comp.appId,
    },
    data = {
      offender_userid = offender_userid,
      room_id = sessionId,
      category = category,
      lang = lang,
      user_comment = user_comment,
      chat_log = chat_log,
      details_json = details_json
    },
    action = "hst_complaint"
  }


  char.request(request, function(result) {
    if (result) {

      let errorMsg = result?.result?.error
      if (errorMsg)
        log("hst_complaint for", comp.userid, "returns error", errorMsg)
    }
    else {
      log("hst_complaint return NO result")
    }
  })
}


ecs.register_es("complaints_es", {
  [charactions.CmdSendComplaint] = CmdSendComplaint }, {
    comps_ro = [ ["userid", ecs.TYPE_UINT64], ["appId", ecs.TYPE_INT] ]})

