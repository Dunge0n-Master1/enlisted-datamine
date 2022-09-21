import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let mkIcon3d = require("%ui/components/icon3d.nut")
let { isHarmonizationEnabled } = require("%enlSqGlob/harmonizationState.nut")

let function applyHarmonizationImpl(template, objTexReplace, objTexSet) {
  let objTexHarmonize = template.getCompValNullable("animchar__objTexHarmonize")
  if (objTexHarmonize == null)
    return

  objTexReplace.append(objTexHarmonize?["animchar__objTexReplace"]?.getAll() ?? {})
  objTexSet.append(objTexHarmonize?["animchar__objTexSet"]?.getAll() ?? {})
}

let applyHarmonization = isHarmonizationEnabled.value ? applyHarmonizationImpl : @(...) null

let DB = ecs.g_entity_mgr.getTemplateDB()

let function mkDecorAnimchar(decor) {
  let animchar = DB.getTemplateByName(decor?.template)?.getCompValNullable("animchar__res")
  return decor.__merge(animchar ? { animchar } : {})
}

let function getIconInfoByGameTemplate(template, params = {}) {
  let reassign = @(value, key) key in params ? params[key] : value
  let decorators = template.getCompValNullable("attach_decorators__templates")?.getAll().map(mkDecorAnimchar)

  let objTexReplace = [template.getCompValNullable("animchar__objTexReplace")?.getAll() ?? {}]
  let objTexSet = [template.getCompValNullable("animchar__objTexSet")?.getAll() ?? {}]

  applyHarmonization(template, objTexReplace, objTexSet)

  return {
    iconName = template.getCompValNullable("animchar__res")
    objTexReplace
    objTexSet
    decorators
    iconPitch = reassign(template.getCompValNullable("item__iconPitch"), "itemPitch")
    iconYaw = reassign(template.getCompValNullable("item__iconYaw"), "itemYaw")
    iconRoll = reassign(template.getCompValNullable("item__iconRoll"), "itemRoll")
    iconOffsX = reassign(template.getCompValNullable("item__iconOffset")?.x, "itemOfsX")
    iconOffsY = reassign(template.getCompValNullable("item__iconOffset")?.y, "itemOfsY")
    iconScale = reassign(template.getCompValNullable("item__iconScale"), "itemScale")
    hideNodes = template.getCompValNullable("disableDMParts")?.getAll() ?? []
    paintColor = template.getCompValNullable("paintColor")
    headgenTex0 = template.getCompValNullable("headgen__tex0")
    headgenTex1 = template.getCompValNullable("headgen__tex1")
    blendFactor = template.getCompValNullable("headgen__blendFactor")
  }
}

let function icon3dByGameTemplate(gametemplate, params = {}) {
  if (gametemplate == null)
    return null
  let template = DB.getTemplateByName(gametemplate)
  if (template == null)
    return null
  let itemInfo = getIconInfoByGameTemplate(template, params)
  itemInfo.__update(params?.genOverride ?? {})
  return mkIcon3d(itemInfo, params, itemInfo?.iconAttachments)
}

return icon3dByGameTemplate