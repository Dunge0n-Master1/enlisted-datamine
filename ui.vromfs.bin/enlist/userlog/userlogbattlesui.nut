from "%enlSqGlob/ui_library.nut" import *

let { battlesUserLogs, UserLogType } = require("userLogState.nut")
let { bigPadding, defTxtColor, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { mkUserLogHeader, mkRowText, rowStyle, userLogStyle, userLogRowStyle, borderColor
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

let mkBattleLog = @(uLog, isSelected) {
  children = [
    mkUserLogHeader(isSelected, uLog.logTime,
      loc("userLog/battle", {
        result = loc(battleResLoc[uLog?.value ?? 0])
        missionName = loc(uLog.missionId)
      }))
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
    onClick = @() selectedIdx(idx)
    borderColor = borderColor(sf, isSelected.value)
    borderWidth = hdpx(1)
    children = mkBattleLog(uLog, isSelected.value)
  })
}

return @() {
  watch = battlesUserLogs
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = battlesUserLogs.value.map(mkLog)
}
