import "%dngscripts/ecs.nut" as ecs
let { apply_customization=@(_t,_l,c) c, get_menu_character_template=@(_) null } = require_optional("playerCustomization")
let function destroyChar(char) {
  if (char != ecs.INVALID_ENTITY_ID)
    ecs.g_entity_mgr.destroyEntity(char)
}

let function onInit(_myEid, comp) {
  destroyChar(comp["menu_char_controller__characterToControl"])

  if (!comp["menu_char_controller__show"])
    return

  let comps = {
    "transform" : [comp.transform, ecs.TYPE_MATRIX],
  }
  let itemslist = comp["menu_char_controller__itemsList"].getAll()
  let templ = get_menu_character_template(itemslist) ?? comp["menu_char_controller__characterTemplate"]
  if (templ == "")
    return // do not create anything is we don't even have a template
  let modComps = apply_customization(templ, itemslist, comps)
  comp["menu_char_controller__ignoreComponents"].getAll().each(function(field){
    if (field in modComps)
      delete modComps[field]
  })
  modComps["menu_animchar__uid"] <- comp["menu_char_controller__uid"]
  comp["menu_char_controller__characterToControl"] = ecs.g_entity_mgr.createEntity(templ, modComps)
}

ecs.register_es("menu_char_controller_es", {
  onInit = onInit,
  onChange = onInit,
  onDestroy = @(_eid, comp) destroyChar(comp["menu_char_controller__characterToControl"])
}, {
  comps_rw = [
    ["menu_char_controller__characterToControl", ecs.TYPE_EID],
  ],
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["menu_char_controller__ignoreComponents", ecs.TYPE_STRING_LIST],
    ["menu_char_controller__uid", ecs.TYPE_INT],
  ]
  comps_track = [
    ["menu_char_controller__characterTemplate", ecs.TYPE_STRING],
    ["menu_char_controller__itemsList", ecs.TYPE_ARRAY],
    ["menu_char_controller__show", ecs.TYPE_BOOL, true],
  ]
},
{tags="gameClient"})

