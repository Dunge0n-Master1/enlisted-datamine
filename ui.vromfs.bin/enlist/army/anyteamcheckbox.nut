from "%enlSqGlob/ui_library.nut" import *

let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { fontMedium, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, midPadding, smallPadding, colPart
} = require("%enlSqGlob/ui/designConst.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let { isInQueue, leaveQueue, joinQueue, timeInQueue, curQueueParam
} = require("%enlist/quickMatchQueue.nut")
let { curUnfinishedBattleTutorial } = require("%enlist/tutorial/battleTutorial.nut")
let { isInSquad, isSquadLeader } = require("%enlist/squad/squadState.nut")
let { curArmiesList, armies } = require("%enlist/meta/profile.nut")
let { mteam } = require("%enlist/soldiers/model/state.nut")
let localSettings = require("%enlist/options/localSettings.nut")("quickMatch/")
let { currentGameMode, eventGameModes } = require("%enlist/gameModes/gameModeState.nut")
let saveCrossnetworkPlayValue = require("%enlist/options/crossnetwork_save.nut")
let { crossnetworkPlay, CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")
let { is_xbox } = require("%dngscripts/platform.nut")
let { selEvent, isEventModesOpened } = require("%enlist/gameModes/eventModesState.nut")
let mkCheckbox = require("%ui/components/mkCheckbox.nut")
let { mkArmyIcon } = require("%enlist/army/armyPackage.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)

let lastQueue = mkWatched(persist, "lastQueue", null)
let isInEventGM = Computed(@() isEventModesOpened.value || (curQueueParam.value != null
  && eventGameModes.value.findvalue(@(v) v.queue.queueId == curQueueParam.value?.queueId)))


let matchRandomTeamCommon = localSettings(true, "matchRandomTeam")
let matchRandomTeamEvent = localSettings(true, "matchRandomTeamEvent")
let matchRandomTeam = Computed(@() isInEventGM.value
  ? matchRandomTeamEvent.value
  : matchRandomTeamCommon.value)


let randTeamAvailable = Computed(function () {
  let isAvailable = curUnfinishedBattleTutorial.value == null
    && (!isInSquad.value || isSquadLeader.value)

  if (!isAvailable)
    return false
  if (!isInEventGM.value)
    return true

  let { minCampaignLevelReq = 1 } = selEvent.value
  return curArmiesList.value.findindex(@(cur)
    armies.value[cur].level < minCampaignLevelReq) == null
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


let randTeamCheckbox = @() {
  watch = [isInEventGM, curArmiesList]
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = curArmiesList.value.map(@(armyId) mkArmyIcon(armyId, colPart(0.35)))
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("queue/join_any_team")
    }.__update(titleTxtStyle)
    mkCheckbox(isInEventGM.value ? matchRandomTeamEvent : matchRandomTeamCommon)
  ]
}

foreach (value in [matchRandomTeamEvent, matchRandomTeamCommon])
  value.subscribe(setRandTeamValue)

let alwaysRandTeamSign = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick = @() showMsgbox({ text = loc("modeIsAlwaysForRandTeam") })
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("queue/join_any_team")
    }
    mkCheckbox(Watched(true), false)
  ]
}


let activateCrossplay =  @(_val) saveCrossnetworkPlayValue(CrossplayState.ALL)
let isCrossplayStateOn = Computed(@() crossnetworkPlay.value == CrossplayState.ALL)
let canSwitchCrossplayState = Computed(@() !is_xbox || crossnetworkPlay.value != CrossplayState.OFF)
let isCrossplayEnabled = Watched(isCrossplayStateOn.value)


let hasCrossplayHint = Computed(function() {
  if (!isInQueue.value
    || isCrossplayStateOn.value)
    return false

  let crossplayHintSec = currentGameMode.value?.showCrossplayHintAfterSec ?? -1
  if (crossplayHintSec < 0)
    return false

  return timeInQueue.value / 1000 >= crossplayHintSec
})

let crossplayCheckbox = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("queue/switchCrossplay")
    }.__update(titleTxtStyle)
    mkCheckbox(isCrossplayEnabled)
  ]
}
isCrossplayEnabled.subscribe(activateCrossplay)

let crossplayHint = @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = [hasCrossplayHint, canSwitchCrossplayState]
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  children = !hasCrossplayHint.value ? null
    : [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = midPadding
          children = [
            crossplayIcon
            {
              size = [flex(), SIZE_TO_CONTENT]
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              text = loc("queueCrossplayHint")
            }.__update(defTxtStyle)
          ]
        }
        canSwitchCrossplayState.value ? crossplayCheckbox : null
      ]
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
