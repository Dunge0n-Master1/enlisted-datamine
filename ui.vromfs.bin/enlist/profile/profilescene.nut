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
  achievementsList, hasAchievementsReward
} = require("%enlist/unlocks/taskListState.nut")
let { mkAchievementTitle } = require("%enlSqGlob/ui/taskPkg.nut")
let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let wallpostersUi = require("wallpostersUi.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let mkWindowTab = require("%enlist/components/mkWindowTab.nut")
let { mkFooterWithButtons, PROFILE_WIDTH } = require("profilePkg.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { isWpHidden, wpIdSelected } = require("wallpostersState.nut")
let {
  defBgColor, blurBgColor, tinyOffset, bigOffset
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


let hasUnseenCardElements = Computed(@()
  hasUnseenDecorators.value || hasRankUnseen.value)
let hasUnopenedCardElements = Computed(@()
  hasUnopenedDecorators.value || hasUnopenedRank.value)


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
        .__update(h2_txt, { color })
    }
    content = achievementsBlockUI
    unseenMarkType = Computed(@() !hasAchievementsReward.value ? null
      : hasUnopenedAchievements.value ? "blink"
      : "noBlink")
  }
  {
    id = "weeklyTasks"
    locId = "profile/weeklyTasks"
    content = weeklyUnlocksUi
    unseenMarkType = Computed(@() !hasUnseenWeeklyTasks.value ? null
      : hasUnopenedWeeklyTasks.value ? "blink"
      : "noBlink")
  }
  {
    id = "replay"
    locId = "replay/records"
    content = replayCardUi
    hideWatch = isReplayTabHidden
  }
]

let function switchTab(newIdx){
  if (tabsList?[newIdx] != null)
    curTabIdx(newIdx)
}

let tabsUi = @() {
  watch = [curTabIdx, isGamepad]
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  color = defBgColor
  halign = ALIGN_CENTER
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
        children = isHidden ? null
          : mkWindowTab(
              tab?.mkTitleComponent ?? loc(tab?.locId ?? ""),
              @() curTabIdx(idx),
              idx == curTabIdx.value,
              { margin = [0, tinyOffset] },
              tab?.unseenMarkType ?? Watched(null)
            )
      }
    }
  }).insert(0, isGamepad.value ? mkHotkey("^J:LB", @() switchTab(curTabIdx.value - 1)) : null)
    .append(isGamepad.value ? mkHotkey("^J:RB", @() switchTab(curTabIdx.value + 1)) : null)
}

let tabsContentUi = @() {
  watch = curTabIdx
  size = flex()
  padding = [bigOffset, 0]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = tabsList[curTabIdx.value].content
}

let profileWindow = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = safeAreaBorders
  size = flex()
  padding = safeAreaBorders.value
  halign = ALIGN_CENTER
  color = blurBgColor
  onAttach = saveFinishedWeeklyTasks
  children = {
    size = [PROFILE_WIDTH, flex()]
    flow = FLOW_VERTICAL
    padding = [bigOffset, 0]
    children = [
      tabsUi
      tabsContentUi
      mkFooterWithButtons([
        Bordered(loc("BackBtn"), function() {
          if (wpIdSelected.value != null)
            return wpIdSelected(null)

          isProfileOpened(false)
        }, {
          hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
          margin = 0
        })
      ])
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
