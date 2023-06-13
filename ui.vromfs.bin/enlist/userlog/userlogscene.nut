from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let userLogPurchasesUi = require("userLogPurchasesUi.nut")
let userLogBattlesUi = require("userLogBattlesUi.nut")
let mkWindowTab = require("%enlist/components/mkWindowTab.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { defBgColor, blurBgColor, tinyOffset, smallOffset, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { userLogsRequest, isUserLogsRequesting } = require("userLogState.nut")


let USERLOG_WIDTH = fsh(100)

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
  if (newIdx > tabsList.len()-1)
    newIdx = 0
  else if (newIdx < 0)
    newIdx = tabsList.len()-1
  if (tabsList?[newIdx] != null)
    curTabIdx(newIdx)
}

let prevTab = @() switchTab(curTabIdx.value - 1)
let nextTab = @() switchTab(curTabIdx.value + 1)

let tabsUi = @() {
  watch = [curTabIdx, isGamepad]
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  color = defBgColor
  hotkeys = [["^J:RB | Tab", nextTab], ["^J:LB | L.Shift Tab", prevTab]]
  children = [isGamepad.value ? mkHotkey("^J:LB", prevTab) : null].extend(
    tabsList.map(@(tab, idx)
      mkWindowTab(
        tab?.mkTitleComponent ?? loc(tab?.locId ?? ""),
        @() curTabIdx(idx),
        idx == curTabIdx.value,
        { margin = [0, tinyOffset], skipDirPadNav=true},
        tab?.unseenWatch ?? Watched(null)
      )
    )
  )
  .append(isGamepad.value ? mkHotkey("^J:RB", nextTab) : null)
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
  watch = [safeAreaBorders, isUserLogsRequesting, isGamepad]
  size = [USERLOG_WIDTH, flex()]
  key = isGamepad.value
  flow = FLOW_VERTICAL
  gap = smallOffset
  margin = [safeAreaBorders.value[0]+sh(2), safeAreaBorders.value[1], safeAreaBorders.value[0]+sh(7), safeAreaBorders.value[1]]
  hplace = ALIGN_CENTER
  color = blurBgColor
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn"), action = @() isOpened(false)} ]]
  children = [
    tabsUi
    isUserLogsRequesting.value
      ? null
      : tabsContentUi
    isGamepad.value ? null : Bordered(loc("BackBtn"), @() isOpened(false), {
      margin = 0
    })
  ]
}

let function open() {
  userLogsRequest()
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
