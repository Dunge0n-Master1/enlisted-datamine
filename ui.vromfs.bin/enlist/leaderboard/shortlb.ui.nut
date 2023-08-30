from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { UserNameColor } = require("%ui/style/colors.nut")
let {
  refreshLbData, curLbRequestData, curLbData, curLbErrName, curLbSelfRow,
  lbSelCategories, isRefreshLbEnabled
} = require("lbState.nut")
let { RANK, NAME } = require("lbCategory.nut")
let exclamation = require("%enlist/components/exclamation.nut")
let spinner = require("%ui/components/spinner.nut")


const MAX_LB_ROWS = 10
let rowHeight = hdpx(25)
let fullHeight = (MAX_LB_ROWS + 3) * rowHeight
let waitingSpinner = spinner()

let styleByCategory = {
  [RANK] = { halign = ALIGN_LEFT },
  [NAME] = { color = 0xFFFFFFFF, halign = ALIGN_LEFT },
}

let refreshLbOnChange = @(_) refreshLbData()

let mkLbCell = @(category, rowData) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  halign = ALIGN_RIGHT
  text = category.getText(rowData)
}.__update(
  fontSub,
  styleByCategory?[category] ?? {},
  rowData?.self ? { color = UserNameColor } : {})

let mkLbRow = @(rowData, categories) {
  size = [flex(), rowHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = categories.map(@(c) mkLbCell(c, rowData))
}

let lbHeaderRow = @(categories) {
  size = [flex(), rowHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = categories.map(@(category) {
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    halign = styleByCategory?[category].halign ?? ALIGN_RIGHT
    children = {
      rendObj = ROBJ_TEXT
      text = loc(category.locId)
      color = defTxtColor
    }.__update(fontSub)
  })
}

let dotsRow = {
  size = [flex(), rowHeight]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = "..."
}

let function shortEventLb() {
  let lbCategories = lbSelCategories.value.short
  local children = null
  local valign = ALIGN_CENTER
  if (curLbData.value == null)
    children = waitingSpinner
  else if (curLbData.value.len() == 0)
    children = exclamation(
      loc(curLbErrName.value != null ? $"error/{curLbErrName.value}" : "leaderboard/noLbData"))
  else {
    children = [lbHeaderRow(lbCategories)]
      .extend(curLbData.value
        .slice(0, MAX_LB_ROWS)
        .map(@(rowData) mkLbRow(rowData, lbCategories)))
    valign = ALIGN_TOP
    if (curLbSelfRow.value) {
      let selfRow = mkLbRow(curLbSelfRow.value, lbCategories)
      let { idx = -1 } = curLbSelfRow.value
      if (idx < 0 || idx > MAX_LB_ROWS){
        children.append(dotsRow)
        children.append(selfRow)
      }
    }
  }

  return {
    watch = [lbSelCategories, curLbData, curLbErrName, curLbSelfRow]
    size = [flex(), fullHeight]
    onAttach = function() {
      isRefreshLbEnabled(true)
      curLbRequestData.subscribe(refreshLbOnChange)
    }
    onDetach = function() {
      isRefreshLbEnabled(false)
      curLbRequestData.unsubscribe(refreshLbOnChange)
    }
    halign = ALIGN_CENTER
    valign
    flow = FLOW_VERTICAL
    children
  }
}

return shortEventLb