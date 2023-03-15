from "%enlSqGlob/ui_library.nut" import *

let { fontMedium, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, colPart, titleTxtColor, commonBorderRadius, bigPadding, accentColor, panelBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let { timeInQueue, queueInfo, isInQueue } = require("%enlist/state/queueState.nut")
let { leaveQueue } = require("%enlist/quickMatchQueue.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { allArmiesInfo } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curArmiesList, curArmy } = require("%enlist/soldiers/model/state.nut")
let { eventsArmiesList, eventCurArmyIdx } = require("%enlist/gameModes/eventModesState.nut")
let { doubleSideHighlightLine, doubleSideBg } = require("%enlSqGlob/ui/defcomponents.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { randTeamAvailable, randTeamCheckbox, alwaysRandTeamSign, crossplayHint, matchRandomTeam,
  isCurQueueReqRandomSide
} = require("%enlist/army/anyTeamCheckbox.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")


let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let defTxtStyle = { color = titleTxtColor }.__update(fontMedium)


const TIME_BEFORE_SHOW_QUEUE = 15
const MIN_VISIBLE_PLAYERS_AMOUNT = 2
const WND_UID = "queueWaitingWindow"
let wndSize = [colFull(8), colPart(6.45)]
let titleHeight = colPart(0.903)
let curArmyInfo = Computed(function() {
  local armyList = curArmiesList.value
  local armyId = curArmy.value
  if (eventsArmiesList.value.len() > 0) {
    armyList = eventsArmiesList.value
    armyId = eventsArmiesList.value[eventCurArmyIdx.value]
  }
  return { armyId, armyList }
})


let queueTitle = @() {
  size = [flex(), titleHeight]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    doubleSideHighlightLine()
    doubleSideBg({
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("queue/searchingTitle"))
    }.__update(headerTxtStyle))
    doubleSideHighlightLine({ vplace = ALIGN_BOTTOM })
  ]
}


let searchingTimer = @() {
  watch = timeInQueue
  rendObj = ROBJ_TEXT
  text = secondsToStringLoc(timeInQueue.value / 1000)
}.__update(defTxtStyle)


let maxMinPlayersAmount = Computed(@() (currentGameMode.value?.queue.modes ?? [])
  .reduce(@(res, val) (val?.minPlayers ?? 1) > res ? val : res, 1))


let function armiesBlock() {
  let res = { watch = [queueInfo, timeInQueue, curArmiesList, curArmy, curArmyInfo] }
  if (timeInQueue.value < TIME_BEFORE_SHOW_QUEUE && (queueInfo.value?.matched ?? 0) < 0)
    return res

  return res.__update({
    size = [colFull(4), SIZE_TO_CONTENT]
    padding = [0, colPart(0.5)]
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_CENTER
    gap = {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      text = loc("mainmenu/versus_short")
      vplace = ALIGN_CENTER
    }.__update(headerTxtStyle)
    halign = ALIGN_CENTER
    children = curArmyInfo.value.armyList.map(function(army, idx) {
      let isSelected = army == curArmyInfo.value.armyId
      return @() {
        watch = [matchRandomTeam, allArmiesInfo, maxMinPlayersAmount]
        rendObj = ROBJ_BOX
        borderWidth = matchRandomTeam.value || isSelected ? [0, 0, hdpx(2), 0] : 0
        borderColor = accentColor
        flow = FLOW_HORIZONTAL
        gap = { size = flex() }
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          mkArmyIcon(allArmiesInfo.value?[army].id, colFull(1), matchRandomTeam.value || isSelected
            ? { color = accentColor }
            : {})
          maxMinPlayersAmount.value < MIN_VISIBLE_PLAYERS_AMOUNT ? null
            : {
                rendObj = ROBJ_TEXT
                text = queueInfo.value?.matchedByTeams[idx] ?? 0
              }.__update(defTxtStyle)
        ]
      }
  })
})}


let randomTeamHint = @(needToHide) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), colPart(0.4)]
  text = needToHide ? "" : loc("queue/join_any_team_hint")
  halign = ALIGN_CENTER
}.__update(defTxtStyle)


let function mkRandomTeamContent() {
  let res = { watch = [randTeamAvailable, isCurQueueReqRandomSide, matchRandomTeam] }
  if (!randTeamAvailable.value)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = [
      randomTeamHint(matchRandomTeam.value)
      isCurQueueReqRandomSide.value ? alwaysRandTeamSign : randTeamCheckbox(true)
    ]
  })
}


let timerBlock = {
  flow = FLOW_VERTICAL
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    searchingTimer
    mkSpinner(colFull(1))
  ]
}


let hintsBlock = {
  size = [flex(), colPart(1.2)]
  minHeight = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  gap = bigPadding
  halign = ALIGN_CENTER
  children = [
    crossplayHint
    mkRandomTeamContent
  ]
}


let wndContent = {
  rendObj = ROBJ_BOX
  fillColor = panelBgColor
  borderRadius = commonBorderRadius
  size = wndSize
  padding = [0, 0, titleHeight / 2, 0 ]
  pos = [0, sh(45) - wndSize[1]]
  transform = {}
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
  flow = FLOW_VERTICAL
  gap = { size = flex() }
  halign = ALIGN_CENTER
  children = [
    queueTitle
    timerBlock
    armiesBlock
    hintsBlock
  ]
}


let open = @() addModalWindow({
  key = WND_UID
  size = SIZE_TO_CONTENT
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  stopHover = true
  stopMouse = true
  behavior = Behaviors.Button
  hotkeys = [[$"^{JB.B} | Esc", @() leaveQueue()]]
  children = wndContent
  onClick = @() null
})


isInQueue.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))