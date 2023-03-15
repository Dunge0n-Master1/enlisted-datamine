from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let {
  gap, bigGap, defTxtColor, soldierExpColor, soldierLvlColor, soldierGainLvlColor,
  soldierLockedLvlColor, msgHighlightedTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let soldiersPresentation = require("%enlSqGlob/ui/soldiersPresentation.nut")
let { getClassCfg, getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let blinkingIcon = require("%enlSqGlob/ui/blinkingIcon.nut")
let defcomps = require("%enlSqGlob/ui/defcomps.nut")

const MAX_LEVEL_SOLDIER = 5
const PERK_ALERT_SIGN = "caret-square-o-up"
const ITEM_ALERT_SIGN = "dropbox"
const REQ_MANAGE_SIGN = "plus-square"

let iconSize = hdpxi(26)

let formatIconName = memoize(function(icon, width, height = null) {
  if (icon.endswith(".svg")) {
    log("getting svg icon for soldiers")
    return $"{icon}:{width.tointeger()}:{(height ?? width).tointeger()}:K"
  }
  return $"{icon}?Ac"
})

let mkAlertIcon = @(icon, unseenWatch = Watched(true), hasBlink = false)
  function() {
    let res = { watch = unseenWatch }
    return !unseenWatch.value ? res
      : res.__update(blinkingIcon(icon), hasBlink ? {} : { animations = null })
  }

let mkLevelIcon = @(fontSize = hdpx(10), color = soldierExpColor, fName = "star") {
  rendObj = ROBJ_INSCRIPTION
  validateStaticText = false
  text = fa[fName]
  font = fontawesome.font
  fontSize
  color
}

let mkIconBar = @(level, color, fontSize, fName = "star-o", hasBlink = false) level > 0
  ? mkLevelIcon(fontSize, color, fName).__update({
      key = $"l{level}fnm{fName}b{hasBlink}"
      text = "".join(array(level, fa[fName]))
      color
      animations = hasBlink
        ? [ { prop = AnimProp.opacity, from = 0.5, to = 1, duration = 0.7, play = true, loop = true, easing = Blink} ]
        : null
    })
  : null

let mkHiddenAnim = @(p = {})
  { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.1, play = true }.__update(p)

let mkAnimatedLevelIcon = function(guid, color, fontSize) {
    let trigger = $"{guid}lvl_anim"
    return {
      children = [
        mkLevelIcon(fontSize, color, "star-o")
        mkLevelIcon(fontSize, color, "star").__update({
          transform = {}
          animations = [
            mkHiddenAnim({ duration = 0.9, play = false, trigger })
            { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4,
              easing = InOutCubic, delay = 0.8, trigger }
            { prop = AnimProp.scale, from = [3,3], to = [1,1], duration = 0.8,
              easing = InOutCubic, delay = 0.8, trigger }
          ]
        })
      ]
    }
  }

let function levelBlock(allParams) {
  local { curLevel, tier = 1, gainLevel = 0, leftLevel = 0, lockedLevel = 0, fontSize = hdpx(12),
    hasLeftLevelBlink = false, guid = "", isFreemiumMode = false, thresholdColor = 0
  } = allParams
  local color = soldierExpColor
  local freemiumStars = 0
  if (isFreemiumMode && curLevel + leftLevel < MAX_LEVEL_SOLDIER) {
    lockedLevel = tier == MAX_LEVEL_SOLDIER ? 1 : 0
    freemiumStars = MAX_LEVEL_SOLDIER - curLevel - leftLevel
    color = thresholdColor
  }

  return {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children = [
      mkIconBar(curLevel - 2, color, fontSize, "star")
      curLevel > 1
        ? mkAnimatedLevelIcon(guid, color, fontSize)
        : null
      mkIconBar(gainLevel, soldierGainLvlColor, fontSize)
      mkIconBar(leftLevel, color, fontSize, "star-o", hasLeftLevelBlink)
      mkIconBar(freemiumStars, color, fontSize, "star-o")
      mkIconBar(lockedLevel, soldierLockedLvlColor, fontSize)
    ]
    animations = [ mkHiddenAnim() ]
  }
}

let mkUnknownClassIcon = @(iSize) {
  rendObj = ROBJ_TEXT
  size = [iSize.tointeger(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  text = "?"
  color = defTxtColor
}.__update(body_txt)

let getKindIcon = memoize(@(img, sz) Picture("ui/skin#{0}:{1}:{1}:K".subst(img, sz.tointeger())))
let getClassIcon = memoize(@(img, sz) Picture("{0}:{1}:{1}:K".subst(img, sz.tointeger())))

let function kindIcon(sKind, iSize, sClassRare = null, forceColor = null) {
  if (sKind == null)
    return mkUnknownClassIcon(iSize)

  let { icon = "", iconsByRare = null, colorsByRare = null } = getKindCfg(sKind)
  let sKindImg = iconsByRare?[sClassRare] ?? icon
  if (sKindImg == "")
    return mkUnknownClassIcon(iSize)
  let sClassColor = forceColor ?? colorsByRare?[sClassRare] ?? defTxtColor
  return {
    rendObj = ROBJ_IMAGE
    size = [iSize, iSize]
    color = sClassColor
    image = getKindIcon(sKindImg, iSize)
  }
}

let function classIcon(armyId, sClass, iSize, override = {}) {
  let { getIcon } = getClassCfg(sClass)
  let icon = getIcon(armyId) ?? ""
  if (icon == "")
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = [iSize, iSize]
    keepAspect = KEEP_ASPECT_FIT
    image = getClassIcon(icon, iSize)
  }.__update(override)
}

let kindName = @(sKind) defcomps.note({
  text = loc(getKindCfg(sKind).locId)
  vplace = ALIGN_CENTER
  color = defTxtColor
})

let className = @(sClass, count = 0) defcomps.note({
  text = count <= 1 ? loc(getClassCfg(sClass).locId)
    : $"{loc(getClassCfg(sClass).locId)} {loc("common/amountShort", { count })}"
  vplace = ALIGN_CENTER
  color = defTxtColor
})

let classNameColored = @(sClass, sKind, sClassRare) defcomps.note({
  text = loc(getClassCfg(sClass).locId)
  vplace = ALIGN_CENTER
  color = getKindCfg(sKind)?.colorsByRare[sClassRare] ?? defTxtColor
})

let tierText = @(tier) defcomps.note({
    text = getRomanNumeral(tier)
    color = soldierLvlColor
  }.__update(sub_txt))

let function calcExperienceData(soldier, expToLevel) {
  let { perksCount = 0, level = 1, maxLevel = 1, exp = 0 } = soldier
  let expToNextLevel = max(1, level < maxLevel ? (expToLevel?[level] ?? 0) : 0)
  let perksLevel = min(level, maxLevel)
  return { level, maxLevel, exp, expToNextLevel, perksCount, perksLevel }
}

let classTooltip = @(armyId, sClass, sKind) tooltipBox({
  flow = FLOW_VERTICAL
  size = [hdpx(500), SIZE_TO_CONTENT]
  gap = bigGap
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = gap
      children = [
        kindIcon(sKind, iconSize)
        classIcon(armyId, sClass, iconSize)
        defcomps.txt(loc(getClassCfg(sClass).locId))
      ]
    }
    defcomps.txt(loc($"squadPromo/{sClass}/longDesc")).__update({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
    })
  ]
})

let rankingTooltip = @(curRank) loc("tooltip/soldierRanking", {
  current = colorize(msgHighlightedTxtColor, getRomanNumeral(curRank))
  max = colorize(msgHighlightedTxtColor, getRomanNumeral(MAX_LEVEL_SOLDIER))
})

let experienceTooltip = kwarg(function(
  level, maxLevel, exp, expToNextLevel, perksCount, perksLevel
) {
  let limitLoc = perksCount >= maxLevel ? ""
    : perksCount >= perksLevel ? loc("hint/perksLevelLimit", { count = perksLevel })
    : ""
  return loc(level < maxLevel ? "hint/soldierLevel" : "hint/soldierMaxLevel", {
    level = colorize(msgHighlightedTxtColor, level - 1)
    maxLevel = maxLevel - 1
    exp = colorize(msgHighlightedTxtColor, exp)
    expToNextLevel = expToNextLevel
    limit = limitLoc
  })
})

let function mkSoldierMedalIcon(soldierInfo, size) {
  let { heroTpl = null, armyId = null } = soldierInfo
  let { heroIcon = null } = soldiersPresentation?[armyId]
  if ((heroTpl ?? "") == "" || heroIcon == null)
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture(formatIconName(heroIcon, size))
  }
}

return {
  mkAlertIcon
  levelBlock
  kindIcon
  kindName
  classIcon
  className
  classNameColored
  tierText
  calcExperienceData
  classTooltip
  rankingTooltip
  experienceTooltip
  mkLevelIcon
  mkSoldierMedalIcon
  mkIconBar
  mkAnimatedLevelIcon
  mkHiddenAnim

  PERK_ALERT_SIGN
  ITEM_ALERT_SIGN
  REQ_MANAGE_SIGN
}
