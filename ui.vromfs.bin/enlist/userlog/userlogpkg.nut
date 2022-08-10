from "%enlSqGlob/ui_library.nut" import *

let colorize = require("%ui/components/colorize.nut")
let faComp = require("%ui/components/faComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { tierText } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let {
  accentTitleTxtColor, defTxtColor, activeBgColor, smallOffset,
  disabledTxtColor, smallPadding, bigPadding, tinyOffset
} = require("%enlSqGlob/ui/viewConst.nut")
let { detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { BattleResult } = require("%enlSqGlob/battleParams.nut")


enum UserLogType {
  PURCH_ITEM = "PURCH_ITEM"
  PURCH_SOLDIER = "PURCH_SOLDIER"
  PURCH_SQUAD = "PURCH_SQUAD"
  PURCH_WALLPOSTER = "PURCH_WALLPOSTER"
  PURCH_BONUS = "PURCH_BONUS"
  PURCH_PREMDAYS = "PURCH_PREMDAYS"

  BATTLE_ARMY_EXP = "BATTLE_ARMY_EXP"
  BATTLE_ACTIVITY = "BATTLE_ACTIVITY"
}

let USERLOG_WIDTH = fsh(100)

let borderColor = @(sf, isSelected = false) isSelected ? activeBgColor
  : sf & S_HOVER ? activeBgColor
  : disabledTxtColor

let rowStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = tinyOffset
  valign = ALIGN_CENTER
}

let mkRowText = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(sub_txt)

let mkRowTextArea = @(text, color) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
}.__update(sub_txt)

let userLogStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  padding = bigPadding
  gap = smallPadding
  halign = ALIGN_CENTER
}

let userLogRowStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  padding = [tinyOffset, smallOffset]
}

let function mkReceivedItem(row, allTpl) {
  let { armyId, baseTpl, count } = row
  let template = allTpl?[armyId][baseTpl]
  if (template == null)
    return null

  return {
    children = [
      mkRowText(loc("listWithDot", { text = getItemName(template) }), defTxtColor)
      detailsStatusTier(template)
      count <= 1 ? null : mkRowText(loc("common/amountShort", { count }), accentTitleTxtColor)
    ]
  }.__update(rowStyle)
}

let function mkReceivedSoldier(row, _allTpl = null) {
  let { name, surname, tier, sClass } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = $"{loc(name)} {loc(surname)}" }), defTxtColor)
      tierText(tier)
      mkRowText(loc($"soldierClass/{sClass}"), accentTitleTxtColor)
    ]
  }.__update(rowStyle)
}

let function mkReceivedPremium(row, _allTpl = null) {
  let { count } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = loc("premium/title") }), defTxtColor)
      mkRowText("{0} {1}".subst(count, loc("premiumDays", { days = count })),
        accentTitleTxtColor)
    ]
  }.__update(rowStyle, { gap = smallPadding })
}

let function mkReceivedWallposter(row, _allTpl = null) {
  let { wallposterId, armyId } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = loc("userLogRow/wallposter") }), defTxtColor)
      mkRowText("{0} ({1})".subst(loc($"wp/{wallposterId}/name"), loc(armyId)),
        accentTitleTxtColor)
    ]
  }.__update(rowStyle, { gap = smallPadding })
}

let purchaseRowView = {
  [UserLogType.PURCH_ITEM] = mkReceivedItem,
  [UserLogType.PURCH_SOLDIER] = mkReceivedSoldier,
  [UserLogType.PURCH_PREMDAYS] = mkReceivedPremium,
  [UserLogType.PURCH_WALLPOSTER] = mkReceivedWallposter
}

let mkPurchaseLogRows = @(uLogRows, allTpl) {
  children = uLogRows.map(@(row) purchaseRowView?[row?.logType](row, allTpl))
}.__update(userLogRowStyle)

let mkUserLogHeader = @(uLogRows, logTime, logText) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = [smallOffset, flex()]
      halign = ALIGN_CENTER
      children = faComp(uLogRows == null ? "caret-right" : "caret-down",
        { color = disabledTxtColor })
    }
    noteTextArea({
      text = logText
      size = [flex(), SIZE_TO_CONTENT]
      color = defTxtColor
    }).__update(sub_txt)
    // TODO: Need convert uLog.logTime to date format
    txt({
      text = logTime
      color = defTxtColor
    }).__update(sub_txt)
  ]
}

let function mkPurchaseLog(uLog, uLogRows, shopItem, allTpl) {
  let { nameLocId = "Undefined" } = shopItem
  let shortItemTitle = utf8ToUpper(loc(nameLocId).split("\r\n")?[0] ?? "")
  let rowsBlock = uLogRows == null ? null
    : mkPurchaseLogRows(uLogRows.filter(@(row) row.logType != UserLogType.PURCH_BONUS), allTpl)
  return {
    children = [
      mkUserLogHeader(uLogRows, uLog.logTime,
        loc("userLog/purchase", {
          name = colorize(accentTitleTxtColor, shortItemTitle)
        }))
      rowsBlock
    ]
  }.__update(userLogStyle)
}

let mkArmyExpLogRow = @(row) {
  children = mkRowTextArea(loc("listWithDot", {
    text = loc("userLogRow/armyExp", {
      army = colorize(accentTitleTxtColor, loc(row.armyId))
      exp = colorize(accentTitleTxtColor, row.count)
    })
  }), defTxtColor)
}.__update(rowStyle, { gap = smallPadding })

let mkActivityLogRow = @(row) {
  children = mkRowTextArea(loc("listWithDot", {
    text = loc("userLogRow/battleActivity", {
      activity = colorize(accentTitleTxtColor, row.count)
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
  [BattleResult.DESERTION] = "deserter",
  [BattleResult.WIN] = "victory",
  [BattleResult.DEFEAT] = "defeat"
}

let mkBattleLog = @(uLog, uLogRows) {
  children = [
    mkUserLogHeader(uLogRows, uLog.logTime,
      loc("userLog/battle", {
        result = colorize(accentTitleTxtColor,
          loc($"userLog/battleRes/{battleResLoc[uLog?.value ?? 0]}"))
        missionName = loc(uLog.missionId)
      }))
    uLogRows == null ? null : mkBattleLogRows(uLogRows)
  ]
}.__update(userLogStyle)

return {
  USERLOG_WIDTH
  mkPurchaseLog
  mkBattleLog
  borderColor
}
