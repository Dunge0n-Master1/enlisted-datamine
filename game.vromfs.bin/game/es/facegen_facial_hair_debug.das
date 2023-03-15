options no_aot
require ecs
require DagorRandom
require DagorConsole
require DagorSystem
require DagorDataBlock
require enlisted.game.es.blk_utils_common
require enlisted.events_enlisted
require ecs.common

def find_head_eid_in_scene()
  var attachableHeadEid = INVALID_ENTITY_ID
  var headCount = 0
  query() <| $ [es(REQUIRE=(isAttachableHead, animchar__res)) ] (eid : EntityId)
    attachableHeadEid = eid
    headCount++
  if headCount > 1
    logerr("for correctly work of faceGen must be only one head entity on scene")
    return INVALID_ENTITY_ID
  return attachableHeadEid

def facegen_facial_hair(seed : int;
                        beard : int = -1;
                        mustache : int = -1)
  var resSeed = seed
  let attachableHeadEid = find_head_eid_in_scene()
  query(attachableHeadEid) <| $ [es] (var beard_id, mustache_id : int&;
                                      facial_hairs, headgen__beards, headgen__mustaches : StringList)
    let facial_nodes_count = length(facial_hairs)
    for i in range(facial_nodes_count)
      let nodeName = string(facial_hairs[i])
      if nodeName == "beard"
        beard_id = beard < 0 ? (beard + rnd_int(0, 1) >= 0 ? _rnd_int(resSeed, 0, length(headgen__beards) - 1) : -1) : beard
      elif nodeName == "mustache"
        mustache_id = mustache < 0 ? (mustache + rnd_int(0, 1) >= 0 ? _rnd_int(resSeed, 0, length(headgen__mustaches) - 1) : -1) : mustache

[console_cmd(name="faceGen2.regenOnlyFacialSkin")]
def facegen_facial_hair_command(beard : int = -1;
                                mustache : int = -1)
  facegen_facial_hair(get_rnd_seed(), beard, mustache)

[console_cmd(name="faceGen2.regenOnlyFacialSkinWithSeed")]
def facegen_facial_hair_with_seed_command(seed : int)
  facegen_facial_hair(seed)

[console_cmd(name="faceGen2.regenFullRandom")]
def facegen_reinit_full_random()
  console_command("faceGen2.regenOnlyTex")
  console_command("faceGen2.regenOnlyBlendFactor")
  console_command("faceGen2.regenOnlyFacialSkin")
  console_command("faceGen2.regenOnlyMesh")

[console_cmd(name="faceGen2.regenFullRandomWithSeed")]
def facegen_reinit_full_random(seed : int)
  console_command("faceGen2.regenOnlyTexWithSeed {seed}")
  console_command("faceGen2.regenOnlyBlendFactorWithSeed {seed}")
  console_command("faceGen2.regenOnlyFacialSkinWithSeed {seed}")
  console_command("faceGen2.regenOnlyMeshWithSeed {seed}")

def facegen_regen_tex_with_seed(seed : int;
                                tex0_init : string = "";
                                tex1_init : string = "")
  var resSeed = seed
  let attachableHeadEid = find_head_eid_in_scene()
  query(attachableHeadEid) <| $ [es] (headgen__skins : StringList;
                                      var headgen__tex0 : das_string&;
                                      var headgen__tex1 : das_string&)
    if headgen__tex0 != "" && headgen__tex0 == headgen__tex1
      logerr("tex must be different")
      return
    let headgenSkinsCount = length(headgen__skins)
    let firstTex = tex0_init != "" ? find_index(headgen__skins, tex0_init) : _rnd_int(resSeed, 0, headgenSkinsCount - 1)
    var secondTex = tex1_init != "" ? find_index(headgen__skins, tex1_init) : _rnd_int(resSeed, 0, headgenSkinsCount - 2)
    if firstTex < 0 || secondTex < 0
      logerr("invalid tex name")
      return
    if secondTex >= firstTex
      secondTex++;
    headgen__tex0 := headgen__skins[firstTex]
    headgen__tex1 := headgen__skins[secondTex]

[console_cmd(name="faceGen2.regenOnlyTex")]
def facegen_regen_tex(tex0_init : string = "";
                      tex1_init : string = "")
  facegen_regen_tex_with_seed(get_rnd_seed(), tex0_init, tex1_init)

[console_cmd(name="faceGen2.regenOnlyTexWithSeed")]
def facegen_regen_tex_seed(seed : int)
  facegen_regen_tex_with_seed(seed)

def facegen_regen_blend_factor_with_seed(seed : int;
                                         blend_factor : float = -1.f)
  var resSeed = seed
  let attachableHeadEid = find_head_eid_in_scene()
  query(attachableHeadEid) <| $ [es] (var headgen__blendFactor : float&)
    headgen__blendFactor = blend_factor >= 0.f ? blend_factor : _rnd_float(resSeed, 0.f, 1.f)

[console_cmd(name="faceGen2.regenOnlyBlendFactor")]
def facegen_regen_blend_factor(blend_factor : float = -1.f)
  facegen_regen_blend_factor_with_seed(get_rnd_seed(), blend_factor)

[console_cmd(name="faceGen2.regenOnlyBlendFactorWithSeed")]
def facegen_regen_blend_factor_seed(seed : int)
  facegen_regen_blend_factor_with_seed(seed)

[console_cmd(name="faceGen2.saveCurrentFace")]
def saveCurrentFace()
  let attachableHeadEid = find_head_eid_in_scene()
  sendEvent(attachableHeadEid, [[faceGenSaveInfo initialSave = false]])

def reload_head_entity_anim(head_eid : EntityId; template_name : string; save_mesh_res : bool)
  //recreate to entity without animchar/collres/physvars to init at second recreate in CB
  var templ = clone_string(template_name)
  let cb <- @ <| [[ <- templ]] (reid : EntityId)
    reCreateEntityFrom(reid, templ)

  var headBaseItemTemplate = "head_gen_base_item"
  var headBaseTemplate = "head_gen_base"
  query() <| $ [es(REQUIRE=nft_equip__seed)] (nft__head_gen_base_item_template : string;
                                              nft_head_gen_base_template : string)
    headBaseItemTemplate := nft__head_gen_base_item_template
    headBaseTemplate := nft_head_gen_base_template
  let recreateTo = save_mesh_res ? headBaseItemTemplate : headBaseTemplate
  reCreateEntityFrom(head_eid, recreateTo, cb) <| $ [unused_argument(init)] (var init) {}

[console_cmd(name="faceGen2.editFaceTemplate")]
def facegen_edit_template(template_name : string)
  let attachableHeadEid = find_head_eid_in_scene()
  if !attachableHeadEid
    return
  console_command("ecs.reload_templates")
  reload_head_entity_anim(attachableHeadEid, template_name, false)

def facegen_regen_mesh(seed : int;
                       mesh_name : string = "")
  let attachableHeadEid = find_head_eid_in_scene()
  if !attachableHeadEid
    return
  var resSeed = seed
  query(attachableHeadEid) <| $ [es] (face_gen__animcharRes : StringList;
                                      var animchar__res : das_string&;
                                      var collres__res : das_string&)
    let animcharResCount = length(face_gen__animcharRes)
    let resId = mesh_name != "" ? find_index(face_gen__animcharRes, mesh_name) : _rnd_int(resSeed, 0, animcharResCount - 1)
    animchar__res := "{face_gen__animcharRes[resId]}_char"
    collres__res := "{face_gen__animcharRes[resId]}_collision"
    let curTemplate = getEntityTemplateName(attachableHeadEid)
    let templatesArr <- split_template(curTemplate)
    reload_head_entity_anim(attachableHeadEid, templatesArr[0], true)

[console_cmd(name="faceGen2.regenOnlyMesh")]
def facegen_regen_mesh_command(mesh_name : string = "")
  facegen_regen_mesh(get_rnd_seed(), mesh_name)

[console_cmd(name="faceGen2.regenOnlyMeshWithSeed")]
def facegen_regen_mesh_command(seed : int)
  facegen_regen_mesh(seed)

def get_base_facegen_template_path()
  let baseTemplate = getTemplateByName("headgen_components")
  if baseTemplate == null
    logerr("headgen_components isn't inited in templates")
    return ""
  return getTemplatePath(*baseTemplate)

[console_cmd(name="faceGen2.createNewFaceTemplate", hint="will save at file containing headgen_components template")]
def facegen_create_new_template(template_name : string)
  let attachableHeadEid = find_head_eid_in_scene()
  if !attachableHeadEid
    return

  let templatePath = get_base_facegen_template_path()
  if templatePath == ""
    return
  using() <| $(var blk : DataBlock)
    datablock_load(blk, templatePath)
    if datablock_get_block_by_name(blk, template_name) != null
      logerr("template name {template_name} already exist")
      return

    blk |> datablock_add_new_block(template_name) <| $(new_template)
      new_template |> set("_extends", "head_gen_base_item")
    datablock_save_to_text_file(blk, templatePath)

    console_command("ecs.reload_templates")
    reCreateEntityFrom(attachableHeadEid, "{template_name}+head_gen_regen_info+head_gen_save_info")

[es(on_event=faceGenInfoUpdated, REQUIRE=head_gen__saveInfo, tag=render)]
def save_info_for_new_facegen_template(evt : Event;
                                       eid : EntityId)
  removeSubTemplate(eid, "head_gen_regen_info")
  sendEvent(eid, [[faceGenSaveInfo initialSave = true]])

[es(on_appear, REQUIRE=animchar, tag=render)]
def init_additive_templates_for_nft_template(evt : Event;
                                             eid : EntityId;
                                             additive_eyes_tampletes_list : StringList;
                                             additive_scar_tampletes_list : StringList)
  query() <| $ [es] (nft_equip__seed : int)
    var resSeed = nft_equip__seed
    let eyesTemplId = _rnd_int(resSeed, 0, length(additive_eyes_tampletes_list) - 1)
    let scarTemplId = _rnd_int(resSeed, 0, length(additive_scar_tampletes_list) - 1)
    addSubTemplate(eid, string(additive_eyes_tampletes_list[eyesTemplId]))
    addSubTemplate(eid, string(additive_scar_tampletes_list[scarTemplId]))

[es(tag=render)]
def save_info_for_facegen(evt : faceGenSaveInfo;
                          eid : EntityId;
                          headgen__blendFactor : float;
                          headgen__tex0 : string;
                          headgen__tex1 : string;
                          animchar__res : string;
                          collres__res : string;
                          beard_id, mustache_id : int)
  let templateName = getEntityTemplateName(eid)

  let templatesArr <- split_template(templateName)
  let baseTemplate = templatesArr[0]

  let templatePath = get_base_facegen_template_path()
  if templatePath == ""
    return
  using() <| $(var blk : DataBlock)
    datablock_load(blk, templatePath)
    datablock_get_block(blk, baseTemplate) <| $(originTemplate)
      if evt.initialSave
        originTemplate |> add("_extends", "base_collres_vis_item")
        originTemplate |> add("_extends", "head_gen_animphys")
        originTemplate |> add("_extends", "animchar")
      originTemplate |> set("headgen__tex0", headgen__tex0)
      originTemplate |> set("headgen__tex1", headgen__tex1)
      originTemplate |> set("animchar__res", animchar__res)
      originTemplate |> set("collres__res", collres__res)
      originTemplate |> set("beard_id", beard_id)
      originTemplate |> set("mustache_id", mustache_id)
      originTemplate |> set("headgen__blendFactor", headgen__blendFactor)
      datablock_save_to_text_file(blk, templatePath)

