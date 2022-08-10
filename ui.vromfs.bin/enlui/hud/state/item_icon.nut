import "%dngscripts/ecs.nut" as ecs
let { Point2 } = require("dagor.math")

let itemIconQuery = ecs.SqQuery("itemIconQuery", {
  comps_ro = [
    ["animchar__res", ecs.TYPE_STRING, ""],
    ["item__iconYaw", ecs.TYPE_FLOAT, 0.0],
    ["item__iconPitch", ecs.TYPE_FLOAT, 0.0],
    ["item__iconRoll", ecs.TYPE_FLOAT, 0.0],
    ["item__iconOffset", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["item__iconScale", ecs.TYPE_FLOAT, 1.0],
  ]
})

let function getIconParams(itemEid) {
  return itemIconQuery(itemEid, function (_eid, comp) {
    return {
      iconName = comp["animchar__res"]
      iconYaw = comp["item__iconYaw"]
      iconPitch = comp["item__iconPitch"]
      iconRoll = comp["item__iconRoll"]
      iconOffsX = comp["item__iconOffset"].x
      iconOffsY = comp["item__iconOffset"].y
      iconScale = comp["item__iconScale"]
    }
  })
}

let itemTemplateQuery = ecs.SqQuery("itemTemplateQuery", {
  comps_ro = [
    ["item__template", ecs.TYPE_STRING, null],
    ["ammo_holder__templateName", ecs.TYPE_STRING, null]
  ]
})

let function getIconParamsByTemplate(itemEid) {
  if (itemEid == INVALID_ENTITY_ID)
    return {}
  let itemTempl =
    itemTemplateQuery(itemEid, @(_eid, comp) comp.item__template ?? comp.ammo_holder__templateName)
  if (itemTempl == null)
    return {}
  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(itemTempl)
  if (templ == null)
    return {}
  let iconOffset = templ.getCompValNullable("item__iconOffset") ?? Point2(0.0, 0.0)
  return {
    iconName = templ.getCompValNullable("animchar__res") ?? ""
    iconYaw = templ.getCompValNullable("item__iconYaw") ?? 0.0
    iconPitch = templ.getCompValNullable("item__iconPitch") ?? 0.0
    iconRoll = templ.getCompValNullable("item__iconRoll") ?? 0.0
    iconOffsX = iconOffset.x
    iconOffsY = iconOffset.y
    iconScale = templ.getCompValNullable("item__iconScale") ?? 1.0
  }
}

return {
  getIconParams
  getIconParamsByTemplate
}