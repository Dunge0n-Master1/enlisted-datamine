from "%enlSqGlob/ui_library.nut" import *

let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { smallPadding, rowBg } = require("%enlSqGlob/ui/viewConst.nut")
let { getFiles, currentRecord } = require("%enlist/replay/replaySettings.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { format_unix_time } = require("dagor.iso8601")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { load_replay_meta_info, replay_play } = require("app")
let { ceil } = require("%sqstd/math.nut")
let textButton = require("%ui/components/textButton.nut")
let { NET_PROTO_VERSION, get_dasevent_net_version } = require("net")
let msgbox = require("%enlist/components/msgbox.nut")
let {get_setting_by_blk_path} = require("settings")

let allowProtoMismatch = get_setting_by_blk_path("replay/allowProtoMismatch") ?? false

let displayPerPage = 10
let curPage = Watched(0)
let isCurrentRecordProtocolValid = Watched(true)
let records = Watched(getFiles())
let totalPages = Computed(@() ceil(records.value.len().tofloat() / displayPerPage).tointeger())

records.subscribe(function(_) {
  if (totalPages.value < curPage.value)
    curPage(totalPages.value)
})

let mkProtocolBlock = @(isValid) {
  size = [pw(45), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  text = loc(isValid ? "replay/readyToPlay" : "replay/protocolMisMatch")
  color = isValid ? 0xFF14FF0A : 0xFFFF4E4E
}.__update(body_txt)

let function watchCurrentReplay() {
  let replayInfo = load_replay_meta_info(currentRecord.value.id)
  let startFrom = replayInfo?.first_human_spawn_time ?? 0
  if (isCurrentRecordProtocolValid.value) {
    replay_play(currentRecord.value.id, startFrom)
    return
  }

  let buttons = [{
    text = loc("Ok")
    isCancel = true
  }]

  if (allowProtoMismatch)
    buttons.append({
      text = loc("replay/playAnyway")
      action = @() replay_play(currentRecord.value.id, startFrom)
      isCurrent = true
    })

  msgbox.show({
    text = loc("replay/protocolMisMatchDoYouWantStart"),
    buttons
  })
}

let function mkReplay(record, idx, das_net_version) {
  let replayInfo = load_replay_meta_info(record.id)
  if (!replayInfo)
    return null

  let isValidProtocol = replayInfo?.protocol_version == NET_PROTO_VERSION &&
    replayInfo?.dasevent_net_version == das_net_version

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
      onClick = function() {
        currentRecord(record)
        isCurrentRecordProtocolValid(isValidProtocol)
      }
      children = [
        {
          rendObj = ROBJ_TEXT
          size = [pw(25), SIZE_TO_CONTENT]
          text = format_unix_time(replayInfo?.start_timestamp ?? 0).replace("T", " ").replace("Z", "")
        }.__update(body_txt)
        {
          rendObj = ROBJ_TEXT
          size = [pw(35), SIZE_TO_CONTENT]
          text = loc(replayInfo?.mission_name ?? "replay/UnknownMission")
        }.__update(body_txt)
        {
          size = [pw(15), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXT
          text = secondsToStringLoc(replayInfo?.total_play_time ?? 0)
        }.__update(body_txt)
        mkProtocolBlock(isValidProtocol)
      ]
    }
  }
}

let mkReplayScroll = makeVertScroll(function() {
  let dasNetVersion = get_dasevent_net_version()
  let sliceFrom = curPage.value * displayPerPage
  let sliceTo = (curPage.value * displayPerPage) + displayPerPage
  return {
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
    children = records.value.slice(sliceFrom, sliceTo).map(@(v, k) mkReplay(v, k, dasNetVersion))
  }
})

let mkReplayControl = @() {
  watch = [curPage, totalPages, currentRecord]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    textButton(loc("page/prev"), @() curPage( curPage.value - 1 ), { isEnabled = curPage.value > 0 })
    textButton(loc("page/next"), @() curPage( curPage.value + 1 ), { isEnabled = (curPage.value + 1) < totalPages.value })
    currentRecord.value ? textButton(loc("replay/Watch"), watchCurrentReplay, { gap=hdpx(10) }) : null
  ]
}

return {
  size = [fsh(100), flex()]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  onAttach = @() records(getFiles())
  children = [
    mkReplayScroll
    mkReplayControl
  ]
}
