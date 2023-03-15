from "%enlSqGlob/ui_library.nut" import *

let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let invalidNickName = "????????"
let {request_nick_by_uid_batch} = require("%enlist/netUtils.nut")
let {ndbTryRead, ndbWrite} = require("nestdb")

let function mkGlobalWatched(userIdStr, defVal){
  let key = ["allContacts",userIdStr]
  local container = ndbTryRead(key)
  if (container==null) {
    ndbWrite(key, defVal)
    container = ndbTryRead(key)
  }
  let watch = Watched(container)
  watch.subscribe(@(v) ndbWrite(key, v))
  return watch
}

let contacts = {}
//better to replace lots of observables with one observable - contactData + function to getOnline

let function loadContact(userIdStr, name=invalidNickName) {
  return mkGlobalWatched(userIdStr,
    { userId = userIdStr.tostring(), uid = userIdStr.tointeger(), realnick = name })
}

let isValidContactNick = @(c) c.value.realnick != invalidNickName

local function Contact(userIdStr, name=null) {
  assert(type(userIdStr)==type(""), "Contact can be created only by string user id")
  name = name ?? invalidNickName
  let c = contacts?[userIdStr]
  if (c == null)
    contacts[userIdStr] <- loadContact(userIdStr, name) //Create new
  else if (name != invalidNickName && name != c.value.realnick)
    contacts[userIdStr].mutate(@(v) v.realnick = name) //Update existed

  return contacts[userIdStr]
}

let requestedUids = {}

//contacts - array or table of contacts
let function validateNickNames(contactsContainer, finish_cb = null) {
  let requestContacts = []
  foreach (c in contactsContainer) {
    if (!isValidContactNick(c) && !(c.value.uid in requestedUids)) {
      requestContacts.append(c)
      requestedUids[c.value.uid] <- true
    }
  }
  if (!requestContacts.len()) {
    if (finish_cb)
      finish_cb()
    return
  }

  request_nick_by_uid_batch(requestContacts.map(@(c) c.value.uid),
    function(result) {
      foreach (contact in requestContacts) {
        let { userId, uid } = contact.value
        let name = result?[userId]
        if (name)
          contact.mutate(@(v) v.realnick = name)
        if (uid in requestedUids)
          delete requestedUids[uid]
      }
      if (finish_cb)
        finish_cb()
    })
}

let nickContactsCache = persist("nickContactsCache", @() {})
let function getContactNick(contact) {
  let uid = contact?.value.uid ?? contact?.uid
  let nick = contact?.value.realnick ?? contact?.realnick ?? invalidNickName

  if (uid == null)
    remap_others(nick)

  if (uid in nickContactsCache)
    return nickContactsCache[uid]

  if (nick != invalidNickName) {
    nickContactsCache[uid] <- remap_others(nick)
    return nickContactsCache[uid]
  }
  return invalidNickName
}

return {
  Contact
  validateNickNames
  getContactNick
  isValidContactNick
}
