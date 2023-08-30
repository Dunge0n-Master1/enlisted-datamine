from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { mainContentOffset, bigPadding, startBtnWidth, midPadding, contentOffset, commonBtnHeight,
  defItemBlur, darkTxtColor, transpPanelBgColor, hoverSlotBgColor, titleTxtColor, defTxtColor,
  accentColor, smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let startBtn = require("%enlist/startButton.nut")
let { changeGameModeBtn, selectedGameMode } = require("%enlist/mainScene/changeGameModeButton.nut")
let { randTeamAvailable, randTeamCheckbox } = require("%enlist/quickMatch.nut")
let { mkDailyTasksUiReward, mkDailyTasksUi } = require("%enlist/unlocks/taskWidgetUi.nut")
let mkOffersPanel = require("%enlist/offers/offersPanel.nut")
let { isMainMenuVisible } = require("%enlist/mainMenu/sectionsState.nut")
let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let mkServiceNotification = require("%enlSqGlob/notifications/mkServiceNotification.nut")
let { mkSquadsList } = require("%enlist/soldiers/squads_list.ui.nut")
let systemWarningsBlock = require("%enlist/mainScene/systemWarnings.nut")
let { mkSquadInfo } = require("%enlist/soldiers/squad_info.ui.nut")
let mkSoldierInfo = require("%enlist/soldiers/mkSoldierInfo.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let gotoResearchUpgradeMsgBox = require("%enlist/soldiers/researchUpgradeMsgBox.nut")
let { promoWidget } = require("%enlist/components/mkPromoWidget.nut")
let { mkPresetEquipBlock } = require("%enlist/preset/presetEquipUi.nut")
let { notifierHint } = require("%enlist/tutorial/notifierTutorial.nut")
let { hasBaseEvent, openCustomGameMode } = require("%enlist/gameModes/eventModesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")


let isOfferExpandLocked = Watched(false)

let function mkMainSceneContent() {
  let function mkSoldiersUi(){
    let squad_info = mkSquadInfo()
    let squads_list = mkSquadsList()

    let mainContent = {
      size = flex()
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          valign = ALIGN_BOTTOM
          children = [
            armySelectUi
            promoWidget("soldier_equip", "soldier_inventory")
            notifierHint
          ]
        }
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = [
            squads_list
            squad_info
            mkSoldierInfo({ soldierInfoWatch = curSoldierInfo, onResearchClickCb = gotoResearchUpgradeMsgBox})
            mkPresetEquipBlock()
          ]
        }
      ]
    }

    return mainContent
  }

  let customMatchesBtn = @(){
    watch = hasBaseEvent
    size = [flex(), SIZE_TO_CONTENT]
    children = hasBaseEvent.value ? null : watchElemState(@(sf) {
      rendObj = ROBJ_WORLD_BLUR
      size = [flex(), commonBtnHeight]
      color = defItemBlur
      fillColor = sf & S_ACTIVE ? accentColor
        : sf & S_HOVER ? hoverSlotBgColor
        : transpPanelBgColor
      behavior = Behaviors.Button
      onClick = openCustomGameMode
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("custom_matches"))
        color = sf & S_ACTIVE ? titleTxtColor
          : sf & S_HOVER ? darkTxtColor
          : defTxtColor
      }.__update(fontBody)
    })
  }

  let quickMatchButtonWidth = startBtnWidth

  let armyGameModeBlock = @() {
    watch = [selectedGameMode, randTeamAvailable]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
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
      gap = smallPadding
      children = [
        armyGameModeBlock
        startBtn
      ]
    }
  }

  let bpBlockUi = @() {
    watch = isOfferExpandLocked
    behavior = Behaviors.Button
    onHover = @(on) isOfferExpandLocked(on)
    skipDirPadNav = true
    children = {
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        mkDailyTasksUiReward(@(on) isOfferExpandLocked(on))
        !isOfferExpandLocked.value ? null
          : {
              clipChildren = true
              children = {
                key = isOfferExpandLocked.value
                children = mkDailyTasksUi(@(on) isOfferExpandLocked(on))
                transform = {}
                animations = [{ prop = AnimProp.translate, from = [0, -hdpxi(180)],
                  to = [0, 0], duration = 0.3, easing = OutQuintic, play = true }]
              }
            }
      ]
    }
  }

  let rightContent = {
    size = [startBtnWidth, flex()]
    margin = [mainContentOffset,0,0,0]
    hplace = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    gap = { size = flex() }
    children = [
      @() {
        watch = [serviceNotificationsList, hasBaseEvent]
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = midPadding
        children = serviceNotificationsList.value.len() > 0
          ? mkServiceNotification(serviceNotificationsList.value, { hplace = ALIGN_RIGHT })
          : [
              bpBlockUi
              mkOffersPanel(isOfferExpandLocked)
              hasBaseEvent.value ? customMatchesBtn : null
            ]
      }
      startPlay
    ]
  }

  let leftContent = @() {
    size = flex()
    margin = [contentOffset, 0,0,0]
    children = mkSoldiersUi
  }
  return {
    size = flex()
    onAttach = @() isMainMenuVisible(true)
    onDetach = @() isMainMenuVisible(false)
    children = [
      leftContent
      rightContent
      systemWarningsBlock
    ]
  }
}
return {mkMainSceneContent}