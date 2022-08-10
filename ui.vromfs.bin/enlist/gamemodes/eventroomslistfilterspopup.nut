from "%enlSqGlob/ui_library.nut" import *
from "eventRoomsListFilter.nut" import *
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, smallPadding, defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { localGap } = require("eventModeStyle.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let mkOptionRow = require("components/mkOptionRow.nut")
let faComp = require("%ui/components/faComp.nut")
let { isModAvailable } = require("sandbox/customMissionState.nut")

let WND_UID = "eventFiltersPopup"
let isRoomFilterOpened = Watched(false)
let columnWidth = hdpx(440)
let rowHeight = hdpx(38)
let locOn = loc($"option/on")
let locOff = loc($"option/off")

let OPTS_LIST = "opts_list"

let modsFilter = {
  optType = OPTS_LIST
  innerOption = optModRooms
}

let roomsCheckboxBlock = [
  {
    locId = "rooms/Rooms"
    optType = OPTS_LIST
    innerOption = optFullRooms
  }
  {
    optType = OPTS_LIST
    innerOption = optPasswordRooms
  }
].append(isModAvailable.value ? modsFilter : null )

let columns = [
  [ optMode, optDifficulty ].extend(roomsCheckboxBlock),
  [ optCampaigns ],
  [ optCluster, optCrossplay ]
]

let widthPopup = columnWidth*columns.len()

let bTxt = @(text) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(body_txt)

let mkBlock = @(headerText, children) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    headerText == null ? null :{
      size = [flex(), rowHeight]
      valign = ALIGN_BOTTOM
      padding = [0, bigPadding, smallPadding, bigPadding]
      rendObj = ROBJ_TEXT
      color = 0xFF808080
      text = headerText
    }.__update(sub_txt)
    children
  ]
}

let mkCheckIcon = @(watched) @() {
  watch = watched
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = watched.value ? faComp("check", {valign = ALIGN_CENTER}) : null
}

let mkCheckCircleIcon = @(v) {
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#{v ? "on" : "off"}_radiobutton.svg")
}

let mkCircleCheck = @(watched) @() {
  watch = watched
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  padding = [bigPadding, 0]
  gap = hdpx(5)
  children = [
    bTxt(locOn)
    mkCheckCircleIcon(watched.value)
    { size = [bigPadding, flex()]}
    bTxt(locOff)
    mkCheckCircleIcon(!watched.value)
  ]
}

let function mkCheckbox(opt) {
  let { locId, curValue, setValue } = opt
  return mkOptionRow(
    loc(locId),
    mkCircleCheck(curValue),
    {
      onClick = @() setValue(!curValue.value)
      size = [flex(), rowHeight]
    }
  )
}

let mkSelectOption = @(opt) function () {
  let { locId, curValues, allValues, valToString = @(v) v, action } = opt
  let res = { watch = allValues }
  if (allValues.value == null || allValues.value.len() <= 1)
    return res

  let children = allValues.value.map(function (value) {
    let isChecked = Computed(@() curValues.value.contains(value))
    return mkOptionRow(
      loc(valToString(value)),
      mkCheckIcon(isChecked),
      {
        onClick = @() action(value)
        gap = null
        size = [flex(), rowHeight]
      }
    )
  })

  return res.__update({
    watch = allValues
    size = [flex(), SIZE_TO_CONTENT]
    children = mkBlock(loc(locId),
      {
        flow = FLOW_VERTICAL
        size = [flex(), SIZE_TO_CONTENT]
        children = children
      }
    )
  })
}

let mkSelectSingle = @(opt) mkSelectOption(opt.__merge({
  action = @(value) opt?.setValue([value])
}))

let mkSelectMultiple = @(opt) mkSelectOption(opt.__merge({
  action = function (value) {
    let { toggleValue, curValues } = opt
    toggleValue(value, !curValues.value.contains(value))
  }
}))

let function mkOptsList(opt) {
  return mkBlock(
    loc(opt?.locId),
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = mkCheckbox(opt.innerOption)
    }
  )
}

let function mkRow(option) {
  let { optType = null } = option
  if (optType == null)
    return null
  let ctor = {
    [OPTS_LIST] = mkOptsList,
    [OPT_RADIO] = mkSelectSingle,
    [OPT_MULTISELECT] = mkSelectMultiple
  }?[optType]

  return ctor?(option)
}


let mkColumn = @(rows) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = rows.map(mkRow)
}

let content = {
    size = [widthPopup, SIZE_TO_CONTENT]
    padding = [0, bigPadding, bigPadding, bigPadding]
    stopMouse = true
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = columns.map(mkColumn)
  }

let openEventFiltersPopup = @(event)
  modalPopupWnd.add(event.targetRect, {
    uid = WND_UID
    children = content
    popupOffset = localGap
    popupHalign = ALIGN_LEFT
    onAttach = @() isRoomFilterOpened(true)
    onDetach = @() isRoomFilterOpened(false)
  })

return {
  openEventFiltersPopup
  closeEventFiltersPopup = @() modalPopupWnd.remove(WND_UID)
  isRoomFilterOpened
}