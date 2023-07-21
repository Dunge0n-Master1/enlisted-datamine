from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { colPart, transpPanelBgColor, panelBgColor, defItemBlur, bigPadding, largePadding
} = require("%enlSqGlob/ui/designConst.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let spinner = require("%ui/components/spinner.nut")
let cursors = require("%ui/style/cursors.nut")
let { activeTitleTxtColor, titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let {
  randTeamAvailable, randTeamCheckbox, matchRandomTeam, crossplayHint,
  alwaysRandTeamSign, isCurQueueReqRandomSide
} = require("%enlist/quickMatch.nut")
let { timeInQueue, queueInfo, isInQueue } = require("%enlist/state/queueState.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { noteTextArea, txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  allArmiesInfo
} = require("%enlist/soldiers/model/config/gameProfile.nut")
let {
  curArmiesList, curArmy
} = require("%enlist/soldiers/model/state.nut")
let {
  eventsArmiesList, eventCurArmyIdx
} = require("%enlist/gameModes/eventModesState.nut")
let { doubleSideHighlightLine, doubleSideHighlightLineBottom, doubleSideBg
} = require("%enlSqGlob/ui/defComponents.nut")
let { dailyTasksUi } = require("%enlist/unlocks/taskWidgetUi.nut")

const TIME_BEFORE_SHOW_QUEUE = 15
const MIN_VISIBLE_PLAYERS_AMOUNT = 2

let defaultSize = [fsh(45), fsh(53)]
let defPosSize = {
  size = defaultSize
  pos = [ sw(50) - defaultSize[0] / 2, sh(80) - defaultSize[1] ]
}
let titleHeight = colPart(1)
let spinnerHeight = colPart(1.1)
let waitingSpinner = spinner(spinnerHeight)

let posSize = Watched(defPosSize)

let infoContainer = {
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  padding = 0
  transform = {}
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
}

let function queueTitle() {
  return {
    size = [flex(), titleHeight]
    flow = FLOW_VERTICAL
    watch = timeInQueue
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    vplace = ALIGN_TOP
    children = [
      doubleSideHighlightLine
      doubleSideBg(
        noteTextArea({
          text = loc("queue/searching", {
            wait_time = secondsToStringLoc(timeInQueue.value  / 1000)
          })
          halign = ALIGN_CENTER
          color = titleTxtColor
        }).__update(body_txt)
      )
      doubleSideHighlightLineBottom
    ]
  }
}

let maxMinPlayersAmount = Computed(@() (currentGameMode.value?.queue.modes ?? [])
  .reduce(@(res, val) (val?.minPlayers ?? 1) > res ? val : res, 1))

let armiesGap = {
  rendObj = ROBJ_TEXT
  text = loc("mainmenu/versus_short")
  vplace = ALIGN_CENTER
  margin = hdpx(20)
  color = activeTitleTxtColor
}

let queueContent = @() {
  watch = [queueInfo, timeInQueue]
  size = [flex(), hdpx(160)]
  children = (timeInQueue.value > TIME_BEFORE_SHOW_QUEUE && (queueInfo.value?.matched ?? 0) > 0)
    ? function(){
        local armyList = curArmiesList.value
        local armyId = curArmy.value
        if (eventsArmiesList.value.len() > 0) {
          armyList = eventsArmiesList.value
          armyId = eventsArmiesList.value[eventCurArmyIdx.value]
        }
        return {
          watch = [curArmiesList, curArmy, eventsArmiesList, eventCurArmyIdx, allArmiesInfo,
            matchRandomTeam, maxMinPlayersAmount]
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = armiesGap
              halign = ALIGN_CENTER
              children = armyList.map(@(army, idx) {
                rendObj = ROBJ_BOX
                borderWidth = matchRandomTeam.value ? 0 : [0, 0, army == armyId ? 1 : 0, 0]
                fillColor = Color(10,10,10,10)
                size = [hdpx(150), SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                gap = hdpx(20)
                valign = ALIGN_CENTER
                halign = ALIGN_CENTER
                children = [
                  mkArmyIcon(allArmiesInfo.value?[army].id),
                  maxMinPlayersAmount.value < MIN_VISIBLE_PLAYERS_AMOUNT ? null
                    : txt({
                        text = queueInfo.value?.matchedByTeams[idx] ?? 0
                        color = titleTxtColor
                      }).__update(body_txt)
                ]
              })
            }
            waitingSpinner
          ]
        }}
    : null
}

let randomTeamHint = noteTextArea({
  text = loc("queue/join_any_team_hint")
  halign = ALIGN_CENTER
  color = titleTxtColor
}).__update(sub_txt)

let function mkRandomTeamContent() {
  let res = { watch = [randTeamAvailable, isCurQueueReqRandomSide, matchRandomTeam] }
  if (!randTeamAvailable.value)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      matchRandomTeam.value ? null : randomTeamHint
      isCurQueueReqRandomSide.value ? alwaysRandTeamSign : randTeamCheckbox
    ]
  })
}

let tasksBlock = {
  rendObj = ROBJ_WORLD_BLUR
  fillColor = panelBgColor
  color = defItemBlur
  size = [flex(), SIZE_TO_CONTENT]
  padding = hdpx(30)
  halign = ALIGN_CENTER
  gap = hdpx(30)
  children = dailyTasksUi
}

local dxSum = 0.0
local dySum = 0.0
local canBeUpdated = false

return function queueWaitingInfo() {
  let pos = posSize.value.pos

  return !isInQueue.value ? {watch=[isInQueue]} : {
    watch = [posSize, isInQueue]
    fillColor = transpPanelBgColor
    borderRadius = hdpx(2)
    rendObj = ROBJ_WORLD_BLUR_PANEL
    moveResizeCursors = null
    size = SIZE_TO_CONTENT
    behavior = [Behaviors.MoveResize, Behaviors.RtPropUpdate]
    update = function() {
      canBeUpdated = true
    }
    cursor = cursors.normal
    stopHover = true
    valign = ALIGN_CENTER
    key = 1
    pos
    onMoveResize = function(dx, dy, _dw, _dh) {
      dxSum += dx
      dySum += dy
      if (!canBeUpdated)
        return null

      canBeUpdated = false
      let newPosSize = {size = defaultSize, pos = [
        clamp(pos[0] + dxSum, 0, sw(100) - defaultSize[0]),
        clamp(pos[1] + dySum, 0, sh(100) - defaultSize[1])
      ]}
      posSize(newPosSize)
      dxSum = 0.0
      dySum = 0.0
      return newPosSize
    }
    children = infoContainer.__merge({
      size = [SIZE_TO_CONTENT, defaultSize[1]]
      minWidth = defaultSize[0]
      gap = largePadding
      valign = ALIGN_TOP
      children = [
        queueTitle
        crossplayHint
        queueContent
        mkRandomTeamContent
        tasksBlock
      ]
    })
  }
}