from "%enlSqGlob/ui_library.nut" import *

let { body_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { rowBg, bigPadding, blockedTxtColor, defTxtColor, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let { currentRecord, replayPlay, deleteReplay, records, updateReplays,
 defaultRecordFolder
} = require("%enlist/replay/replaySettings.nut")
let { format_unix_time } = require("dagor.iso8601")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { shell_execute } = require("dagor.shell")
let { ceil } = require("%sqstd/math.nut")
let { is_pc } = require("%dngscripts/platform.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let textButton = require("%ui/components/textButton.nut")
let msgbox = require("%ui/components/msgbox.nut")
let openUrl = require("%ui/components/openUrl.nut")

const REPLAY_URL = "https://enlisted.net/replays"

let displayPerPage = 11
let maxListHeight = (displayPerPage + 1) * commonBtnHeight
let curPage = Watched(0)
let listGap = hdpx(20)
let buttonsGap = hdpx(16)
let listPadding = [0, listGap]
let isCurrentRecordProtocolValid = Watched(true)
let totalPages = Computed(@() ceil(records.value.len().tofloat() / displayPerPage).tointeger())

let defTxtStyle = { color = defTxtColor }.__update(body_txt)
let disabledTxtStyle = { color = blockedTxtColor }.__update(body_txt)

records.subscribe(function(_) {
  if (totalPages.value < curPage.value)
    curPage(totalPages.value)
})

let mkProtocolBlock = @(isValid) {
  size = [flex(1.5), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  text = isValid ? loc("replay/readyToPlay") : loc("replay/protocolMisMatch")
}.__update(isValid ? defTxtStyle : disabledTxtStyle)

let listHeader = [
  {
    locId = loc("replay/recordDate")
    size = flex()
  }
  {
    locId = loc("replay/mission")
    size = [flex(1.5), flex()]
  }
  {
    locId = loc("replay/gameTime")
    size = [flex(0.5), flex()]
  }
  {
    locId = loc("replay/availabilityStatus")
    size = [flex(1.5), flex()]
  }
]

let headerRow = {
  size = [flex(), commonBtnHeight]
  flow = FLOW_HORIZONTAL
  padding = listPadding
  gap = listGap
  children = listHeader.map(@(tab) {
    size = tab.size
    rendObj = ROBJ_TEXT
    text = tab.locId
  }.__update(defTxtStyle))
}

let function mkReplay(record, idx) {
  let replayInfo = record.recordInfo
  if (!replayInfo)
    return null

  let { isValid } = record
  return watchElemState(@(sf) {
    watch = currentRecord
    size = [flex(), commonBtnHeight]
    rendObj = ROBJ_SOLID
    flow = FLOW_HORIZONTAL
    gap = listGap
    padding = listPadding
    valign = ALIGN_CENTER
    xmbNode = XmbNode()
    behavior = Behaviors.Button
    color = rowBg(sf, idx, record.id == (currentRecord.value?.id ?? ""))
    onClick = function() {
      currentRecord(record)
      isCurrentRecordProtocolValid(isValid)
    }
    children = [
      {
        rendObj = ROBJ_TEXT
        size = [flex(), SIZE_TO_CONTENT]
        text = format_unix_time(replayInfo?.start_timestamp ?? 0)
          .replace("T", " ").replace("Z", "")
      }.__update(body_txt)
      {
        rendObj = ROBJ_TEXT
        size = [flex(1.5), SIZE_TO_CONTENT]
        behavior = Behaviors.Marquee
        text = loc(replayInfo?.mission_name ?? "replay/UnknownMission",
          { mission_type=loc($"missionType/{replayInfo?.mission_type}" ?? "unknownMissionType") })
      }.__update(body_txt)
      {
        size = [flex(0.5), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        text = secondsToStringLoc(replayInfo?.total_play_time ?? 0)
      }.__update(body_txt)
      mkProtocolBlock(isValid)
    ]
  })
}

let emptyReplayBlock = {
  rendObj = ROBJ_TEXT
  text = loc("replay/emptyList")
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}.__update(defTxtStyle)

let function mkReplayList() {
  let sliceFrom = curPage.value * displayPerPage
  let sliceTo = (curPage.value * displayPerPage) + displayPerPage
  let recordsToShow = records.value
    .sort(@(a, b) b.isValid <=> a.isValid || (b.recordInfo?.start_timestamp ?? 0) <=> (a.recordInfo?.start_timestamp ?? 0))
  let hasAnyReplay = records.value.len() > 0
  return {
    watch = [records, curPage]
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = maxListHeight
    onAttach = updateReplays
    flow = FLOW_VERTICAL
    children = !hasAnyReplay ? emptyReplayBlock
      : [headerRow].extend(recordsToShow.slice(sliceFrom, sliceTo).map(@(v, k) mkReplay(v, k)))
  }}

let deleteReplayMsgbox = @() msgbox.show({
  text = loc("replay/deleteApprove"),
  buttons = [
    {
      text = loc("Yes")
      action = @() deleteReplay(currentRecord.value.id)
      isCurrent = true
    },
    {
      text = loc("No")
      isCancel = true
    }
  ]
})


let curPageInfo = @() {
  watch = [totalPages, curPage]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = totalPages.value <= 1 ? ""
    : loc("replay/page", { curPage = curPage.value + 1, totalPages = totalPages.value })
}.__update(defTxtStyle)

let iconParam = {
  hplace = ALIGN_CENTER
  margin = bigPadding
  size = [hdpx(35),hdpx(35)]
  fontSize = hdpx(35)
  font = fontawesome.font
}

let mkReplayControl = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = { size = [flex(), 0]}
  children = [
    {
      flow = FLOW_VERTICAL
      gap = buttonsGap
      children = [
        @() {
          watch = [totalPages, curPage]
          flow = FLOW_HORIZONTAL
          gap = buttonsGap
          children = [
            textButton(loc("page/prev"), @() curPage( curPage.value - 1 ),
              {
                isEnabled = curPage.value > 0
                margin = 0
                hotkeys = totalPages.value > 0 ? [["^J:LT"]] : null
              })
            textButton(loc("page/next"), @() curPage( curPage.value + 1 ),
              {
                isEnabled = (curPage.value + 1) < totalPages.value
                margin = 0
                hotkeys = totalPages.value > 0 ? [["^J:RT"]] : null
              })
          ]
        }
        {
          flow = FLOW_HORIZONTAL
          gap = buttonsGap
          children = [
            is_pc ? textButton("", @() shell_execute({cmd="explore", dir=defaultRecordFolder}), {
              margin = 0
              children = [
                txt({ text = fa["folder-open"] }).__merge(iconParam)
              ]
            }) : null
            textButton(loc("replay/replaysOnSite"), @() openUrl(REPLAY_URL), {
              margin = 0
            })
          ]
        }
      ]
    }
    @() {
      watch = currentRecord
      flow = FLOW_HORIZONTAL
      gap = buttonsGap
      children = [
        textButton(loc("replay/delete"), deleteReplayMsgbox,
          {
            isEnabled = currentRecord.value != null
            margin = 0
            hotkeys = [["^J:X"]]
          })
        textButton(loc("replay/Watch"), @() replayPlay(currentRecord.value.id),
          {
            isEnabled = currentRecord.value != null
            margin = 0
            hotkeys = [["^J:Y"]]
          })
      ]
    }
  ]
}

return {
  size = flex()
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = { size = flex() }
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        mkReplayList
        curPageInfo
      ]
    }
    mkReplayControl
  ]
}
