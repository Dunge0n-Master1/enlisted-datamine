from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { getClassCfg, getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { mkSoldierPhotoWithoutFrame } = require("%enlSqGlob/ui/soldierPhoto.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let {
  colPart, defTxtColor, titleTxtColor, haveLevelColor, gainLevelColor,
  lockLevelColor
} = require("%enlSqGlob/ui/designConst.nut")


// TODO: this metods should be in this file after switching to a new design
let {
  mkAnimatedLevelIcon, mkHiddenAnim, mkIconBar, calcExperienceData
} = require("%enlSqGlob/ui/soldiersUiComps.nut")


const MAX_LEVEL_SOLDIER = 5


let defKindSize = colPart(0.6)
let classSize = colPart(0.6)
let photoSize = [colPart(1), colPart(1.5)]


let nameTxtStyle = { color = titleTxtColor }.__update(fontLarge)


let getKindIcon = memoize(@(img, size)
  Picture("ui/skin#{0}:{1}:{1}:K".subst(img, size.tointeger())))

let getClassIcon = memoize(@(img, size)
  Picture("{0}:{1}:{1}:K".subst(img, size.tointeger())))


let function mkClassIcon(armyId, sClass, override = {}, cSize = classSize) {
  let { getIcon } = getClassCfg(sClass)
  let icon = getIcon(armyId) ?? ""
  if (icon == "")
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = [cSize, cSize]
    keepAspect = KEEP_ASPECT_FIT
    image = getClassIcon(icon, cSize)
  }.__update(override)
}


let function mkKindIcon(sKind, sClassRare, kindSize = defKindSize) {
  if (sKind == null)
    return null

  let { icon = "", iconsByRare = null, colorsByRare = null } = getKindCfg(sKind)
  let sKindImg = iconsByRare?[sClassRare] ?? icon
  if (sKindImg == "")
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = [kindSize, kindSize]
    color = colorsByRare?[sClassRare] ?? defTxtColor
    image = getKindIcon(sKindImg, kindSize)
  }
}


let function mkSoldierBadgePhoto(photo) {
  return mkSoldierPhotoWithoutFrame(photo, photoSize, {})
}


let mkClassName = @(sClass, sKind, sClassRare) {
  rendObj = ROBJ_TEXT
  text = loc(getClassCfg(sClass).locId)
  color = getKindCfg(sKind)?.colorsByRare[sClassRare] ?? defTxtColor
}.__update(fontLarge)


let mkSoldierTier = @(tier) {
  rendObj = ROBJ_TEXT
  text = getRomanNumeral(tier)
}.__update(nameTxtStyle)


let function mkSoldierBadgeData(soldier, allPerks, expGrid, thresholdColor) {
  let {
    guid, armyId, tier, sKind, sClass, sClassRare,
    photo = null, name = "", surname = ""
  } = soldier
  let perks = allPerks?[guid] ?? {}
  let levelData = calcExperienceData(soldier.__merge(perks), expGrid)
  let { maxLevel, perksCount, perksLevel } = levelData
  let isPremium = getClassCfg(sClass)?.isPremium ?? false
  return {
    guid, armyId, tier, sKind, sClass, sClassRare, photo, name, surname,
    maxLevel, perksCount, perksLevel, thresholdColor, isPremium
  }
}


let function levelBlock(allParams) {
  local {
    curLevel, tier = 1, gainLevel = 0, leftLevel = 0, lockedLevel = 0,
    fontSize = hdpx(12), hasLeftLevelBlink = false, guid = "",
    isFreemiumMode = false, thresholdColor = 0
  } = allParams
  local color = haveLevelColor
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
      mkIconBar(gainLevel, gainLevelColor, fontSize)
      mkIconBar(leftLevel, color, fontSize, "star-o", hasLeftLevelBlink)
      mkIconBar(freemiumStars, color, fontSize, "star-o")
      mkIconBar(lockedLevel, lockLevelColor, fontSize)
    ]
    animations = [ mkHiddenAnim() ]
  }
}


return {
  mkClassName
  mkClassIcon
  mkKindIcon
  levelBlock
  mkSoldierTier
  calcExperienceData
  mkSoldierBadgePhoto
  mkSoldierBadgeData
}
