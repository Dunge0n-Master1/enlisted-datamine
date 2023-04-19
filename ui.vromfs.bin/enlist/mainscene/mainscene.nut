from "%enlSqGlob/ui_library.nut" import *

let { colPart, bigPadding, startBtnWidth, midPadding, leftAppearanceAnim,
  rightAppearanceAnim, DEF_APPEARANCE_TIME
} = require("%enlSqGlob/ui/designConst.nut")
let armySelectUi = require("%enlist/army/armySelectionUi.nut")
let { choosenSquadsList } = require("%enlist/squad/squadsList.ui.nut")
let startBtn = require("%enlist/startButton.nut")
let { changeGameModeBtn, selectedGameMode } = require("%enlist/mainScene/changeGameModeButton.nut")
let eventsAndCustomsButton = require("%enlist/gameModes/eventsAndCustomsButton.nut")
let { randTeamAvailable, randTeamCheckbox } = require("%enlist/army/anyTeamCheckbox.nut")
let { dailyTasksUi } = require("%enlist/unlocks/taskWidgetUi.nut")
let weeklyTasksUi = require("%enlist/unlocks/weeklyTasksBtn.nut")
let battlepassWidgetOpen = require("%enlist/battlepass/battlePassButton.nut")
let { hasBattlePass } = require("%enlist/unlocks/taskRewardsState.nut")
let offersPanel = require("%enlist/offers/offersPanel.nut")
let { isMainMenuVisible } = require("%enlist/mainMenu/sectionsState.nut")
let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let mkServiceNotification = require("%enlSqGlob/notifications/mkServiceNotification.nut")
let { squadInfo } = require("%enlist/squad/squadInfo.nut")
let { curSoldierIdx } = require("%enlist/soldiers/model/curSoldiersState.nut")


let armyGameModeBlock = @() {
  watch = [selectedGameMode, randTeamAvailable]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_RIGHT
  children = [
    selectedGameMode.value?.isLocal || !randTeamAvailable.value ? null : randTeamCheckbox
    changeGameModeBtn()
  ]
}


let topBlock = {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  children = [
    @() {
      watch = hasBattlePass
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        hasBattlePass.value ? battlepassWidgetOpen : null
        dailyTasksUi
        weeklyTasksUi
      ]
    }.__update(rightAppearanceAnim())
    @() {
      watch = serviceNotificationsList
      size = [startBtnWidth, SIZE_TO_CONTENT]
      valign = ALIGN_BOTTOM
      gap = bigPadding
      flow = FLOW_VERTICAL
      children = [
        serviceNotificationsList.value.len() > 0
          ? mkServiceNotification(serviceNotificationsList.value, { hplace = ALIGN_RIGHT })
          : offersPanel
        eventsAndCustomsButton
      ]
    }.__update(leftAppearanceAnim())
  ]
}


let bottomBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_BOTTOM
      gap = { size = flex() }
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = midPadding
          children = [
            squadInfo()
            armySelectUi.__merge({ vplace = ALIGN_BOTTOM})
          ]
        }.__update(rightAppearanceAnim(DEF_APPEARANCE_TIME + 0.2))
        {
          size = [startBtnWidth, SIZE_TO_CONTENT]
          children = armyGameModeBlock
        }.__update(leftAppearanceAnim(DEF_APPEARANCE_TIME + 0.2))
      ]
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        {
          clipChildren = true
          size = [flex(), SIZE_TO_CONTENT]
          children = choosenSquadsList
        }.__update(rightAppearanceAnim(DEF_APPEARANCE_TIME + 0.2))
        startBtn
      ]
    }
  ]
}


return {
  size = flex()
  onAttach = function() {
    curSoldierIdx(null)
    isMainMenuVisible(true)
  }
  onDetach = @() isMainMenuVisible(false)
  margin = [colPart(1.8), 0, 0, 0]
  flow = FLOW_VERTICAL
  children = [
    topBlock
    bottomBlock
  ]
}