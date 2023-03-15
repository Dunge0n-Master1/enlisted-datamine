from "%enlSqGlob/ui_library.nut" import *
from "eventRoomsListState.nut" import *

let { format } = require("string")
let { unixtime_to_local_timetbl } = require("dagor.time")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, rowBg, bigPadding, commonBtnHeight, titleTxtColor, activeTxtColor, isWide,
  accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80) })
let exclamation = require("%enlist/components/exclamation.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { txt, smallCampaignIcon, lockIcon, iconPreparingBattle, iconInBattle, iconMod
} = require("roomsPkg.nut")
let getPlayersCountInRoomText = require("getPlayersCountInRoomText.nut")
let { lockIconSize } = require("eventModeStyle.nut")
let { joinSelEventRoom } = require("joinEventRoom.nut")
let faComp = require("%ui/components/faComp.nut")
let { featuredModsRoomsList } = require("sandbox/customMissionOfferState.nut")
let { soundDefault } = require("%ui/components/textButton.nut")
let { secondsToStringLoc } = require("%ui/helpers/time.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")


let rowHeight = hdpx(28)
const IN_BATTLE = "launched"
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
let battleIcon = withTooltip(iconInBattle, @() loc("memberStatus/inBattle"))
let preparationIcon = withTooltip(iconPreparingBattle, @() loc("lobby/preparationBattle"))
let modIcon = withTooltip(iconMod, @() loc("mods/roomDescription"))

let creatorColumnWidth  = flex(0.8)
let campaignColumnWidth = flex(0.5)
let playersColumnWidth  = isWide ? flex(0.3) : flex(0.2)
let gameModeColumnWidth = isWide ? flex(2)   : flex(0.9)
let statusColumnWidth = flex(0.6)
let batlleTimeWidth = hdpx(90)

let columnsTable = {
  campaigns = {
    cell = @(r) {
      size = [campaignColumnWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = r?.campaigns.map(@(campaign)
        withTooltip(smallCampaignIcon(campaign), @() loc(campaign)))
    }
    label = loc("options/campaigns")
    width = campaignColumnWidth
    sortFunc = @(a, b) (b?.campaigns ?? []).len() <=> (a?.campaigns ?? []).len()
      || (a?.campaign ?? "") <=> (b?.campaign ?? "")
  }
  creator = {
    cell = @(r) txt(remap_others(r?.creator ?? ""), creatorColumnWidth)
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
    cell = function(r) {
      let { launcherState = null, cTime = 0, timeInBattle = 0 } = r
      let isLobbyLaunched = launcherState == IN_BATTLE
      let isLobbyLaunching = launcherState == "launching"
      let tm = unixtime_to_local_timetbl(cTime)
      return {
        size = [statusColumnWidth, SIZE_TO_CONTENT]
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          isLobbyLaunched || isLobbyLaunching ? battleIcon : preparationIcon
          timeInBattle > 0 && isLobbyLaunched
            ? withTooltip(txt(secondsToStringLoc(timeInBattle), batlleTimeWidth, accentTitleTxtColor),
                @() loc("looby/battleTime"))
            : txt(loc("In lobby"), batlleTimeWidth)
          withTooltip(txt(format("%02d:%02d", tm.hour, tm.min), hdpx(70)),
            @() loc("lobby/creationTime"))
        ]
      }
    }
    label = loc("lobby/status")
    width = statusColumnWidth
    defSorting = true
    sortFunc = @(a, b) ((b?.launcherState == IN_BATTLE) <=> (a?.launcherState == IN_BATTLE)
      && (b?.sessionLaunchTime ?? -1) <=> (a?.sessionLaunchTime ?? -1))
      || (b?.cTime ?? 0) <=> (a?.cTime ?? 0)
  }
  isPrivate = {
    cell = @(r) {
      size = [lockIconSize, SIZE_TO_CONTENT]
      children = r?.hasPassword != null ? withTooltip(lockIcon, @() loc("options/private")) : null
    }
    label = lockIcon
    width = lockIconSize
    sortFunc = @(a, b) (a?.hasPassword == null) <=> (b?.hasPassword == null)
  }
  isMod = {
    cell = @(r) {
      size = [lockIconSize + bigPadding, SIZE_TO_CONTENT]
      padding = [0, bigPadding, 0, 0]
      halign = ALIGN_LEFT
      hplace = ALIGN_LEFT
      children = r?.scene == null ? modIcon : null
    }
    label = ""
    width = lockIconSize + bigPadding
    sortFunc = @(a, b) (a?.scene == null) <=> (b?.scene == null)
  }
}

foreach (id, column in columnsTable) {
  columnsTable[id].name <- id
  if (column?.defSorting)
    curSorting({column, isReverse = false})
}

let columns = ["status", "creator", "mode", "campaigns", "players", "isMod", "isPrivate"]

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
  valign = ALIGN_CENTER
  children = [
    type(column.label) != "string" ? column.label : {
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