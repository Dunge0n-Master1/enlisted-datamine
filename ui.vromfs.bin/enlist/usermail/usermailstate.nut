from "%enlSqGlob/ui_library.nut" import *

let { usermail_list, usermail_take_reward } = require("%enlist/meta/clientApi.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let matching_api = require("matching.api")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let eventbus = require("eventbus")
let { sound_play } = require("sound")

const MAX_AMOUNT = 20
let MAX_LIFETIME = 30 * 24 * 60 * 60
let soundNewMail = "ui/enlist/notification"

let letters = mkWatched(persist, "letters", [])
let lastTime = mkWatched(persist, "lastTime", serverTime.value - MAX_LIFETIME)

let isRequest = Watched(false)
let isUsermailWndOpend = mkWatched(persist, "isUsermailWndOpend", false)
let selectedLetterIdx = mkWatched(persist, "selectedLetterIdx", -1)
let hasUnseenLetters = mkWatched(persist, "hasUnseenLetters", false)

let function markUnseenLetters(){
  if (isRequest.value)
    return
  hasUnseenLetters(true)
  if (!isInBattleState.value)
    sound_play(soundNewMail)
}

matching_api.listen_notify("newmail")

eventbus.subscribe("matching.notify_new_mail", @(...) markUnseenLetters())

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

let function requestLetters() {
  if (isRequest.value)
    return

  isRequest(true)
  let ts = lastTime.value
  lastTime(serverTime.value)
  usermail_list(ts, MAX_AMOUNT, onLettersUpdate)
}

let function takeLetterReward(guid) {
  if (isRequest.value)
    return

  isRequest(true)
  usermail_take_reward(guid, onLettersUpdate)
}


console_register_command(requestLetters, "usermail.request")
console_register_command(takeLetterReward, "usermail.getReward")
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
