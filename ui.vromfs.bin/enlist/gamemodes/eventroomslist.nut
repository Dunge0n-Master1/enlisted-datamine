from "%enlSqGlob/ui_library.nut" import *
from "eventRoomsListState.nut" import *

let { format } = require("string")
let { unixtime_to_local_timetbl } = require("dagor.time")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  defTxtColor, rowBg, bigPadding, commonBtnHeight, titleTxtColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80) })
let exclamation = require("%enlist/components/exclamation.nut")
let { makeVertScroll } = require("%darg/components/scrollbar.nut")
let {
  txt, smallCampaignIcon, lockIcon, iconPreparingBattle, iconInBattle, iconMod
} = require("roomsPkg.nut")
let getPlayersCountInRoomText = require("getPlayersCountInRoomText.nut")
let { lockIconSize } = require("eventModeStyle.nut")
let { joinSelEventRoom } = require("joinEventRoom.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")
let faComp = require("%ui/components/faComp.nut")
let { setTooltip } = require("%ui/style/cursors.nut")

let rowHeight = hdpx(28)

let emptyRoomsInfo = @() {
  watch = [roomsListError, isRequestInProgress]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    exclamation(roomsListError.value != null ? loc($"error/{roomsListError.value}")
      : loc("noRoomsFound"))
    isRequestInProgress.value ? spinner : { size = [0, hdpx(80)] }
  ]
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, easing = InCubic, duration = 0.5, play = true }]
}

let isFull = @(room) (room?.membersCnt ?? 0) >= (room?.maxPlayers ?? 0)

let columnsTable = {
  campaigns = {
    cell = @(r) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = r?.campaigns.map(@(campaign) smallCampaignIcon(campaign))
    }
    label = loc("options/campaigns")
    width = flex()
  }
  cTime = {
    cell = function(r) {
      let tm = unixtime_to_local_timetbl(r?.cTime ?? 0)
      return txt(format("%02d:%02d", tm.hour, tm.min), hdpx(60))
    }
    label = ""
    width = hdpx(60)
  }
  creator = {
    cell = @(r) txt(remap_nick(r?.creator ?? "???"), flex(1.5))
    label = loc("Creator")
    width = flex(1.5)
    sortFunc = @(a, b) remap_nick(a?.creator ?? "") <=> remap_nick(b?.creator ?? "")
  }
  players = {
    cell = @(r) txt(getPlayersCountInRoomText(r), flex(0.5))
    label = loc("Players")
    width = flex(0.5)
    defSorting = true
    sortFunc = @(a, b) isFull(b) <=> isFull(a) || (b?.membersCnt ?? 0) <=> (a?.membersCnt ?? 0)
  }
  mode = {
    cell = @(r) txt(loc(r.mode ?? ""))
    label = loc("current_mode")
    width = flex()
    sortFunc = @(a, b) loc(a.mode ?? "") <=> loc(b.mode ?? "")
  }
  status = {
    cell = @(r) {
      size = [lockIconSize + bigPadding, SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = (r?.launcherState ?? "") == "launching" || (r?.launcherState ?? "") == "launched"
        ? iconInBattle
        : iconPreparingBattle
    }
    label = ""
    width = lockIconSize + bigPadding
  }
  isPrivate = {
    cell = @(r) {
      size = [lockIconSize + bigPadding, SIZE_TO_CONTENT]
      padding = [0, bigPadding, 0, 0]
      halign = ALIGN_LEFT
      hplace = ALIGN_LEFT
      children = r?.isPrivate
        ? lockIcon.__merge({
            halign = ALIGN_LEFT
            hplace = ALIGN_LEFT
          })
        : null
    }
    label = ""
    width = lockIconSize + bigPadding
  }
  isMod = {
    cell = @(r) watchElemState(@(_sf){
      size = [lockIconSize + bigPadding, SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(on ? loc("mods/roomDescription") : null)
      padding = [0, bigPadding, 0, 0]
      halign = ALIGN_LEFT
      hplace = ALIGN_LEFT
      children = r?.scene == null ? iconMod : null
    })
    label = ""
    width = lockIconSize + bigPadding
  }
}

foreach (id, column in columnsTable) {
  columnsTable[id].name <- id
  if (column?.defSorting)
    curSorting({column, isReverse = false})
}

let columns = ["status", "isPrivate", "cTime", "creator", "mode", "campaigns", "players", "isMod"]

let mkRoomRow = @(room, idx, isSelected) watchElemState(@(sf) {
  size = [flex(), rowHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  padding = [0, bigPadding]
  rendObj = ROBJ_SOLID
  color = rowBg(sf, idx, isSelected)
  children = columns.map(@(ctor) columnsTable[ctor].cell(room))

  behavior = Behaviors.Button
  onClick = @() selectRoom(room.roomId)
  onDoubleClick = joinSelEventRoom
  sound = {
    click  = "ui/enlist/button_click"
    hover  = "ui/enlist/button_highlight"
  }
})

let cellHeaderColor = @(sf, col) curSorting.value.column == col ? titleTxtColor
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

let headerTxt = @(column) watchElemState(@(sf) {
  size = [column.width, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  behavior = column?.sortFunc ? Behaviors.Button : null
  onClick = @() curSorting.value.column == column
        ? curSorting.mutate(@(val) val.isReverse = !val.isReverse)
        : curSorting({column, isReverse = false})

  children = [{
      rendObj = ROBJ_TEXT
      color = cellHeaderColor(sf, column)
      text = column.label
    }.__update(body_txt)
    curSorting.value.column == column
      ? faComp(curSorting.value.isReverse? "caret-up" : "caret-down", {
          color = cellHeaderColor(sf, column)
          padding = [0, 0, 0, hdpx(5)]
          fontSize = body_txt.fontSize
          valign = ALIGN_CENTER
        })
      : null
  ]
})


let eventRoomsListHeaderRow = @(columns){
  size = [flex(), commonBtnHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = bigPadding
  color = Color(0,0,0)
  children = columns.map(@(column) headerTxt(columnsTable[column]))
}

let scrollHandler = ScrollHandler()

let eventRoomsList = @() {
  watch = [roomsList, selRoom, curSorting]
  flow = FLOW_VERTICAL
  size = flex()
  onAttach = @() isRefreshEnabled(true)
  onDetach = @() isRefreshEnabled(false)
  children = roomsList.value.len() == 0
    ? emptyRoomsInfo
    : [
        eventRoomsListHeaderRow(columns)
        makeVertScroll({
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children = roomsList.value.map(@(r, i) mkRoomRow(r, i, r == selRoom.value))
        },
        {
          needReservePlace = false
          scrollHandler
        })
      ]
}

return eventRoomsList