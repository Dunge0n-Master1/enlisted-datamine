from "%enlSqGlob/ui_library.nut" import *

let {copy_to_clipboard} = require("dagor.clipboard")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { tostring_r, utf8ToLower } = require("%sqstd/string.nut")
let { startswith, endswith } = require("string")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let textInput = require("%ui/components/textInput.nut")

let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let wndWidth = sw(80)

let gap = hdpx(5)
let defaultColor = 0xFFA0A0A0
let defFilterText = mkWatched(persist, "filterText", "")

let function tabButton(text, idx, curTab){
  let stateFlags = Watched(0)
  return function(){
    let isSelected = curTab.value == idx
    let sf = stateFlags.value
    return {
      children = {
        rendObj = ROBJ_TEXT
        text
        color = isSelected ? Color(255,255,255) : defaultColor
      }.__update(sub_txt)
      behavior = Behaviors.Button
      onClick = @() curTab(idx)
      onElemState = @(s) stateFlags(s)
      watch = [stateFlags, curTab]
      padding = [hdpx(5),hdpx(10)]
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? Color(200,200,200) : isSelected ? Color(0,0,0,0) : Color(0,0,0)
      borderColor = Color(200,200,200)
      borderWidth = isSelected ? [hdpx(1), hdpx(1), 0, hdpx(1)] : [0,0, hdpx(1), 0]
    }
  }
}
let hGap = freeze({rendObj = ROBJ_SOLID size = [hdpx(1), hdpx(10)] vplace = ALIGN_CENTER color = Color(40,40,40,40)})
let mkTabs = @(tabs, curTab) @() {
  watch = curTab
  children = wrap(
    tabs.map(@(_, idx) tabButton(tabs[idx].id, idx, curTab)),
    {
      width = wndWidth - gap - hdpx(250), //editbox width
      vGap = gap
      hGap
    })
}

let textArea = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  color = defaultColor
  rendObj=ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  preformatted = FMT_AS_IS //FMT_KEEP_SPACES
  text
}.__update(sub_txt)

let dataToText = @(data) tostring_r(data, { maxdeeplevel = 10, compact = false })

let function defaultRowFilter(rowData, rowKey, txt) {
  if (txt == "")
    return true
  if (startswith(txt, "\"") && endswith(txt, "\""))
    return txt.slice(1,-1) == rowKey.tostring()
  else if (startswith(txt, "\""))
    return startswith(rowKey.tostring(), txt.slice(1))
  else if (endswith(txt, "\""))
    return endswith(rowKey.tostring(), txt.slice(0,-1))

  if (utf8ToLower(rowKey.tostring()).contains(txt))
    return true
  if (rowData == null)
    return false
  let dataType = type(rowData)
  if (dataType == "array" || dataType == "table") {
    foreach (key, value in rowData)
      if (defaultRowFilter(value, key, txt))
        return true
    return false
  }
  return utf8ToLower(rowData.tostring()).indexof(txt) != null
}

let function filterData(data, curLevel, filterLevel, rowFilter, countLeft) {
  let isArray = type(data) == "array"
  if (!isArray && type(data) != "table")
    return rowFilter(data, "") ? data : null

  let res = isArray ? [] : {}
  foreach (key, rowData in data) {
    local curData = rowData
    if (filterLevel <= curLevel) {
      let isVisible = countLeft.value >= 0 && rowFilter(rowData, key)
      if (!isVisible)
        continue
      countLeft(countLeft.value - 1)
      if (countLeft.value < 0)
        break
    }
    else {
      curData = filterData(rowData, curLevel + 1, filterLevel, rowFilter, countLeft)
      if (curData == null)
        continue
    }

    if (isArray)
      res.append(curData)
    else
      res[key] <- curData
    if (countLeft.value < 0)
      break
    continue
  }
  return (curLevel == 0 || res.len() > 0) ? res : null
}

let mkFilter = @(rowFilterBase, filterArr) filterArr.len() == 0 ? @(_rowData, _key) true
  : function(rowData, key) {
      foreach (anyList in filterArr) {
        local res = true
        foreach (andText in anyList)
          if (!rowFilterBase(rowData, key, andText)) {
            res = false
            break
          }
        if (res)
          return true
      }
      return false
    }

local mkInfoBlockKey = 0
let function mkInfoBlock(curTabIdx, tabs, filterText) {
  let curTabV = tabs?[curTabIdx]
  let dataWatch = curTabV?.data
  let textWatch = Watched("")
  let recalcText = function() {
    let filterArr = utf8ToLower(filterText.value).split("||").map(@(v) v.split("&&"))
    let rowFilterBase = curTabV?.rowFilter ?? defaultRowFilter
    let rowFilter = mkFilter(rowFilterBase, filterArr)
    let countLeft = Watched(curTabV?.maxItems ?? 100)
    let resData = filterData(dataWatch?.value, 0, curTabV?.recursionLevel ?? 0, rowFilter, countLeft)
    local resText = dataToText(resData)
    if (countLeft.value < 0)
      resText = $"{resText}\n...... has more items ......"
    textWatch(resText)
  }

  let function timerRestart(_) {
    gui_scene.clearTimer(recalcText)
    gui_scene.setTimeout(0.8, recalcText)
  }
  filterText.subscribe(timerRestart)

  mkInfoBlockKey++
  let function copytoCb() {
    log_for_user("copied to clipboard")
    copy_to_clipboard(textWatch.value)
  }
  return @() {
    watch = [textWatch]
    key = mkInfoBlockKey
    size = [flex(), SIZE_TO_CONTENT]
    children = textArea(textWatch.value)
    hotkeys = [["L.Ctrl C", {action = copytoCb}]]
    onAttach = recalcText
    function onDetach() {
      gui_scene.clearTimer(recalcText)
      filterText.unsubscribe(timerRestart)
    }
  }
}

let mkCurInfo = @(curTab, tabs, filterText) @() {
  watch = curTab
  size = [flex(), SIZE_TO_CONTENT]
  children = mkInfoBlock(curTab.value, tabs, filterText)
}

let debugShopWnd = @(tabs, curTab, filterText) {
  size = [wndWidth + 2 * gap, sh(90)]
  stopMouse = true
  padding = gap
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = Color(30,30,30,120)
  flow = FLOW_VERTICAL
  gap = gap

  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      children = [
        mkTabs(tabs, curTab)
        textInput(filterText, {
          placeholder = "filter..."
          textmargin = hdpx(5)
          margin = 0
          onChange = @(value) filterText(value)
          onEscape = @() filterText("")
        }.__update(sub_txt))
      ]
    }
    makeVertScroll(mkCurInfo(curTab, tabs, filterText))
  ]
}

let function openDebugWnd(tabs, wndUid = "debugWnd", filterText = defFilterText) {
  let curTab = Watched(0)
  let close = @() removeModalWindow(wndUid)

  addModalWindow({
    key = wndUid
    size = [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = Color(0,0,0,220)
    onClick = close
    children = debugShopWnd(tabs, curTab, filterText)
    hotkeys = [["^J:B | Esc", { action = close, description = loc("Cancel") }]]
  })
}

return {
  openDebugWnd = kwarg(openDebugWnd)
  defaultRowFilter
}