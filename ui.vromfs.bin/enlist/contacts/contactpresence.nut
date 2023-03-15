from "%enlSqGlob/ui_library.nut" import *

let { ndbTryRead, ndbWrite, ndbDelete } = require("nestdb")

const PRESENCES_ID = "presences"
const SQUAD_STATUS_ID = "squad_status"

let presences = Watched(ndbTryRead(PRESENCES_ID) ?? {})
let squadStatus = Watched(ndbTryRead(SQUAD_STATUS_ID) ?? {})

let calcStatus = @(presence) presence?.unknown ? null : presence?.online
let onlineStatusBase = Watched(presences.value.map(calcStatus))

let onlineStatus = Computed(@() onlineStatusBase.value.__merge(squadStatus.value))

let mkUpdatePresences = @(watch, dbId) function(newPresences) {
  if (newPresences.len() > 10) { //faster way when many presences received
    //merge and filter are much faster when receive a lot of friends then foreach with delete
    watch(watch.value.__merge(newPresences).filter(@(p) p != null))
    ndbWrite(dbId, watch.value)
    return
  }

  foreach (userId, p in newPresences) //faster way when you have 1000+ presences and updated only few of them
    if (p == null)
      ndbDelete([dbId, userId])
    else
      ndbWrite([dbId, userId], p)

  watch.mutate(function(v) {
    v.__update(newPresences)
    //it much faster than filter when update few presences of 2000 friends
    foreach (userId, presence in newPresences)
      if (presence == null)
        delete v[userId]
  })
}

let updatePresencesImpl = mkUpdatePresences(presences, PRESENCES_ID)
let updateSquadPresences = mkUpdatePresences(squadStatus, SQUAD_STATUS_ID)

let function updatePresences(newPresences) {
  updatePresencesImpl(newPresences)
  onlineStatusBase.mutate(@(v) v.__update(newPresences.map(calcStatus)))
}

let isContactOnline = function(userId, onlineStatusVal) {
  let uid = type(userId) =="integer" ? userId.tostring() : userId
  return onlineStatusVal?[uid] == true
}

let mkContactOnlineStatus = @(userId) Computed(@() onlineStatus.value?[userId])
let mkContactIsOnline = @(userId) Computed(@() isContactOnline(userId, onlineStatus.value))

return {
  presences
  onlineStatus
  updatePresences
  updateSquadPresences

  isContactOnline
  mkContactOnlineStatus
  mkContactIsOnline
}