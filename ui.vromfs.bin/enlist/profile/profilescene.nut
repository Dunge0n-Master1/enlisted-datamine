from "%enlSqGlob/ui_library.nut" import *

let medalsUi = require("medalsUi.nut")
let boostersUi = require("boostersUi.nut")
let playerCardUi = require("playerCardUi.nut")
let replayCardUi = require("replayCardUi.nut")
let { isProfileOpened } = require("profileState.nut")
let { hasMedals } = require("%enlist/featureFlags.nut")
let achievementsBlockUI = require("%enlist/unlocks/achievementsBlockUI.nut")
let weeklyUnlocksUi = require("%enlist/unlocks/weeklyUnlocksUi.nut")
let {
  achievementsList, hasAchievementsReward, receiveTaskRewardsAll
} = require("%enlist/unlocks/taskListState.nut")
let { mkAchievementTitle } = require("%enlSqGlob/ui/tasksPkg.nut")
let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let wallpostersUi = require("wallpostersUi.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let mkWindowTab = require("%enlist/components/mkWindowTab.nut")
let { mkFooterWithButtons, PROFILE_WIDTH } = require("profilePkg.nut")
let { Bordered, PrimaryFlat } = require("%ui/components/textButton.nut")
let { isWpHidden, wpIdSelected } = require("wallpostersState.nut")
let {
  defBgColor, blurBgColor, bigOffset, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  hasUnseenMedals, hasUnopenedMedals, hasUnseenDecorators, hasUnopenedDecorators,
  hasUnseenWallposters, hasUnopenedWallposters
} = require("unseenProfileState.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let {
  weeklyTasks, needWeeklyTasksAnim, saveFinishedWeeklyTasks
} = require("%enlist/unlocks/weeklyUnlocksState.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { isReplayTabHidden } = require("%enlist/replay/replaySettings.nut")
let { BLINK, NO_BLINK } = require("%ui/components/unseenComps.nut")
let {
  hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
} = require("%enlist/unlocks/unseenUnlocksState.nut")
let { hasRankUnseen, hasUnopenedRank } = require("%enlist/profile/rankState.nut")
let spinner = require("%ui/components/spinner.nut")
let { unlockRewardsInProgress } = require("%enlSqGlob/userstats/userstat.nut")

let hasUnseenCardElements = Computed(@()
  hasUnseenDecorators.value || hasRankUnseen.value)
let hasUnopenedCardElements = Computed(@()
  hasUnopenedDecorators.value || hasUnopenedRank.value)

let waitingSpinner = spinner()

let btnSize = [hdpx(230), commonBtnHeight]
let function mkBtnGetAllRewards(data) {
  let showBtnWatch = Computed(function() {
    local count = 0
    foreach (u in data.value) {
      if (u.hasReward)
        ++count
      if (count > 1)
        return true
    }
    return false
  })

  return function() {
    if (!showBtnWatch.value)
      return {watch = showBtnWatch}

    return {
      size = [SIZE_TO_CONTENT, btnSize[1]]
      watch = [showBtnWatch, unlockRewardsInProgress]
      minWidth = btnSize[0]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = unlockRewardsInProgress.value.len() > 0
        ? waitingSpinner
        : PrimaryFlat(loc("bp/getAllReward"), @() receiveTaskRewardsAll(data.value), {
            hotkeys = [["^J:X | Enter | Space", { skip = true }]]
            margin = 0
          })
    }
  }
}

let curTabIdx = mkWatched(persist, "curTabIdx", 0)
let tabsList = [
  {
    id = "playerCard"
    locId = "profile/playerCardTab"
    content = playerCardUi
    unseenMarkType = Computed(@() !hasUnseenCardElements.value ? null
      : hasUnopenedCardElements.value ? BLINK
      : NO_BLINK)
  }
  {
    id = "medals"
    locId = "profile/medalsTab"
    content = medalsUi
    hideWatch = Computed(@() !hasMedals.value)
    unseenMarkType = Computed(@() !hasUnseenMedals.value ? null
      : hasUnopenedMedals.value ? BLINK
      : NO_BLINK)
  }
  {
    id = "wallpapers"
    locId = "profile/wallpaperTab"
    content = wallpostersUi
    hideWatch = isWpHidden
    unseenMarkType = Computed(@() !hasUnseenWallposters.value ? null
      : hasUnopenedWallposters.value ? "blink"
      : "noBlink")
  }
  {
    id = "boosters"
    locId = "profile/boostersTab"
    content = boostersUi
  }
  {
    id = "achievements"
    mkTitleComponent = @(color) @() {
      watch = achievementsList
      children = mkAchievementTitle(achievementsList.value, "profile/achievementsTab")
        .__update(fontHeading2, { color })
    }
    content = achievementsBlockUI
    unseenMarkType = Computed(@() !hasAchievementsReward.value ? null
      : hasUnopenedAchievements.value ? "blink"
      : "noBlink")
    additional = @() mkBtnGetAllRewards(achievementsList)
  }
  {
    id = "weeklyTasks"
    locId = "profile/weeklyTasks"
    content = weeklyUnlocksUi
    unseenMarkType = Computed(@() !hasUnseenWeeklyTasks.value ? null
      : hasUnopenedWeeklyTasks.value ? "blink"
      : "noBlink")
    additional = @() mkBtnGetAllRewards(weeklyTasks)
  }
  {
    id = "replay"
    locId = "replay/records"
    content = replayCardUi
    hideWatch = isReplayTabHidden
  }
]

let function switchTab(newIdx){
  if (newIdx > tabsList.len()-1)
    newIdx = 0
  else if (newIdx < 0)
    newIdx = tabsList.len()-1
  if (tabsList?[newIdx] != null)
    curTabIdx(newIdx)
}
let nextTab = @() switchTab(curTabIdx.value + 1)
let prevTab = @() switchTab(curTabIdx.value - 1)

let tabsUi = @() {
  watch = [curTabIdx, isGamepad]
  rendObj = ROBJ_SOLID
  flow = FLOW_HORIZONTAL
  color = defBgColor
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = tabsList.map(function(tab, idx) {
    let isHiddenWatch = tab?.hideWatch ?? Watched(false)
    return function() {
      let isHidden = isHiddenWatch.value
      if (isHidden && curTabIdx.value == idx)
        gui_scene.setTimeout(0.1, function() {
          let newIdx = tabsList.findindex(@(t) !(t?.hideWatch ?? Watched(false)).value)
          if (newIdx == null)
            isProfileOpened(false)
          else
            curTabIdx(newIdx)
        })
      return {
        watch = isHiddenWatch
        hotkeys = [["Tab", nextTab], ["L.Shift Tab", prevTab]]
        children = isHidden ? null
          : mkWindowTab(
              tab?.mkTitleComponent ?? loc(tab?.locId ?? ""),
              @() curTabIdx(idx),
              idx == curTabIdx.value,
              {skipDirPadNav=true},
              tab?.unseenMarkType ?? Watched(null)
            )
      }
    }
  }).insert(0, isGamepad.value ? mkHotkey("^J:LB", prevTab) : null)
    .append(isGamepad.value ? mkHotkey("^J:RB", nextTab) : null)
}

let backAction = function() {
  if (wpIdSelected.value != null)
    return wpIdSelected(null)
  isProfileOpened(false)
}

let tabsContentUi = @() {
  watch = [curTabIdx, isGamepad]
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigOffset
  padding = [bigOffset, 0]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    tabsList[curTabIdx.value].content
    {
      rendObj = ROBJ_BOX
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        isGamepad.value ? null
          : mkFooterWithButtons([ Bordered(loc("BackBtn"), backAction, {margin = 0}) ])
        tabsList[curTabIdx.value]?.additional()
      ]
    }
  ]
}

let profileWindow = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = [safeAreaBorders, isGamepad]
  size = flex()
  padding = safeAreaBorders.value
  halign = ALIGN_CENTER
  color = blurBgColor
  onAttach = saveFinishedWeeklyTasks
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn"), action = backAction} ]]
  children = {
    size = [PROFILE_WIDTH, flex()]
    flow = FLOW_VERTICAL
    padding = [bigOffset, 0]
    children = [
      tabsUi
      tabsContentUi
    ]
  }
}

let function open() {
  sceneWithCameraAdd(profileWindow, "events")
}

let function close() {
  sceneWithCameraRemove(profileWindow)
}

if (isProfileOpened.value)
  open()

isProfileOpened.subscribe(@ (v) v ? open() : close())
weeklyTasks.subscribe(function(_) {
  if (isProfileOpened.value && needWeeklyTasksAnim())
    isProfileOpened(false)
})

console_register_command(@() isProfileOpened(true), "ui.profileScene")

return function(tabId = "") {
  if (tabId != "") {
    let idx = tabsList.findindex(@(tab) tab.id == tabId)
    if (idx != null)
      curTabIdx(idx)
  }
  isProfileOpened(true)
}
