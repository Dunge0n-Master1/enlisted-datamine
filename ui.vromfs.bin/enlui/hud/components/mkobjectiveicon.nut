from "%enlSqGlob/ui_library.nut" import *

let {h1_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let { logerr } = require("dagor.debug")
let { endswith } = require("string")
let {TEAM0_COLOR_FG, TEAM1_COLOR_FG} = require("%ui/hud/style.nut")
let fa = require("%darg/components/fontawesome.map.nut")
let capzone_images = require("capzone_images.nut")

let ZONE_TEXT_COLOR = Color(80,80,80,20)

let transformCenterPivot = {pivot = [0.5, 0.5]}

let defZoneBaseSize = [hdpx(24), hdpx(24)]

let defaultCorrect = @(fontSize) [fontSize*0.04+1, fontSize*0.05]
let lettersCorrection = {
  B = defaultCorrect,
  D = defaultCorrect,
  F = defaultCorrect,
  [fa["forward"]] = @(fontSize) [fontSize*0.2, -fontSize*0.03],
  [fa["shield"]] = @(fontSize) [fontSize*0.1, fontSize*0.05],
  [fa["close"]] = @(fontSize) [fontSize*0.12, -fontSize*0.04],
  [fa["check"]] = @(fontSize) [fontSize*0.1, -fontSize*0.04],
}
let function mkPosOffsetForLetterVisPos(letter, fontSize){
// we need psychovisual correction for centered letters - B is not percepted as in the center when it is in the center
  return lettersCorrection?[letter](fontSize) ?? [0, fontSize*0.05]
}

let function zoneBase(text_params={}, params={}, cache = null) {
  let text = text_params?.text
  if (cache!=null && text in cache)
    return cache[text]
  if (text == null)
    return null
  let color = params?.color ?? ZONE_TEXT_COLOR
  let fontSize = (params?.size ?? defZoneBaseSize)[1] * 0.8
  let children = {
    rendObj = ROBJ_INSCRIPTION
    color
    pos = mkPosOffsetForLetterVisPos(text, fontSize)
    animations = params?.animAppear ?? params?.baseZoneAppearAnims
    transform = transformCenterPivot
  }.__update(text_params, { fontSize })
  let res = {
    transform = transformCenterPivot
    size = SIZE_TO_CONTENT
    halign  = ALIGN_CENTER
    valign = ALIGN_CENTER
    children
  }
  if (cache!=null)
    cache[text] <- res
  return res
}

let function zoneFontAwesome(symbol, params) {
  return zoneBase({
    text = fa[symbol]
    padding = [0,0,hdpx(2)]
    valign = ALIGN_CENTER
    key = symbol
  }.__update(fontawesome), params)
}

let getPicture = memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = endswith(name,".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name
  } else if (name in capzone_images) {
    imagename = "{0}:{1}:{1}:K".subst(capzone_images[name], iconSz.tointeger())
  }

  if (!imagename) {
    logerr("no image found")
    return null
  }

  return Picture(imagename)
}, @(name, iconSz) $"{name}{iconSz}")


let caches = {}
let mkZoneCaches = @() {
  title = {}
  icon = {}
}

let function mkZoneIcon(icon, iconSz, animations, cache){
  if (icon in cache)
    return cache[icon]
  let image = getPicture(icon, iconSz[0])
  if (image == null)
    return null
  let res = {
    rendObj = ROBJ_IMAGE
    size = iconSz
    halign  = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = Color(125,125,125,125)
    transform = transformCenterPivot
    image
    animations
  }
  cache[icon] <- res
  return res
}
let mkZoneToCaptureIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("shield",
  { size = iconSz, color = TEAM1_COLOR_FG, animAppear}))
let mkZoneCapturedIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("check",
  { size = iconSz, color = TEAM0_COLOR_FG, animAppear}))
let mkZoneToDefendIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("shield",
  { size = iconSz, color = TEAM0_COLOR_FG, animAppear}))
let mkZoneFailedIcon = memoize(@(_width, iconSz, animAppear) zoneFontAwesome("close",
  { size = iconSz, color = TEAM1_COLOR_FG, animAppear}))

let mkZoneTitle = @(text, iconSz, titleSize, animAppear, cache) zoneBase({ text }.__update(h1_txt),
    { size = titleSize > 0 ? [fsh(titleSize), fsh(titleSize)] : iconSz, animAppear}, cache)

let function mkObjectiveIcon(zoneData, iconSz, params={}) {
  let { animAppear = null, baseZoneAppearAnims = null } = params
  let { icon = null, bombPlantingTeam, attackTeam, trainTriggerable = null, active = null, capTeam = null, capzoneTwoChains = null, owningTeam = null, titleSize, title} = zoneData
  let [iconWidth] = iconSz
  if (iconWidth not in caches)
    caches[iconWidth] <- mkZoneCaches()
  let cacheBySz = caches[iconWidth]
  let zoneToCaptureIcon = mkZoneToCaptureIcon(iconWidth, iconSz, animAppear)
  let zoneCapturedIcon = mkZoneCapturedIcon(iconWidth, iconSz, animAppear)
  let zoneToDefendIcon = mkZoneToDefendIcon(iconWidth, iconSz, animAppear)
  let zoneFailedIcon = mkZoneFailedIcon(iconWidth, iconSz, animAppear)

  let zoneTitle = mkZoneTitle(title, iconSz, titleSize, animAppear, cacheBySz.title)
  let zoneIcon = mkZoneIcon(icon, iconSz, animAppear ?? baseZoneAppearAnims, cacheBySz.icon)
  let activeIcon = {
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [zoneIcon, zoneTitle]
  }

  let heroTeam = params?.heroTeam ?? INVALID_ENTITY_ID
  let attackTeamId = bombPlantingTeam > -1 ? bombPlantingTeam : attackTeam
  let isDefendZone = attackTeamId > -1 && attackTeamId != heroTeam
  let isAttackZone = attackTeamId > -1 && attackTeamId == heroTeam

  return (trainTriggerable || active)
    ? activeIcon
    : isAttackZone
      ? (capTeam == heroTeam ? zoneCapturedIcon : zoneToCaptureIcon)
      : isDefendZone
        ? (capTeam > 0 && capTeam != heroTeam ? zoneFailedIcon : zoneToDefendIcon)
        : capzoneTwoChains
          ? (owningTeam == heroTeam ? zoneToDefendIcon : (owningTeam > 0 ? zoneToCaptureIcon : zoneIcon))
          : zoneIcon
}

return {
  mkObjectiveIcon
  mkZoneToCaptureIcon
  mkZoneCapturedIcon
  mkZoneFailedIcon
  mkZoneToDefendIcon
  mkZoneIcon
  mkZoneTitle
}