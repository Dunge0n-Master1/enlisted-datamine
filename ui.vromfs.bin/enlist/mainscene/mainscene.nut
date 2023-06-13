from "%enlSqGlob/ui_library.nut" import *

let { mainContentOffset, bigPadding, startBtnWidth, midPadding
} = require("%enlSqGlob/ui/designConst.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let startBtn = require("%enlist/startButton.nut")
let { changeGameModeBtn, selectedGameMode } = require("%enlist/mainScene/changeGameModeButton.nut")
let { randTeamAvailable, randTeamCheckbox } = require("%enlist/quickMatch.nut")
let { dailyTasksUi } = require("%enlist/unlocks/taskWidgetUi.nut")
let weeklyTasksUi = require("%enlist/unlocks/weeklyTasksBtn.nut")
let battlepassWidgetOpen = require("%enlist/battlepass/battlePassButton.nut")
let { hasBattlePass } = require("%enlist/unlocks/taskRewardsState.nut")
let offersPanel = require("%enlist/offers/offersPanel.nut")
let { setCurSection, isMainMenuVisible } = require("%enlist/mainMenu/sectionsState.nut")
let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let mkServiceNotification = require("%enlSqGlob/notifications/mkServiceNotification.nut")
let { squadInfo } = require("%enlist/soldiers/squadInfo.nut")
let tooltipCtor = require("%ui/style/tooltipCtor.nut")
let { setTooltip } = require("%ui/style/cursors.nut")

let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkCurSquadsList.nut")
let { curSquadId, setCurSquadId, curChoosenSquads, curUnlockedSquads } = require("%enlist/soldiers/model/state.nut")
let { mkSlotAlertsComponent, mkSquadManagementBtn } = require("%enlist/soldiers/squads_list.ui.nut")
let { multySquadPanelSize } = require("%enlSqGlob/ui/viewConst.nut")
let systemWarningsBlock = require("%enlist/mainScene/systemWarnings.nut")

let dblClkTooltipTxt = tooltipCtor({
  rendObj = ROBJ_TEXT
  text = loc("squad/doubleClick")
})

let function mkMainSceneContent() {

  let curSquadsList = Computed(@() (curChoosenSquads.value ?? [])
    .map(@(squad) squad.__merge({
      level = allSquadsLevels.value?[squad.squadId] ?? 0
      addChild = mkSlotAlertsComponent(squad)
      onDoubleClick = @() setCurSection("SQUAD_SOLDIERS")
      onHover = @(on) setTooltip(on ? dblClkTooltipTxt : null)
    })))


  let restSquadsCount = Computed(@()
    max(curUnlockedSquads.value.len() - curChoosenSquads.value.len(), 0))

  let curSquads = mkCurSquadsList({
    curSquadsList
    curSquadId
    setCurSquadId
    preChild = mkSquadManagementBtn({restSquadsCount, size=multySquadPanelSize, margin=0})
  })

  let quickMatchButtonWidth = hdpx(400)

  let armyGameModeBlock = @() {
    watch = [selectedGameMode, randTeamAvailable]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_RIGHT
    children = [
      selectedGameMode.value?.isLocal || !randTeamAvailable.value ? null : randTeamCheckbox
      changeGameModeBtn
    ]
  }

  let startPlay = {
    halign = ALIGN_RIGHT
    children = @() {
      watch = [selectedGameMode, randTeamAvailable]
      size = [quickMatchButtonWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      gap = bigPadding
      children = [
        armyGameModeBlock
        startBtn
      ]
    }
  }

  let rightContent = {
    size = flex()
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    children = [
      offersPanel
      {size = [0, flex()]}
      startPlay
    ]
  }

  let mainContent = @() {
    size = flex()
    flow = FLOW_VERTICAL
    gap = fsh(1.5)
    children = [
      {
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = @() {
          watch = [serviceNotificationsList, hasBattlePass]
          size = [startBtnWidth, SIZE_TO_CONTENT]
          gap = bigPadding
          flow = FLOW_VERTICAL
          children = serviceNotificationsList.value.len() > 0
            ? mkServiceNotification(serviceNotificationsList.value, { hplace = ALIGN_RIGHT })
            : [
                {
                  flow = FLOW_VERTICAL
                  gap = bigPadding
                  children = [
                    hasBattlePass.value ? battlepassWidgetOpen : null
                    dailyTasksUi
                    weeklyTasksUi
                  ]
                }
            ]
        }
      }
      {size = [0, flex()]}
      armySelectUi
      squadInfo
      curSquads
    ]
  }
  return {
    size = flex()
    onAttach = @() isMainMenuVisible(true)
    onDetach = @() isMainMenuVisible(false)
    margin = [mainContentOffset,0,0,0]
    children = [
      mainContent
      rightContent
      systemWarningsBlock
    ]
  }
}
return {mkMainSceneContent}