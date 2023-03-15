from "%enlSqGlob/ui_library.nut" import *

let { usermail_list, usermail_take_reward, usermail_reset_reward
} = require("%enlist/meta/clientApi.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let eventbus = require("eventbus")
let { sound_play } = require("sound")
let { subscribe } = require("%enlSqGlob/notifications/matchingNotifications.nut")

const MAX_AMOUNT = 20
let MAX_LIFETIME = 30 * 24 * 60 * 60
const soundNewMail = "ui/enlist/notification"

let letters = mkWatched(persist, "letters", [])
let lastTime = mkWatched(persist, "lastTime", 0)

let isRequest = Watched(false)
let isUsermailWndOpend = mkWatched(persist, "isUsermailWndOpend", false)
let selectedLetterIdx = mkWatched(persist, "selectedLetterIdx", -1)
let hasUnseenLetters = mkWatched(persist, "hasUnseenLetters", false)

serverTime.subscribe(function(ts) {
  if (ts <= 0)
    return
  serverTime.unsubscribe(callee())
  lastTime(ts - MAX_LIFETIME)
})

let function markUnseenLetters(){
  if (isRequest.value)
    return
  hasUnseenLetters(true)
  if (!isInBattleState.value)
    sound_play(soundNewMail)
}

eventbus.subscribe("matching.notify_new_mail", @(...) markUnseenLetters())
subscribe("profile", @(ev) ev?.func == "newmail" ? markUnseenLetters() : null)

let function closeUsermailWindow(){
  isUsermailWndOpend(false)
  hasUnseenLetters(false)
  selectedLetterIdx(-1)
}

let function onLettersUpdate(result) {
  isRequest(false)
  let { usermail = [] } = result
  if (usermail.len() == 0)
    return

  letters.mutate(function(list) {
    foreach (letter in usermail) {
      let idx = list.findindex(@(prev) prev.guid == letter.guid)
      if (idx == null)
        list.append(letter)
      else
        list[idx] = letter
    }
    list.sort(@(a,b) b.cTime <=> a.cTime)
  })
}

let function requestLetters(forceUpdate = false) {
  if (isRequest.value)
    return

  isRequest(true)
  let ts = lastTime.value
  lastTime(serverTime.value)
  usermail_list(forceUpdate ? 0 : ts, MAX_AMOUNT, onLettersUpdate)
}

let function takeLetterReward(guid) {
  if (isRequest.value)
    return

  isRequest(true)
  usermail_take_reward(guid, onLettersUpdate)
}


console_register_command(@() requestLetters(true), "usermail.request")
console_register_command(takeLetterReward, "usermail.getReward")
console_register_command(@() usermail_reset_reward(onLettersUpdate), "usermail.resetReward")
console_register_command(
  function(reward){
    let letter = {
      guid = serverTime.value
      text = $"New mail received, mail in mailbox № {letters.value.len() + 1}"
      cTime = serverTime.value
    }
    if (reward != null && reward.tointeger() > 0)
      letter.__update({
        reward
        endTime = serverTime.value + 1000
      })
    letters.mutate(@(v) v.insert(0, letter))
    eventbus.send("matching.notify_new_mail", null)
  },
  "usermail.newMail"
)

return {
  letters
  requestLetters
  takeLetterReward
  isRequest
  isUsermailWndOpend
  selectedLetterIdx
  closeUsermailWindow
  hasUnseenLetters
}
