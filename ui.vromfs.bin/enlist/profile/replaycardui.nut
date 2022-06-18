from "%enlSqGlob/ui_library.nut" import *

let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { smallPadding, rowBg } = require("%enlSqGlob/ui/viewConst.nut")
let { records, currentRecord } = require("%enlist/replay/replaySettings.nut")
let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { format_unix_time } = require("dagor.iso8601")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { load_replay_meta_info } = require("app")
let { ceil } = require("%sqstd/math.nut")
let textButton = require("%ui/components/textButton.nut")
let console = require("console")

let displayPerPage = 10
let curPage = Watched(0)
let totalPages = Computed(@() ceil(records.value.len().tofloat() / displayPerPage).tointeger())

records.subscribe(function(_) {
  if (totalPages.value < curPage.value)
    curPage(totalPages.value)
})

let function mkReplay(record, idx) {
  let replayInfo = load_replay_meta_info(record.id)
  if (!replayInfo)
    return null

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = @() {
      watch = currentRecord
      size = [flex(), hdpx(56)]
      rendObj = ROBJ_SOLID
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      padding = [hdpx(5), hdpx(5), hdpx(5), hdpx(24)]
      valign = ALIGN_CENTER
      xmbNode = XmbNode()
      behavior = Behaviors.Button
      color = rowBg(0, idx, record.id == (currentRecord.value?.id ?? ""))
      onClick = @() currentRecord(record)
      children = [
        {
          rendObj = ROBJ_TEXT
          size = [pw(35), SIZE_TO_CONTENT]
          text = format_unix_time(replayInfo.start_timestamp).replace("T", " ").replace("Z", "")
        }.__update(h2_txt)
        {
          rendObj = ROBJ_TEXT
          size = [pw(45), SIZE_TO_CONTENT]
          text = loc(replayInfo.mission_name)
        }.__update(h2_txt)
        {
          rendObj = ROBJ_TEXT
          text = secondsToStringLoc(replayInfo.total_play_time)
        }.__update(h2_txt)
      ]
    }
  }
}

let mkReplayScroll = makeVertScroll(@() {
  watch = [records, curPage]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = ph(100)
  xmbNode = XmbContainer({
    canFocus = @() false
    scrollSpeed = 5
    isViewport = true
  })
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = records.value.slice(curPage.value * displayPerPage, (curPage.value * displayPerPage) + displayPerPage).map(mkReplay)
})

let mkReplayControl = @() {
  watch = [curPage, totalPages, currentRecord]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    textButton(loc("page/prev"), @() curPage( curPage.value - 1 ), { isEnabled = curPage.value > 0 })
    textButton(loc("page/next"), @() curPage( curPage.value + 1 ), { isEnabled = (curPage.value + 1) < totalPages.value })
    currentRecord.value ? textButton(loc("replay/Watch"), @() console.command($"replay.play {currentRecord.value.id}"), { gap=hdpx(10) }) : null
  ]
}

return {
  size = [fsh(100), flex()]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    mkReplayScroll
    mkReplayControl
  ]
}
