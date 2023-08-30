from "%enlSqGlob/ui_library.nut" import *

let { battlesUserLogs, UserLogType } = require("userLogState.nut")
let { defTxtColor, smallPadding, hoverSlotBgColor, panelBgColor, selectedPanelBgColor, miniPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { mkUserLogHeader, mkRowText, rowStyle, userLogStyle, userLogRowStyle
} = require("userLogPkg.nut")
let { BattleResult } = require("%enlSqGlob/battleParams.nut")


let selectedIdx = Watched(0)

let mkArmyExpLogRow = @(row) {
  children = mkRowText(loc("listWithDot", {
    text = loc("userLogRow/armyExp", {
      army = loc(row.armyId)
      exp = row.count
    })
  }), defTxtColor)
}.__update(rowStyle, { gap = smallPadding })

let mkActivityLogRow = @(row) {
  children = mkRowText(loc("listWithDot", {
    text = loc("userLogRow/battleActivity", {
      activity = row.count
    })
  }), defTxtColor)
}.__update(rowStyle, { gap = smallPadding })

let battleRowView = {
  [UserLogType.BATTLE_ARMY_EXP] = mkArmyExpLogRow,
  [UserLogType.BATTLE_ACTIVITY] = mkActivityLogRow
}

let mkBattleLogRows = @(uLogRows) {
  children = uLogRows.map(@(row) battleRowView?[row?.logType](row))
}.__update(userLogRowStyle)

let battleResLoc = {
  [BattleResult.DESERTION] = "userLog/battleRes/deserter",
  [BattleResult.WIN] = "userLog/battleRes/victory",
  [BattleResult.DEFEAT] = "userLog/battleRes/defeat"
}

let mkBattleLog = @(uLog, isSelected, sf) {
  children = [
    mkUserLogHeader(isSelected, uLog.logTime,
      loc("userLog/battle", {
        result = loc(battleResLoc[uLog?.value ?? 0])
        missionName = loc(uLog.missionId, {mission_type = ""}).replace(" ()","")//fixme! should have mission type
      }), sf)
    isSelected && uLog?.rows ? mkBattleLogRows(uLog.rows) : null
  ]
}.__update(userLogStyle)

let function mkLog(uLog, idx) {
  let isSelected = Computed(@() idx == selectedIdx.value)
  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    watch = isSelected
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    onClick = @() selectedIdx(idx)
    fillColor = sf & S_HOVER ? hoverSlotBgColor
      : isSelected.value ? selectedPanelBgColor
      : panelBgColor
    children = mkBattleLog(uLog, isSelected.value, sf)
  })
}

return @() {
  watch = battlesUserLogs
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  xmbNode = XmbContainer({
    canFocus = false
    wrap = false
    scrollSpeed = 10.0
    isViewport = true
  })
  gap = miniPadding
  children = battlesUserLogs.value.map(mkLog)
}
