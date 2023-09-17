from "%enlSqGlob/ui_library.nut" import *

let { doesLocTextExist } = require("dagor.localize")
let { fontTitle, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let {
  defTxtColor, blurBgColor, bigPadding, defInsideBgColor,
  rowBg
} = require("%enlSqGlob/ui/viewConst.nut")
let { UserNameColor } = require("%ui/style/colors.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let {
  refreshLbData, curLbRequestData, curLbData, curLbSelfRow, curLbErrName, isLbWndOpened,
  isRefreshLbEnabled, lbSelCategories, LB_PAGE_ROWS, bestBattlesByMode, ratingBattlesCountByMode
} = require("lbState.nut")
let { selLbMode } = require("%enlist/gameModes/eventModesState.nut")
let { RANK, NAME } = require("lbCategory.nut")
let exclamation = require("%enlist/components/exclamation.nut")
let spinner = require("%ui/components/spinner.nut")
let closeBtn = require("%ui/components/closeBtn.nut")
let { mkHeaderFlag, casualFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let lbBestBattlesWnd = require("lbBestBattlesWnd.nut")
let { Bordered } = require("%ui/components/textButton.nut")



const WND_UID = "leaderboard"
let rowHeight = hdpx(28)
let contentHeaderHeight = rowHeight * 1.5
let fullHeight = (LB_PAGE_ROWS + 2) * rowHeight + 2 * bigPadding + contentHeaderHeight//header, ..., self data
let firstPlaceColor = 0xFFFFFFFF
let top3Color = Color(255, 245, 180)
let localGap = bigPadding * 2
let wreathSize = hdpx(24)
let headerImgHeight = hdpx(150)
let iconHeaderSize = hdpxi(30)
let waitingSpinner = spinner()


let styleByCategory = {
  [RANK] = { halign = ALIGN_LEFT },
  [NAME] = { halign = ALIGN_LEFT, size = [hdpx(240), SIZE_TO_CONTENT] },
}

let close = @() isLbWndOpened(false)
let refreshLbOnChange = @(_) refreshLbData()

let mkLbCell = @(category, rowData, override) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  halign = ALIGN_CENTER
  text = category.getText(rowData)
}.__update(
  fontSub,
  styleByCategory?[category] ?? {},
  override)

let function mkLbRankCell(category, rowData, override) {
  let { idx = -1 } = rowData

  return {
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    children = {
      size = [wreathSize, SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [ idx >= 0 && idx < 3
        ? {
            rendObj = ROBJ_IMAGE
            size = [wreathSize, wreathSize]
            image = Picture("ui/uiskin/scanner_range.avif")
          }
        : null
        {
            rendObj = ROBJ_TEXT
            color = defTxtColor
            text = category.getText(rowData)
        }.__update(fontSub)
      ]
    }
  }.__update(override, styleByCategory)
}

let renderByCategory = {
  [RANK] = mkLbRankCell
}

let function mkLbRow(rowData, categories) {
  let { self = false, idx = -1 } = rowData
  let color = self ? UserNameColor
    : idx == 0 ? firstPlaceColor
    : idx == 1 || idx == 2 ? top3Color
    : null

  let override = color != null ? { color } : {}
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), rowHeight]
    flow = FLOW_HORIZONTAL
    padding = localGap
    color = rowBg(0, idx)
    valign = ALIGN_CENTER
    children = categories.map(@(c) (renderByCategory?[c] ?? mkLbCell)(c, rowData, override))
  }
}

let dotsRow = {
  size = [flex(), rowHeight]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = "..."
}

let lbHeaderFlag = {
  vplace = ALIGN_CENTER
  children = mkHeaderFlag(
    {
      padding = [localGap, bigPadding * 3]
      rendObj = ROBJ_TEXT
      text = loc("Leaderboard")
    }.__update(fontTitle),
    {
      offset = hdpx(15)
    }.__update(casualFlagStyle)
  )
}

let lbHeaderImg = {
  size = [flex(), headerImgHeight]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/pacific_usa_login_screen.avif")
  keepAspect = KEEP_ASPECT_FILL
}

let lbWindowHeader = {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    lbHeaderImg
    lbHeaderFlag
    closeBtn({ onClick = close }).__update({ margin = bigPadding })
    function() {
      let res = { watch = [selLbMode, bestBattlesByMode] }
      let battles = bestBattlesByMode.value?[selLbMode.value] ?? []
      return battles.len() == 0 ? res
        : res.__update({
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            children = Bordered(loc("lb/bestBattles"),
              @() lbBestBattlesWnd(selLbMode.value))
          })
    }
  ]
}


let getColumnDescription = function(locId, textParams = null) {
  let descLocId = $"{locId}/desc"
  let description = doesLocTextExist(descLocId) ? loc(descLocId, textParams) : ""

  return description
}

let categoryTooltip = Computed(function() {
  let count = ratingBattlesCountByMode.value?[selLbMode.value] ?? 20

  return {
    common = @(category) "\n\n".join([loc(category.locId),
      getColumnDescription(category.locId)]),
    BATTLE_RATING = @(category) "\n\n".join([loc(category.locId),
      getColumnDescription(category.locId, { count })])
    TOURNAMENT_BATTLE_RATING = @(category) "\n\n".join([loc(category.locId),
      getColumnDescription(category.locId, { count })])
  }
})

let mkCategoryTooltip = @(category, categoryTooltipVal)
  (categoryTooltipVal?[category.id] ?? categoryTooltipVal.common)(category)

let mkHeaderName = @(category) {
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    children = category?.icon == null
      ? {
          rendObj = ROBJ_TEXT
          text = loc(category.locId)
          color = defTxtColor
        }.__update(fontSub)
      : withTooltip({
            rendObj = ROBJ_IMAGE
            color = defTxtColor
            size = [iconHeaderSize, iconHeaderSize]
            image = Picture(category.icon)
          },
          @() tooltipBox(@() {
              watch = categoryTooltip
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              maxWidth = hdpx(500)
              text = mkCategoryTooltip(category, categoryTooltip.value)
              color = Color(180, 180, 180, 120)
            })
          )
  }.__update(styleByCategory?[category] ?? {})

let lbHeaderRow = @(categories) {
  rendObj = ROBJ_SOLID
  size = [flex(), contentHeaderHeight]
  xmbNode = XmbContainer({
    isViewport = true
  })
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = localGap
  color = Color(0,0,0)
  children = categories.map(mkHeaderName)
}

let function lbContent() {
  let lbCategories = lbSelCategories.value.full
  local children = null
  local valign = ALIGN_CENTER
  if (curLbData.value == null)
    children = waitingSpinner
  else if (curLbData.value.len() == 0)
    children = exclamation(
      loc(curLbErrName.value != null ? $"error/{curLbErrName.value}" : "leaderboard/noLbData"))
  else {
    children = curLbData.value.map(@(rowData) mkLbRow(rowData, lbCategories))
    if (curLbSelfRow.value && curLbData.value.findvalue(@(r) r?.self ?? false) == null) {
      let selfRow = mkLbRow(curLbSelfRow.value, lbCategories)
      let { idx = -1 } = curLbSelfRow.value
      if (idx > 0 && idx < (curLbData.value[0]?.idx ?? -1)) {
        children.insert(0, selfRow)
        children.insert(1, dotsRow)
      }
      else if (idx > (curLbData.value.top()?.idx ?? -1) + 1) {
        children.append(dotsRow)
        children.append(selfRow)
      }
    }
    children.insert(0, lbHeaderRow(lbCategories))
    valign = ALIGN_TOP
  }

  return {
    watch = [lbSelCategories, curLbData, curLbSelfRow, curLbErrName]
    size = [flex(), fullHeight]
    rendObj = ROBJ_SOLID
    color = Color(10,10,10,10)
    halign = ALIGN_CENTER
    valign
    flow = FLOW_VERTICAL
    children
  }
}

let lbWindow = {
  size = [hdpx(1300), SIZE_TO_CONTENT]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  flow = FLOW_VERTICAL
  function onAttach() {
    refreshLbData()
    curLbRequestData.subscribe(refreshLbOnChange)
  }
  onDetach = @() curLbRequestData.unsubscribe(refreshLbOnChange)
  children = [
    lbWindowHeader
    lbContent
  ]
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = flex()
  onAttach = @() isRefreshLbEnabled(true)
  onDetach = @() isRefreshLbEnabled(false)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  onClick = @() null
  children = lbWindow
})

if (isLbWndOpened.value)
  open()
isLbWndOpened.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))
