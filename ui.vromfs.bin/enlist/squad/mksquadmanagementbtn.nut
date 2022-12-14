from "%enlSqGlob/ui_library.nut" import *

let { openChooseSquadsWnd } = require("%enlist/soldiers/model/chooseSquadsState.nut")
let { curArmy, curSquadId } = require("%enlist/soldiers/model/state.nut")
let { unseenSquads } = require("%enlist/soldiers/model/unseenSquads.nut")
let { armySlotDiscount } = require("%enlist/shop/armySlotDiscount.nut")
let { columnWidth, colPart, defBdColor, accentColor, defTxtColor, hoverTxtColor, darkTxtColor,
  midPadding, commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")
let { fontMedium, fontSmall} = require("%enlSqGlob/ui/fontsStyle.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut") /* FIX ME: need to be redesigned after lottie animation integtation */


let defPointsStyle = {
  color = defTxtColor
  fontSize = fontMedium.fontSize
}

let hoverPointsStyle = {
  color = hoverTxtColor
  fontSize = fontMedium.fontSize
}

let defSaleStyle = { color = darkTxtColor }.__update(fontMedium)
let discoutTxtStyle = { color = accentColor }.__update(fontSmall)

let commonBtnStyle = { fillColor = null }
let hoverBtnStyle = { fillColor = accentColor }
let salePanelSize = [columnWidth, colPart(0.32)]
let ellipsisSize = [colPart(0.36), colPart(0.065)]

let discountHeader = {
  rendObj = ROBJ_TEXT
  text = "DISCOUNT"//loc("squad/slotDiscount")
  valign = ALIGN_CENTER
  size = [SIZE_TO_CONTENT, colPart(0.32)]
}.__update(discoutTxtStyle)

let btnSalePanel = @(percents) {
  size = salePanelSize
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/squads/discount_bg.svg:{0}:{1}:K".subst(salePanelSize[0], salePanelSize[1]))
  color = accentColor
  children = {
    rendObj = ROBJ_TEXT
    text = $"{percents}%"
    halign = ALIGN_CENTER
    size = flex()
  }.__update(defSaleStyle)
}

let unseeSquadsIcon = @() {
  watch = [unseenSquads, curArmy]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = (unseenSquads.value?[curArmy.value] ?? {}).findindex(@(v) v)
    ? unseenSignal(0.7)
    : null
}

let managementBtn = @(restSquadCountWatch) watchElemState(@(sf) {
  watch = armySlotDiscount
  size = [columnWidth, colPart(0.58)]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  borderColor = defBdColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick = @() openChooseSquadsWnd(curArmy.value, curSquadId.value)
  xmbNode = XmbNode()
  children = [
    function() {
      let rest = restSquadCountWatch.value
      return {
        children = rest < 1
          ? {
            rendObj = ROBJ_IMAGE
            image = Picture("!ui/squads/ellipsis.svg:{0}:{1}:K".subst(ellipsisSize[0], ellipsisSize[1]))
            size = ellipsisSize
          }.__update(sf & S_HOVER ? hoverPointsStyle : defPointsStyle)
          : @() {
            watch = restSquadCountWatch
            rendObj = ROBJ_TEXT
            text = $"+{rest}"
          }.__update(sf & S_HOVER ? hoverPointsStyle : defPointsStyle)
      }
    }
    unseeSquadsIcon
  ]
}.__update(sf & S_HOVER ? hoverBtnStyle : commonBtnStyle))

let squadManagementBtn = @(restSquadCountWatch) @() {
  watch = armySlotDiscount
  size = [columnWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    armySlotDiscount.value <= 0 ? null : discountHeader
    managementBtn(restSquadCountWatch)
    armySlotDiscount.value <= 0 ? null : btnSalePanel(armySlotDiscount.value)
  ]

}

return squadManagementBtn