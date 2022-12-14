from "%enlSqGlob/ui_library.nut" import *
from "eventRoomsListState.nut" import *

let { format } = require("string")
let { unixtime_to_local_timetbl } = require("dagor.time")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  defTxtColor, rowBg, bigPadding, commonBtnHeight, titleTxtColor, activeTxtColor, isWide
} = require("%enlSqGlob/ui/viewConst.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80) })
let exclamation = require("%enlist/components/exclamation.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let {
  txt, smallCampaignIcon, lockIcon, iconPreparingBattle, iconInBattle, iconMod
} = require("roomsPkg.nut")
let getPlayersCountInRoomText = require("getPlayersCountInRoomText.nut")
let { lockIconSize } = require("eventModeStyle.nut")
let { joinSelEventRoom } = require("joinEventRoom.nut")
let faComp = require("%ui/components/faComp.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { featuredModsRoomsList } = require("sandbox/customMissionOfferState.nut")
let { soundDefault } = require("%ui/components/textButton.nut")


let rowHeight = hdpx(28)

let emptyRoomsInfo = @() {
  size = flex()
  watch = [roomsListError, isRequestInProgress]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    exclamation(roomsListError.value != null ? loc($"error/{roomsListError.value}")
      : loc("noRoomsFound"))
    isRequestInProgress.value ? spinner : { size = [0, hdpx(80)] }
  ]
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, easing = InCubic, duration = 0.5, play = true }]
}

let isFull = @(room) (room?.membersCnt ?? 0) >= (room?.maxPlayers ?? 0)

let creatorColumnWidth  = flex(0.8)
let campaignColumnWidth = flex(0.5)
let playersColumnWidth  = isWide ? flex(0.3) : flex(0.2)
let gameModeColumnWidth = isWide ? flex(2)   : flex(0.9)

let columnsTable = {
  campaigns = {
    cell = @(r) {
      size = [campaignColumnWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = r?.campaigns.map(@(campaign) smallCampaignIcon(campaign))
    }
    label = loc("options/campaigns")
    width = campaignColumnWidth
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
    cell = @(r) txt(r?.creator ?? "???", creatorColumnWidth)
    label = loc("Creator")
    width = creatorColumnWidth
    sortFunc = @(a, b) (a?.creator ?? "") <=> (b?.creator ?? "")
  }
  players = {
    cell = @(r) txt(getPlayersCountInRoomText(r), playersColumnWidth)
    label = loc("Players")
    width = playersColumnWidth
    defSorting = true
    sortFunc = @(a, b) isFull(b) <=> isFull(a) || (b?.membersCnt ?? 0) <=> (a?.membersCnt ?? 0)
  }
  mode = {
    cell = @(r) txt(r?.modName ?? loc(r.mode ?? ""), gameModeColumnWidth)
    label = loc("current_mode")
    width = gameModeColumnWidth
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
      halign = ALIGN_RIGHT
      hplace = ALIGN_LEFT
      children = r?.hasPassword ? lockIcon : null
    }
    label = ""
    width = lockIconSize + bigPadding
  }
  isMod = {
    cell = @(r) {
      size = [lockIconSize + bigPadding, SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(on ? loc("mods/roomDescription") : null)
      padding = [0, bigPadding, 0, 0]
      halign = ALIGN_LEFT
      hplace = ALIGN_LEFT
      children = r?.scene == null ? iconMod : null
    }
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
  gap = isWide ? 0 : bigPadding
  children = columns.map(@(ctor) columnsTable[ctor].cell(room))

  behavior = Behaviors.Button
  onClick = @() selectRoom(room.roomId)
  onDoubleClick = joinSelEventRoom
  sound = soundDefault
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
  gap = isWide ? 0 : bigPadding
  children = columns.map(@(column) headerTxt(columnsTable[column]))
}

let scrollHandler = ScrollHandler()

let mkRoomsList = @(list, selectedRoom, key) @() {
  watch = [list, selectedRoom]
  flow = FLOW_VERTICAL
  size = flex()
  onAttach = @() isRefreshEnabled(true)
  onDetach = @() isRefreshEnabled(false)
  key
  children = list.value.len() == 0
    ? emptyRoomsInfo
    : [
        eventRoomsListHeaderRow(columns)
        makeVertScroll({
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children = list.value.map(@(r, i) mkRoomRow(r, i, r == selectedRoom.value))
        },
        {
          needReservePlace = false
          scrollHandler
        })
      ]
}


let eventRoomsList = mkRoomsList(roomsList, selRoom, "commonLobbies")
let modsRoomsList = mkRoomsList(featuredModsRoomsList, selRoom, "modsLobbies")

return {
  eventRoomsList
  modsRoomsList
}