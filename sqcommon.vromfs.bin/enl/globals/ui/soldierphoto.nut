import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {getTexReplaceString, getTexSetString} = require("%ui/components/itemTexReplace.nut")
let { Point2 } = require("dagor.math")


let smallIconsCache = {}
let largeIconsCache = {}
let function getSoldierParamsByTemplate(template, isLarge) {
  let cache = isLarge ? largeIconsCache : smallIconsCache
  if (template in cache)
    return cache[template]

  let db = ecs.g_entity_mgr.getTemplateDB()
  let sTpl = db.getTemplateByName(template)
  let offset = sTpl?.getCompValNullable("human_icon__offset") ?? Point2(0.0, -0.47)
  let res = {
    animchar = sTpl?.getCompValNullable("animchar__res")
    width = hdpx(sTpl?.getCompValNullable(isLarge ? "human_icon__widthLarge" : "human_icon__width") ?? 128)
    height = hdpx(sTpl?.getCompValNullable(isLarge ? "human_icon__heightLarge" : "human_icon__height") ?? 190)
    offsetX = offset.x
    offsetY = offset.y
    scale = sTpl?.getCompValNullable("human_icon__scale") ?? 2.2
    zenith = sTpl?.getCompValNullable("human_icon__zenith") ?? 65.0
    azimuth = sTpl?.getCompValNullable("human_icon__azimuth") ?? -40.0
    brightness = sTpl?.getCompValNullable("human_icon__brightness") ?? 4.0
  }

  if (db.size() > 0)
    cache[template] <- res
  return res
}

let attachCache = {}
let function getAttachmentParams(template) {
  if (template in attachCache)
    return attachCache[template]

  let db = ecs.g_entity_mgr.getTemplateDB()
  let tpl = db.getTemplateByName(template)

  let res = {
    isVisibleOnPhoto     = tpl != null && (tpl.getCompValNullable("isVisibleOnPhoto") ?? true)
    hideFlags            = tpl?.getCompValNullable("hideFlags").getAll() ?? []
    hides                = tpl?.getCompValNullable("hides").getAll() ?? []
    animchar             = tpl?.getCompValNullable("animchar__res")
    slotName             = tpl?.getCompValNullable("slot_attach__slotName")
    needAttach   = tpl?.getCompValNullable("skeleton_attach__attachedTo") != null
    paintColor = tpl?.getCompValNullable("paintColor")
    headgenTex0 = tpl?.getCompValNullable("headgen__tex0")
    headgenTex1 = tpl?.getCompValNullable("headgen__tex1")
    blendFactor = tpl?.getCompValNullable("headgen__blendFactor")
    objTexReplace = [tpl?.getCompValNullable("animchar__objTexReplace")?.getAll() ?? {}]
    objTexSet = [tpl?.getCompValNullable("animchar__objTexSet")?.getAll() ?? {}]
  }

  if (db.size() > 0)
    attachCache[template] <- res
  return res
}

local function mkSoldierPhotoName(soldierTemplate, equipment_, animation, isLarge = false) {
  // Sort by slot so that similar soldiers would end up using the same picture.
  let equipment = [].extend(equipment_).sort(@(a, b) a.slot <=> b.slot)
  animation = "enlisted_idle_01" // Always force the same animation to make soldiers look straight ahead.
  soldierTemplate = soldierTemplate ?? "usa_base_soldier"

  let attachments = [];
  let hides = {};
  foreach (equip in equipment)
    foreach (h in getAttachmentParams(equip.tpl).hides)
      hides[h] <- true

  foreach (equip in equipment) {
    let aParams = getAttachmentParams(equip.tpl)
    if (!aParams.isVisibleOnPhoto)
      continue
    if (aParams.hideFlags.findvalue(@(h) h in hides) != null)
      continue
    let paintColor = aParams?.paintColor
    let headgenReplace = aParams?.headgenTex0 && aParams?.headgenTex1 ?
      @"from:t=head_european_01_tex_d*;to:t={tex0}_d*;
      from:t=head_european_02_tex_d*;to:t={tex1}_d*;
      from:t=head_european_01_tex_n*;to:t={tex0}_n*;
      from:t=head_european_02_tex_n*;to:t={tex1}_n*;".subst({tex0 = aParams?.headgenTex0, tex1 = aParams?.headgenTex1}) : ""

    let objTexReplace = getTexReplaceString(aParams)
    let objTexSet = getTexSetString(aParams)
    attachments.append("a{animchar:t={animchar};slot:t={slot};shading:t=same;attachType:t={attachType};{objTexReplaceRules}{objTexSetRules}{paintColorParam}{blendFactor}}"
      .subst({
        animchar = aParams.animchar
        slot = aParams.slotName ?? equip.slot
        attachType = aParams.needAttach ? "skeleton" : "slot"
        objTexReplaceRules = "objTexReplaceRules{{0} r1{{1}}}".subst(objTexReplace, headgenReplace)
        objTexSetRules = "objTexSetRules{{0}} ".subst(objTexSet)
        paintColorParam = paintColor ? $"paintColor:p4={paintColor.x}, {paintColor.y}, {paintColor.z}, {paintColor.w};" : ""
        blendFactor = aParams?.blendFactor ? $"blendfactor:r={aParams?.blendFactor}" : ""
      }))
  }

  let tplParams = getSoldierParamsByTemplate(soldierTemplate, isLarge)
  let tbl = tplParams.__merge({
    attachments = attachments.len() > 0 ? "attachments{{0}}".subst("".join(attachments)) : "",
    animation
  })
  return @"ui/photo#render{
    animchar:t={animchar};offset:p2={offsetX},{offsetY};scale:r={scale};animation:t={animation};
    brightness:r={brightness};autocrop:b=false;zenith:r={zenith};azimuth:r={azimuth};{attachments}
    w:i={width};h:i={height};shading:t=full;}.render".subst(tbl)
}

let function mkSoldierPhoto(photoName, size, inner = null, style = {}) {
  if (photoName == null)
    return {
      size
      rendObj = ROBJ_IMAGE
      image = Picture("ui/soldiers/soldier_default.avif")
      clipChildren = true
      children = inner
    }.__update(style)

  return {
    children = [
      {
        size
        rendObj = ROBJ_IMAGE
        image = Picture("ui/soldiers/soldier_bg.avif")
      }.__update(style)
      {
        size
        rendObj = ROBJ_IMAGE
        image = Picture(photoName)
        clipChildren = true
        children = inner
      }.__update(style)
      {
        size = flex()
        rendObj = ROBJ_FRAME
        color = Color(85, 85, 85, 255)
        borderWidth = hdpx(1)
      }.__update(style)
    ]
  }
}

let mkSoldierPhotoWithoutFrame = @(photoName, size, style = {}) {
  size = [size[0], flex()]
  clipChildren = true
  children = {
    size
    rendObj = ROBJ_IMAGE
    image = Picture(photoName ?? "ui/soldiers/soldier_default.jpg")
    clipChildren = true
  }.__update(style)
}

return {
  mkSoldierPhotoName
  mkSoldierPhoto
  mkSoldierPhotoWithoutFrame
}
