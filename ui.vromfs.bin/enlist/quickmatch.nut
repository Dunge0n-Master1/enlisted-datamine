from "%enlSqGlob/ui_library.nut" import *

let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let checkbox = require("%ui/components/checkbox.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let {
  isInQueue, leaveQueue, joinQueue, timeInQueue, curQueueParam
} = require("%enlist/quickMatchQueue.nut")
let { curUnfinishedBattleTutorial } = require("tutorial/battleTutorial.nut")
let { isInSquad, isSquadLeader } = require("%enlist/squad/squadState.nut")
let { curArmiesList, armies } = require("%enlist/meta/profile.nut")
let { mteam } = require("%enlist/soldiers/model/state.nut")
let localSettings = require("%enlist/options/localSettings.nut")("quickMatch/")
let { currentGameMode, eventGameModes } = require("gameModes/gameModeState.nut")
let saveCrossnetworkPlayValue = require("%enlist/options/crossnetwork_save.nut")
let { crossnetworkPlay, CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { is_xbox } = require("%dngscripts/platform.nut")
let { selEvent, isEventModesOpened } = require("%enlist/gameModes/eventModesState.nut")
let {nestWatched} = require("%dngscripts/globalState.nut")

let lastQueue = nestWatched("lastQueue", null)

let isInEventGM = Computed(@() isEventModesOpened.value
  || (curQueueParam.value != null
    && eventGameModes.value.findvalue(@(v) v.queue.queueId == curQueueParam.value?.queueId)))

let matchRandomTeamCommon = localSettings(true, "matchRandomTeam")
let matchRandomTeamEvent = localSettings(true, "matchRandomTeamEvent")
let matchRandomTeam = Computed(@() isInEventGM.value
  ? matchRandomTeamEvent.value
  : matchRandomTeamCommon.value)

let randTeamAvailable = Computed(function () {
  let isAvailable = curUnfinishedBattleTutorial.value == null
    && (!isInSquad.value || isSquadLeader.value)

  if (!isInEventGM.value && isAvailable)
    return isAvailable

  let { minCampaignLevelReq = 1 } = selEvent.value
  return curArmiesList.value
    .reduce(@(pre, cur) pre && armies.value[cur].level >= minCampaignLevelReq, isAvailable)
})

let function joinImpl(queue) {
  lastQueue(queue)
  let queueSuffixes = curArmiesList.value.map(@(army) armies.value[army].level.tostring())
  let params = { queueSuffixes }
  let queueTeam = queue?.eventCurArmy ?? mteam.value
  params.mteams <- matchRandomTeam.value || queueTeam == null
    ? [0, 1]
    : [queueTeam]
  joinQueue(queue, params)
}

let function join(queue) {
  if (isInQueue.value)
    leaveQueue(@() joinImpl(queue))
  else
    joinImpl(queue)
}

let function setRandTeamValue(val) {
  let watch = isInEventGM.value ? matchRandomTeamEvent : matchRandomTeamCommon
  if (val == watch.value)
    return
  watch(val)

  if (isInQueue.value)
    join(lastQueue.value)
}

let randTeamBoxStyle = {
  text = loc("queue/join_any_team")
  margin = 0
}.__update(body_txt)

let randTeamCheckbox = checkbox(matchRandomTeam, randTeamBoxStyle, {
  setValue = setRandTeamValue
  textOnTheLeft = true
})

let alwaysRandTeamSign = checkbox(Watched(true), randTeamBoxStyle, {
  setValue = @(_val) showMsgbox({ text = loc("modeIsAlwaysForRandTeam") })
  textOnTheLeft = true
})

let function activateCrossplay(_val) {
  saveCrossnetworkPlayValue(CrossplayState.ALL)
}

let isCrossplayStateOn = Computed(@() crossnetworkPlay.value == CrossplayState.ALL)
let canSwitchCrossplayState = Computed(@() !is_xbox || crossnetworkPlay.value != CrossplayState.OFF)

let hasCrossplayHint = Computed(function() {
  if (!isInQueue.value
    || isCrossplayStateOn.value)
    return false

  let crossplayHintSec = currentGameMode.value?.showCrossplayHintAfterSec ?? -1
  if (crossplayHintSec < 0)
    return false

  return timeInQueue.value / 1000 >= crossplayHintSec
})

let crossplayCheckbox = checkbox(isCrossplayStateOn,
  {
    text = loc("queue/switchCrossplay")
    color = Color(255,255,255)
    margin = 0
  }.__update(body_txt),
  {
    setValue = activateCrossplay
    textOnTheLeft = true
  })

let crossplayHint = @() {
  watch = [hasCrossplayHint, canSwitchCrossplayState]
  flow = FLOW_HORIZONTAL
  gap = fsh(2)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = hasCrossplayHint.value
    ? [
        crossplayIcon
        {
          flow = FLOW_VERTICAL
          children = [
            txt({
              text = loc("queueCrossplayHint")
              color = titleTxtColor
            }).__update(sub_txt)
            canSwitchCrossplayState.value ? crossplayCheckbox : null
          ]
        }
      ]
    : null
}

let isCurQueueReqRandomSide = Computed(@()
  lastQueue.value?.alwaysRandomSide ?? false)

let isCurEventReqRandomSide = keepref(Computed(@()
  (selEvent.value?.alwaysRandomSide ?? false) && isEventModesOpened.value))

isCurEventReqRandomSide.subscribe(function(val) {
  if (val)
    setRandTeamValue(true)
})

return {
  randTeamAvailable
  randTeamCheckbox
  alwaysRandTeamSign
  crossplayHint
  joinQueue = join
  matchRandomTeam
  isCurQueueReqRandomSide
}
