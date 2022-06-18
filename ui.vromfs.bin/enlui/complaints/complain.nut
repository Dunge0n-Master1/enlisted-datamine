from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let {char_request=null} = require("%enlSqGlob/charClient.nut")

let complainTypeToId = {
  Cheating = 1
  Exploiting = 2
  OffensiveProfile = 3
  VerbalAbuse = 4
  Scamming = 5
  Spamming = 6
  Other = 7
}

let submitComplain = kwarg(function(userId, sessionId, complainType, message) {
  let request = {
    offender_userid = userId,
    room_id = sessionId.tostring(),
    category = "EAC",
    user_comment = message,
    details_json = "{\"complainId\":\"{0}\"}".subst(complainTypeToId[complainType])
  }

  char_request?(
    "cln_complaint",
    request,
    function(response) {
      log($"[COMPLAIN] on {userId}, type = {complainType}, in session {sessionId}, message = {message}")
      log("[COMPLAIN] result: ", response)
    }
  )
})

eventbus.subscribe("penitentiary.complain", @(data) submitComplain(data))