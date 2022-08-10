from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let lowLevelClient = require("char")
let { INVALID_USER_ID } = require("matching.errors")
//if (lowLevelClient == null)
//  return null

let {get_app_id} = require("app")
let logC = require("%enlSqGlob/library_logs.nut").with_prefix("[CHAR CLIENT] ")

local function char_request(action, data, callback, auth_token = null) {
  auth_token = auth_token ?? userInfo.value?.token
  assert(auth_token != null, "No auth token provided for char request")
  let request = {
    headers = {token = auth_token, appid = get_app_id()},
    action = action
  }

  if (data) {
    request["data"] <- data
  }

  lowLevelClient.request(request, function(result) {
    let errorStr = result?.error ?? result?.result?.error
    if (errorStr != null) {
      let colonPos = errorStr.indexof(":")
      let errorName = colonPos != null ? errorStr.slice(0, colonPos) : errorStr
      let errorDetails = colonPos != null ? errorStr.slice(colonPos + 1) : null
      callback( { result = {
        success = false,
        error = errorName,
        errorDetails = errorDetails
      }})
    }
    else {
      callback(result)
    }
  })
}

let function char_host_request(action, userid, data, callback) {
  let request = {
    headers = {userid },
    action = action
  }

  if (data) {
    request["data"] <- data
  }

  lowLevelClient.request(request, callback)
}

let function perform_contact_action(action, request, params) {
  let onSuccessCb = params?.success
  local onFailureCb = params?.failure

  logC("perform_contact_action", request)

  char_request(action, request, function(result) {
    logC("char_request", result)

    let subResult = result?.result
    if (subResult != null)
      result = subResult

    // Failure only if its explicitly defined in result
    if ("success" in result && !result.success) {
      if (typeof onFailureCb == "function") {
        onFailureCb(result?.error)
      }
    } else {
      if (typeof onSuccessCb == "function") {
        onSuccessCb()
      }
      logC("Ok")
    }
  })
}

let function perform_single_contact_action(request, params) {
  perform_contact_action("cln_change_single_contact_json", request, params)
}

let function contacts_add(id, params = {}) {
  let request = {
    friend = {
      add = [id]
    }
  }

  perform_single_contact_action(request, params)
}


let function contacts_remove(id, params = {}) {
  let request = {
    friend = {
      remove = [id]
    }
  }
  perform_single_contact_action(request, params)
}

let function perform_contacts_for_requestor(action, apprUid, group, params = {}, requestAddon = {}) {
  if (apprUid == INVALID_USER_ID) {
    logC($"try perform action {action} for invalid contact, group {group}")
    return
  }

  let request = {
    apprUid = apprUid
    groupName = group
  }
  perform_contact_action(action, request.__merge(requestAddon), params)
}

let function perform_contacts_for_approver(action, requestorUid, group, params = {}, requestAddon = {}) {
  if (requestorUid == INVALID_USER_ID) {
    logC($"try perform action {action} for invalid contact, group {group}")
    return
  }

  let request = {
    requestorUid = requestorUid
    groupName = group
  }
  perform_contact_action(action, request.__merge(requestAddon), params)
}

let charClient = {
  low_level_client = lowLevelClient
  char_request = char_request
  char_host_request = char_host_request
  perform_contacts_for_requestor = perform_contacts_for_requestor
  perform_contacts_for_approver = perform_contacts_for_approver
  contacts_add = contacts_add
  contacts_remove = contacts_remove
  perform_single_contact_action = perform_single_contact_action
  perform_contact_action = perform_contact_action

  function contacts_request_for_contact(id, group, params = {}) {
    perform_contacts_for_requestor("cln_request_for_contact", id, group, params)
  }

  function contacts_cancel_request(id, group, params = {}) {
    perform_contacts_for_requestor("cln_cancel_request_for_contact", id, group, params)
  }

  function contacts_approve_request(id, group, params = {}) {
    perform_contacts_for_approver("cln_approve_request_for_contact", id, group, params)
  }

  function contacts_break_approval_request(id, group, params = {}) {
    perform_contacts_for_approver("cln_break_approval_contact", id, group, params)
  }

  function contacts_reject_request(id, group, params = {}) {
    perform_contacts_for_approver("cln_reject_request_for_contact", id, group, params, {silent="on"})
  }

  function contacts_add_to_blacklist(id, group, params = {}) {
    perform_contacts_for_approver("cln_blacklist_request_for_contact", id, group, params)
  }

  function contacts_remove_from_blacklist(id, group, params = {}) {
    perform_contacts_for_approver("cln_remove_from_blacklist_for_contact", id, group, params)
  }

}

// console commands
let function contacts_get() {
  char_request("cln_get_contact_lists_ext", null, function(result) {
    logC("cln_get_contact_lists_ext", result)
  })
}

let function leaderboard_get() {
  let request = {
    category = "relativePlayerPlace",
    valueType = "value_total",
    gameMode = "game_test"
    count = 10,
    start = 0
  }

  char_request("cln_get_leaderboard_json", request, function(result) {
    logC("cln_get_leaderboard_json", result)
  })
}

let function leaderboard_host_push() {
  let request = {
    nick = "__",
    data = {
      arcade = {
          each_player_session = 1,
          each_player_victories = 1,
          finalSessionCounter = 1,
          flyouts = 1,
          ground_spawn = 1,
          position = 1,
          relativePosition = 1000,
          time_pvp_played = 41
      }
    }
  }

  char_host_request("hst_leaderboard_player_set", 666, request, function(result) {
    if (result) {
      logC("hst_leaderboard_player_set result", result)
    }
    else {
      logC("Ok")
    }
  })
}


let function contacts_search(nick) {
  let request = {
    nick = nick
    max_count = 10
    ignore_case = true
  }

  char_request("cln_find_users_by_nick_prefix_json", request, function(result) {
    logC("cln_find_users_by_nick_prefix_json result", result)
  })
}


console_register_command(contacts_get, "char.contacts_get")
console_register_command(contacts_add, "char.contacts_add")
console_register_command(contacts_search, "char.contacts_search")
console_register_command(leaderboard_get, "char.leaderboard_get")
console_register_command(leaderboard_host_push, "char.leaderboard_host_push")

return charClient
