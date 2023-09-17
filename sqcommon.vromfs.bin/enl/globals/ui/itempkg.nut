from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let {
  msgHighlightedTxtColor, smallPadding, hoverTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  statusIconChosen, statusIconDisabled, statusIconLocked
} =  require("%enlSqGlob/ui/style/statusIcon.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")
let { mkItemTier } = require("%enlSqGlob/ui/itemTier.nut")

let iconSize = hdpx(15)
let badgeSize = hdpx(40)

let mkStatusIcon = @(icon, color) faComp(icon, {
  margin = smallPadding
  fontSize = iconSize
  color
})

let iconChosen = mkStatusIcon("check", statusIconChosen)
let iconBlocked = mkStatusIcon("ban", statusIconDisabled)

let mkBackBlock = @(children) {
  rendObj = ROBJ_BOX
  size = array(2, hdpx(19))
  borderWidth = 0
  borderRadius = hdpx(5)
  fillColor = statusIconLocked
  clipChildren = true
  margin = smallPadding
  valign = ALIGN_CENTER
  children = children
}

let iconLocked = faComp("lock", {
  size = array(2, hdpx(19))
  fontSize = iconSize
  color = statusIconLocked
})

let mkIconWarning = @(size) faComp("warning", {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  fontSize = size
  color = statusIconLocked
  animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1.0, play = true, loop = true, easing = CosineFull }]
})

let mkLevelBlock = @(level) mkBackBlock({
  rendObj = ROBJ_TEXT
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  text = level
  color = hoverTxtColor
}.__update(fontSub))

let statusIconCtor = @(demands) demands?.classLimit != null ? iconBlocked
  : demands == null ? null
  : demands?.canObtainInShop ? null
  : iconLocked

let mkHintText = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  text = text
  color = msgHighlightedTxtColor
}.__update(fontSub)

let mkStatusHint = @(demands) demands == null ? null
  : demands?.classLimit != null ? mkHintText(loc("itemClassResearch", {
      soldierClass = loc(soldierClasses?[demands.classLimit].locId ?? "unknown")
    }))
  : demands?.levelLimit != null ? mkHintText(loc("itemObtainAtLevel", {
      level = demands.levelLimit
    }))
  : mkHintText(loc(demands?.canObtainInShop ? "itemObtainInShop" : "itemOutOfStock"))

return {
  statusIconLocked = iconLocked
  statusIconChosen = iconChosen
  statusIconBlocked = iconBlocked
  statusIconCtor = statusIconCtor
  statusIconWarning = mkIconWarning(iconSize)
  statusBadgeWarning = mkIconWarning(badgeSize)
  statusLevel = mkLevelBlock
  statusTier = mkItemTier
  hintText = mkHintText
  statusHintText = mkStatusHint
}