from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80) })
let { WindowTransparent } = require("%ui/style/colors.nut")
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


const TIME_BEFORE_SHOW_QUEUE = 15
const MIN_VISIBLE_PLAYERS_AMOUNT = 2

let defaultSize = [hdpx(480), hdpx(360)]
let defPosSize = {
  size = defaultSize
  pos = [ sw(50) - defaultSize[0] / 2, sh(80) - defaultSize[1] ]
}

let posSize = Watched(defPosSize)

let infoContainer = {
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  padding = hdpx(20)
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
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    watch = timeInQueue
    children = noteTextArea({
      text = loc("queue/searching", {
        wait_time = secondsToStringLoc(timeInQueue.value  / 1000)
      })
      halign = ALIGN_CENTER
      color = titleTxtColor
    }).__update(body_txt)
  }
}
let maxMinPlayersAmount = Computed(@() (currentGameMode.value?.queue.modes ?? [])
  .reduce(@(res, val) (val?.minPlayers ?? 1) > res ? val : res, 1))

let queueContent = @() {
    watch = [queueInfo, timeInQueue]
    size = [flex(), SIZE_TO_CONTENT]
    children = (timeInQueue.value > TIME_BEFORE_SHOW_QUEUE && (queueInfo.value?.matched ?? 0) > 0)
      ? function(){
          local armyList = curArmiesList.value
          local armyId = curArmy.value
          if (eventsArmiesList.value.len() > 0) {
            armyList = eventsArmiesList.value
            armyId = eventsArmiesList.value[eventCurArmyIdx.value]
          }
          return {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              watch = [curArmiesList, curArmy, eventsArmiesList, eventCurArmyIdx, allArmiesInfo,
                matchRandomTeam, maxMinPlayersAmount]
              gap = {
                rendObj = ROBJ_TEXT
                text = loc("mainmenu/versus_short")
                vplace = ALIGN_CENTER
                margin = hdpx(20)
                color = activeTitleTxtColor
              }
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

return function queueWaitingInfo() {
  let pos = posSize.value.pos

  return !isInQueue.value ? {watch=[isInQueue]} : {
    fillColor = WindowTransparent
    borderRadius = hdpx(2)
    rendObj = ROBJ_WORLD_BLUR_PANEL
    moveResizeCursors = null
    size = SIZE_TO_CONTENT
    behavior = Behaviors.MoveResize
    cursor = cursors.normal
    stopHover = true

    watch = [ posSize, isInQueue]
    key = 1
    pos = pos
    onMoveResize = function(dx, dy, _dw, _dh) {
      let newPosSize = {size = defaultSize, pos = [
        clamp(pos[0] + dx, 0, sw(100) - defaultSize[0]),
        clamp(pos[1] + dy, 0, sh(100) - defaultSize[1])
      ]}
      posSize.update(newPosSize)
      return newPosSize
    }
    children = infoContainer.__merge({
      size = defaultSize
      gap = hdpx(20)
      valign = ALIGN_CENTER
      children = [
        queueTitle
        {
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = spinner
        }
        crossplayHint
        queueContent
        mkRandomTeamContent
      ]
    })
  }
}