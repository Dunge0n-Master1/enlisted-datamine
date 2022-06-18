from "%enlSqGlob/ui_library.nut" import *

let { battlesUserLogs, userLogRows } = require("userLogState.nut")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { mkBattleLog, borderColor } = require("userLogPkg.nut")


let selectedIdx = Watched(0)

return @() {
  watch = [battlesUserLogs, userLogRows, selectedIdx]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = battlesUserLogs.value.map(function(uLog, idx) {
    let uLogRows = selectedIdx.value != idx ? []
      : userLogRows.value?[uLog.guid] ?? []
    return watchElemState(@(sf) {
      rendObj = ROBJ_BOX
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      onClick = @() selectedIdx(idx)
      borderColor = borderColor(sf, uLogRows.len() > 0)
      borderWidth = hdpx(1)
      children = mkBattleLog(uLog, uLogRows)
    })
  })
}
