from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let {
  vehicles, squadsWithVehicles, viewVehicle, selectVehicle, selectVehParams, curSquadId, setCurSquadId,
  CAN_USE, CANT_USE, vehicleClear
} = require("vehiclesListState.nut")
let { getSquadConfig } = require("%enlist/soldiers/model/state.nut")
let {
  smallPadding, bigPadding, blurBgColor, blurBgFillColor, vehicleListCardSize, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let scrollbar = require("%darg/components/scrollbar.nut")
let vehiclesListCard = require("vehiclesListCard.ui.nut")
let vehicleDetails = require("vehicleDetails.ui.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let mkHeader = require("%enlist/components/mkHeader.nut")
let mkToggleHeader = require("%enlist/components/mkToggleHeader.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let { isDmViewerEnabled, onDmViewerMouseMove, dmViewerPanelUi } = require("%enlist/vehicles/dmViewer.nut")
let freemiumPromo  = require("%enlist/currency/pkgFreemiumWidgets.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")


let showNotAvailable = Watched(false)
selectVehParams.subscribe(@(_) showNotAvailable(false))

let function createSquadHandlers(squads) {
  squads.each(@(squad)
    squad.__update({
      onClick = @() setCurSquadId(squad.squadId)
      isSelected = Computed(@() curSquadId.value == squad.squadId)
    })
  )
}

let notAvailableHeader = mkToggleHeader(showNotAvailable, loc("header/notAvailableVehicles"))

let sortByStatus = @(a, b) a.flags <=> b.flags
  || (a?.levelLimit ?? 0) <=> (b?.levelLimit ?? 0)

let function mkStatusHeader(status) {
  let { statusTextShort = null, statusText = null } = status
  let text = statusTextShort ?? statusText
  return text == null ? null
    : {
        rendObj = ROBJ_TEXT
        size = [flex(), SIZE_TO_CONTENT]
        margin = [smallPadding, 0, 0, 0]
        text
        color = defTxtColor
      }.__update(sub_txt)
}

let function groupByStatus(itemsList) {
  let groupedItems = {}
  foreach (item in itemsList) {
    let { status } = item
    groupedItems[status] <- (groupedItems?[status] ?? []).append(item)
  }
  let children = []
  let statusOrdered = groupedItems.keys().sort(sortByStatus)
  foreach (status in statusOrdered) {
    if (status.flags != CAN_USE)
      children.append(mkStatusHeader(status))
    foreach (item in groupedItems[status])
      children.append(vehiclesListCard({
        item = item
        onClick = @(item) viewVehicle(item)
        onDoubleClick = @(item) selectVehicle(item)
      }))
  }
  return children
}

let function vehiclesList() {
  let children = groupByStatus(vehicles.value.filter(@(v) (v.status.flags & CANT_USE) == 0))
  let unavailable = vehicles.value.filter(@(v) (v.status.flags & CANT_USE) != 0)
  if (unavailable.len() > 0) {
    children.append(notAvailableHeader)
    if (showNotAvailable.value)
      children.extend(groupByStatus(unavailable))
  }
  return {
    watch = [vehicles, showNotAvailable]
    size = [vehicleListCardSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = children
  }
}

let vehiclesBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = bigPadding
  flow = FLOW_VERTICAL
  children = scrollbar.makeVertScroll(vehiclesList, {
    size = [SIZE_TO_CONTENT, flex()]
    needReservePlace = false
  })
}

let function mkSquadName(squadId, armyId) {
  let squadConfig = getSquadConfig(squadId, armyId)
  return squadConfig != null
    ? txt(loc(squadConfig?.titleLocId ?? ""))
    : null
}

let selectVehicleContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    @() {
      watch = selectVehParams
      children = mkSquadName(selectVehParams.value?.squadId, selectVehParams.value?.armyId)
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding

      behavior = Behaviors.MenuCameraControl

      children = [
        mkCurSquadsList({
          curSquadsList = squadsWithVehicles
          curSquadId
          setCurSquadId
          createHandlers = createSquadHandlers
        })
        vehiclesBlock
        {
          size = flex()
          children = dmViewerPanelUi
        }
        {
          size = [SIZE_TO_CONTENT, flex()]
          halign = ALIGN_RIGHT
          children = [
            @() {
              watch = needFreemiumStatus
              children = !needFreemiumStatus.value ? null : freemiumPromo("select_vehicle", null, {
                size = [hdpx(600), SIZE_TO_CONTENT]
                rendObj = ROBJ_WORLD_BLUR_PANEL
                hplace = ALIGN_RIGHT
              })
            }
            vehicleDetails
          ]
        }
      ]
    }
  ]
}

let selectVehicleScene = @() {
  watch = [safeAreaBorders, isDmViewerEnabled]
  size = [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.value
  behavior = isDmViewerEnabled.value ? Behaviors.TrackMouse : null
  onMouseMove = isDmViewerEnabled.value ? onDmViewerMouseMove : null
  children = [
    @() {
      size = [flex(), SIZE_TO_CONTENT]
      watch = selectVehParams
      children = mkHeader({
        armyId = selectVehParams.value?.armyId
        textLocId = "Choose vehicle"
        closeButton = closeBtnBase({ onClick = vehicleClear })
      })
    }
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = selectVehicleContent
    }
  ]
}

let function open() {
  sceneWithCameraAdd(selectVehicleScene, "vehicles")
}

if (selectVehParams.value?.armyId != null
    && selectVehParams.value?.squadId != null
    && !(selectVehParams.value?.isCustomMode ?? false))
  open()

selectVehParams.subscribe(function(p) {
  if (p?.armyId != null && p?.squadId != null && !(p?.isCustomMode ?? false))
    open()
  else
    sceneWithCameraRemove(selectVehicleScene)
})
