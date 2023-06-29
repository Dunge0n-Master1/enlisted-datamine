from "%enlSqGlob/ui_library.nut" import *

let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let invalidNickName = "????????"
let {request_nick_by_uid_batch} = require("%enlist/netUtils.nut")
let {nestWatched} = require("%dngscripts/globalState.nut")
let contacts = nestWatched("contacts", {})

//better to replace lots of observables with one observable - contactData + function to getOnline

let function updateContact(userIdStr, name=invalidNickName) {
  let uidStr = userIdStr.tostring()
  if (uidStr not in contacts.value) {
    let contact = { userId = uidStr, uid = userIdStr.tointeger(), realnick = name }
    contacts.mutate(@(v) v[uidStr] <- contact)
    return contact
  }
  let contact = contacts.value[uidStr]
  if (name != invalidNickName && name != contact.realnick)
    contact.realnick = name
  contacts.mutate(@(v) v[uidStr] <- contact)
  return contact
}

let isValidContactNick = @(c) c.realnick != invalidNickName

let requestedUids = {}

//contacts - array or table of contacts
let function validateNickNames(contactsContainer, finish_cb = null) {
  let requestContacts = []
  foreach (c in contactsContainer) {
    if (!isValidContactNick(c) && !(c.uid in requestedUids)) {
      requestContacts.append(c)
      requestedUids[c.uid] <- true
    }
  }
  if (!requestContacts.len()) {
    if (finish_cb)
      finish_cb()
    return
  }

  request_nick_by_uid_batch(requestContacts.map(@(c) c.uid),
    function(result) {
      foreach (contact in requestContacts) {
        let { userId, uid } = contact
        let name = result?[userId]
        if (name)
          updateContact(userId, name)
        if (uid in requestedUids)
          delete requestedUids[uid]
      }
      if (finish_cb)
        finish_cb()
    })
}

let nickContactsCache = persist("nickContactsCache", @() {})
let function getContactNick(contact) {
  let uid = contact.uid ?? contact?.uid
  let nick = contact.realnick ?? contact?.realnick ?? invalidNickName

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

let getContact = @(userId) contacts.value?[userId] ?? updateContact(userId)

return {
  contacts
  getContactRealnick = @(userId) getContact(userId).realnick
  getContact
  updateContact
  validateNickNames
  getContactNick
  isValidContactNick
}
