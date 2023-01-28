from "%enlSqGlob/ui_library.nut" import *

let { bigPadding, hoverBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let armySelectUi = require("army_select.ui.nut")
let squads_list = require("squads_list.ui.nut")
let squad_info = require("squad_info.ui.nut")
let mkSoldierInfo = require("mkSoldierInfo.nut")
let squadInfoState = require("model/squadInfoState.nut")
let campaignTitle = require("%enlist/campaigns/campaign_title.ui.nut")
let { startBtn, startBtnWidth } = require("%enlist/startBtn.nut")
let { changeGameModeWidget, selectedGameMode
} = require("%enlist/gameModes/changeGameModeBtn.nut")
let clustersUi = require("%enlist/clusters.nut")
let { randTeamAvailable, randTeamCheckbox } = require("%enlist/quickMatch.nut")
let { dailyTasksUi, weeklyTasksUi } = require("%enlist/unlocks/tasksWidgetUi.nut")
let battlepassWidgetOpen = require("%enlist/battlepass/bpWidgets.nut")
let { hasBattlePass } = require("%enlist/unlocks/taskRewardsState.nut")
let offersWidget = require("%enlist/offers/offersWidget.nut")
let gotoResearchUpgradeMsgBox = require("researchUpgradeMsgBox.nut")
let { isMainMenuVisible } = require("%enlist/mainMenu/sectionsState.nut")
let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let { promoWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")
let mkServiceNotification = require("%enlSqGlob/notifications/mkServiceNotification.nut")


let quickMatchButtonWidth = hdpx(400)

let mainContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        @() {
          watch = squadInfoState.curSoldierInfo
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = bigPadding
          children = [
            armySelectUi
            squadInfoState.curSoldierInfo.value == null ? null
              : promoWidget("soldier_equip", "soldier_inventory")
          ]
        }
      ]
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        squads_list
        squad_info
        mkSoldierInfo({ soldierInfoWatch = squadInfoState.curSoldierInfo, onResearchClickCb = gotoResearchUpgradeMsgBox})
      ]
    }
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
      changeGameModeWidget
      startBtn
      selectedGameMode.value?.isLocal ? null : clustersUi
      selectedGameMode.value?.isLocal || !randTeamAvailable.value ? null : randTeamCheckbox
    ]
  }
}

let rightMenuContent = @() {
  watch = hasBattlePass
  size = flex()
  flow = FLOW_VERTICAL
  gap = fsh(1.5)
  halign = ALIGN_RIGHT
  children = [
    campaignTitle
    {
      flow = FLOW_VERTICAL
      size = flex()
      gap = bigPadding
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      children = [
        @() {
          watch = serviceNotificationsList
          size = [startBtnWidth, SIZE_TO_CONTENT]
          valign = ALIGN_BOTTOM
          gap = bigPadding
          flow = FLOW_VERTICAL
          children = serviceNotificationsList.value.len() > 0
            ? mkServiceNotification(serviceNotificationsList.value, { hplace = ALIGN_RIGHT })
            : [
                offersWidget
                {
                  rendObj = ROBJ_WORLD_BLUR_PANEL
                  flow = FLOW_VERTICAL
                  gap = bigPadding
                  color = hoverBgColor
                  children = [
                    hasBattlePass.value ? battlepassWidgetOpen : null
                    dailyTasksUi
                    weeklyTasksUi
                  ]
                }
            ]
        }
        startPlay
      ]
    }
  ]
}

return {
  size = flex()
  onAttach = @() isMainMenuVisible(true)
  onDetach = @() isMainMenuVisible(false)
  children = [
    mainContent
    rightMenuContent
  ]
}
