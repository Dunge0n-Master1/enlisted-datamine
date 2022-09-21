from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let userLogPurchasesUi = require("userLogPurchasesUi.nut")
let userLogBattlesUi = require("userLogBattlesUi.nut")
let mkWindowTab = require("%enlist/components/mkWindowTab.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { USERLOG_WIDTH } = require("userLogPkg.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let {
  defBgColor, blurBgColor, tinyOffset, smallOffset, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { requestUserLogs, isUserLogsRequesting } = require("userLogState.nut")


let isOpened = mkWatched(persist, "isOpened", false)
let curTabIdx = mkWatched(persist, "curTabIdx", 0)
let tabsList = [
  {
    locId = "userLog/purchases"
    content = userLogPurchasesUi
  }
  {
    locId = "userLog/battles"
    content = userLogBattlesUi
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
  children = tabsList.map(@(tab, idx)
    mkWindowTab(
      tab?.mkTitleComponent ?? loc(tab?.locId ?? ""),
      @() curTabIdx(idx),
      idx == curTabIdx.value,
      { margin = [0, tinyOffset] },
      tab?.unseenWatch ?? Watched(null)
    )
  )
  .insert(0, isGamepad.value ? mkHotkey("^J:LB", @() switchTab(curTabIdx.value - 1)) : null)
  .append(isGamepad.value ? mkHotkey("^J:RB", @() switchTab(curTabIdx.value + 1)) : null)
}

let tabsContentUi = @() {
  watch = curTabIdx
  size = flex()
  children = makeVertScroll({
      size = [flex(), SIZE_TO_CONTENT]
      margin = [0,smallPadding,0,0]
      children = tabsList[curTabIdx.value].content
    },
    { styling = thinStyle }
  )
}

let userLogWindow = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = [safeAreaBorders, isUserLogsRequesting]
  size = [USERLOG_WIDTH, flex()]
  flow = FLOW_VERTICAL
  gap = smallOffset
  padding = safeAreaBorders.value
  hplace = ALIGN_CENTER
  color = blurBgColor
  children = [
    tabsUi
    isUserLogsRequesting.value
      ? null
      : tabsContentUi
    Bordered(loc("BackBtn"), @() isOpened(false), {
      margin = 0
      hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
    })
  ]
}

let function open() {
  requestUserLogs()
  sceneWithCameraAdd(userLogWindow, "events")
}

let function close() {
  sceneWithCameraRemove(userLogWindow)
}

if (isOpened.value)
  open()

isOpened.subscribe(@ (v) v ? open() : close())

console_register_command(@() isOpened(true), "ui.userLog")

return @() isOpened(true)
