from "%enlSqGlob/ui_library.nut" import *

let psn = require("%sonyLib/webApi.nut")
if (psn.getPreferredVersion() == 2)
  return require("%enlist/ps4/sessionManager.nut")

let state = require("psn_state.nut")

let SESSION_MAX_USERS = 4
let SESSION_TYPE = "owner-migration"
let SESSION_PRIVACY = "private"
let SESSION_IMAGE = "ui/ps4_session.jpg"
let SESSION_NAME = "Cuisine Royale"
let SESSION_PLATFORMS = ["PS4"]
let SESSION_INDEX = 0

local currentSessionId = null

let function createSessionDesc() {
  let desc = {
    availablePlatforms = SESSION_PLATFORMS
    sessionMaxUser = SESSION_MAX_USERS
    sessionType = SESSION_TYPE
    sessionPrivacy = SESSION_PRIVACY
    sessionName = SESSION_NAME
    // TODO:
    // localizedSessionNames
    // localizedSessionStatus
    index = SESSION_INDEX
    sessionLockFlag = false
  }
  return desc
}

let function create_session(squadId, on_success) {
  let session = createSessionDesc()
  let params = {
    squad_id = squadId
  }
  psn.send(psn.session.create(session, SESSION_IMAGE, params), function(resp, err) {
    if (err) {
      log("[PSNSESSION] Failed to create PSN session")
      return
    }
    currentSessionId = resp.sessionId
    on_success()
  })
}

let function update_session_data(new_id) {
  let params = {
    squad_id = new_id
  }
  psn.send(psn.session.change(currentSessionId, params), function(_resp, err) {
    if (err) {
      log("[PSNSESSION] Failed to update PSN session data")
      return
    }
  })
}

let function invite(uid, on_success) {
  if (currentSessionId == null) {
    log("[PSNSESSION] Session is not created!")
    return
  }

  let uid2psn = state.uid2psn.value
  let struid = uid.tostring()
  if (!(struid in uid2psn)) {
    log("[PSNSESSION] Invalid user id {uid} - unknown PSN friend. Mapping: {uid2psn}".subst({uid = uid, uid2psn = uid2psn}))
    return
  }

  let account_id = uid2psn[struid]
  psn.send(psn.session.invite(currentSessionId, account_id), function(_resp, err) {
    if (err) {
      log("[PSNSESSION] Failed to send PSN invite")
      return
    }
    on_success()
  })
}

let function use_invitation(id) {
  psn.send(psn.invitation.use(id), function(_resp, err) {
    if (err)
      log("[PSNSESSION] Failed to use session invitation {inv_id}".subst({inv_id = id}))
  })
}

let function join(session_id, invitation_id, on_success) {
  psn.send(psn.session.data(session_id), function(resp, err) {
    if (err) {
      log("[PSNSESSION] Failed to read session data")
      return
    }

    let squad_id = resp.squad_id

    if (invitation_id.len() > 0) {
      use_invitation(invitation_id)
    } else {
      psn.send(psn.invitation.list(), function(inv_list, _err) {
        if (inv_list?.invitations) {
          foreach (invitation in inv_list.invitations) {
            use_invitation(invitation.invitationId)
          }
        }
      })
    }

    psn.send(psn.session.join(session_id), function(_resp, err) {
      if (err) {
        log("[PSNSESSION] Failed to join session by invitation")
        return
      }

      currentSessionId = session_id
      on_success(squad_id)
    })
  })
}

let function leave() {
  if (currentSessionId) {
    psn.send(psn.session.leave(currentSessionId), function(_resp, err) {
      if (err) {
        log("[PSNSESSION] Failed to leave session")
      }
      currentSessionId = null
    })
  }
}

return {
  create = create_session
  update_data = update_session_data
  invite = invite
  join = join
  leave = leave
}
