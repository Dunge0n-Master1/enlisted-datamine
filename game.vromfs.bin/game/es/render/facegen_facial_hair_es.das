require ecs
require AnimV20
require ecs.common
require DagorRandom
require enlisted.events_enlisted
require MaterialRecreate
require DagorTexture3D
require DagorMath

[es(on_appear, REQUIRE=head_gen__regenInfo, tag=render, before=(init_facegen_tex_names_es, facegen_facial_haier_es))]
def init_facegen_facial_es(evt : Event;
                           var beard_id, mustache_id : int&;
                           headgen__beards, headgen__mustaches : StringList)
  beard_id = rnd_int(0, 1) > 0 ? rnd_int(0, length(headgen__beards) - 1) : -1
  mustache_id = rnd_int(0, 1) > 0 ? rnd_int(0, length(headgen__mustaches) - 1) : -1

[es(on_appear, REQUIRE=head_gen__regenInfo, tag=render, before=init_facegen_material_es)]
def init_facegen_tex_names_es(evt : Event;
                              headgen__skins : StringList;
                              var headgen__blendFactor : float&;
                              var headgen__tex0 : das_string&;
                              var headgen__tex1 : das_string&)
  let headgenSkinsCount = length(headgen__skins)
  let firstTex = rnd_int(0, headgenSkinsCount - 1)
  var secondTex = rnd_int(0, headgenSkinsCount - 2)
  if secondTex >= firstTex
    secondTex++
  headgen__tex0 := headgen__skins[firstTex]
  headgen__tex1 := headgen__skins[secondTex]
  headgen__blendFactor = rnd_float(0.f, 1.f)

[es(on_appear, REQUIRE=head_gen__regenInfo, tag=render, before=init_facegen_material_es)]
def init_animchar_res_name_es(evt : Event;
                              face_gen__animcharRes : StringList;
                              var animchar__res : das_string&;
                              var collres__res : das_string&)
  let animcharResCount = length(face_gen__animcharRes)
  let randResId = rnd_int(0, animcharResCount - 1)
  animchar__res := "{face_gen__animcharRes[randResId]}_char"
  collres__res := "{face_gen__animcharRes[randResId]}_collision"

[es(on_appear, REQUIRE_NOT=animchar, REQUIRE=head_gen__regenInfo, tag=render, after=init_facegen_tex_names_es)]
def init_animchar_for_facegen(evt : Event;
                              eid : EntityId)
  addSubTemplate(eid, "base_collres_vis_item")
  addSubTemplate(eid, "head_gen_animphys")
  removeSubTemplate(eid, "head_gen_regen_info")
  sendEvent(eid, [[faceGenInfoUpdated]])


[es(tag=render, on_appear, REQUIRE=animchar, track=(headgen__blendFactor, headgen__tex0, headgen__tex1))]
def init_facegen_material_es(evt : Event;
                             var animchar_render : AnimcharRendComponent;
                             headgen__blendFactor : float;
                             var headgen_diffuse0, headgen_diffuse1, headgen_normal0, headgen_normal1 : SharedTex&;
                             headgen__tex0, headgen__tex1 : das_string)

  let skinBlendVarId = get_shader_variable_id("skin_blend", false)

  get_tex_gameres(headgen_diffuse0, "{headgen__tex0}_d")
  get_tex_gameres(headgen_diffuse1, "{headgen__tex1}_d")
  get_tex_gameres(headgen_normal0, "{headgen__tex0}_n")
  get_tex_gameres(headgen_normal1, "{headgen__tex1}_n")

  recreate_material(animchar_render, "dynamic_blended_skin") <| $(mat)
    mat |> set_real_param(skinBlendVarId, headgen__blendFactor);
    mat |> set_texture(0, headgen_diffuse0.getTexId);
    mat |> set_texture(2, headgen_diffuse1.getTexId);
    mat |> set_texture(3, headgen_normal0.getTexId);
    mat |> set_texture(4, headgen_normal1.getTexId);



[es(tag=render, on_appear, REQUIRE=animchar,
  track=(eye_caustics_strength, eye_caustics_light_lerp_factor, eye_caustics_focal_point_offset, // eye caustics params are really difficult to fine tune otherwise
  eye_caustics_iris_radius, eye_caustics_falloff_strength, eye_caustics_concavity_scale))]
def init_eye_material_es(evt : Event;
                         var animchar_render : AnimcharRendComponent;
                         eye_iris_color_a_from, eye_iris_color_a_to, eye_iris_color_b_from, eye_iris_color_b_to, eye_sclera_color_from, eye_sclera_color_to : float4;
                         eye_iris_radius, eye_parallax, eye_reflectance, eye_smoothness,
                         eye_caustics_strength, eye_caustics_light_lerp_factor, eye_caustics_focal_point_offset,
                         eye_caustics_iris_radius, eye_caustics_falloff_strength, eye_caustics_concavity_scale : float)

  let eyesVarId : array<int> <- [{ auto[]
    get_shader_variable_id("eye_iris_color_a_from", false);
    get_shader_variable_id("eye_iris_color_a_to", false);
    get_shader_variable_id("eye_iris_color_b_from", false);
    get_shader_variable_id("eye_iris_color_b_to", false);
    get_shader_variable_id("eye_sclera_color_from", false);
    get_shader_variable_id("eye_sclera_color_to", false);
    get_shader_variable_id("eye_iris_radius", false);
    get_shader_variable_id("eye_parallax", false);
    get_shader_variable_id("eye_reflectance", false);
    get_shader_variable_id("eye_smoothness", false);
    get_shader_variable_id("eye_caustics_strength", false);
    get_shader_variable_id("eye_caustics_light_lerp_factor", false);
    get_shader_variable_id("eye_caustics_focal_point_offset", false);
    get_shader_variable_id("eye_caustics_iris_radius", false);
    get_shader_variable_id("eye_caustics_falloff_strength", false);
    get_shader_variable_id("eye_caustics_concavity_scale", false)
  }]

  recreate_material(animchar_render, "dynamic_eye") <| $(mat)
    mat |> set_color4_param(eyesVarId[0], Color4(eye_iris_color_a_from))
    mat |> set_color4_param(eyesVarId[1], Color4(eye_iris_color_a_to))
    mat |> set_color4_param(eyesVarId[2], Color4(eye_iris_color_b_from))
    mat |> set_color4_param(eyesVarId[3], Color4(eye_iris_color_b_to))
    mat |> set_color4_param(eyesVarId[4], Color4(eye_sclera_color_from))
    mat |> set_color4_param(eyesVarId[5], Color4(eye_sclera_color_to))
    mat |> set_real_param(eyesVarId[6], eye_iris_radius)
    mat |> set_real_param(eyesVarId[7], eye_parallax)
    mat |> set_real_param(eyesVarId[8], eye_reflectance)
    mat |> set_real_param(eyesVarId[9], eye_smoothness)
    mat |> set_real_param(eyesVarId[10], eye_caustics_strength)
    mat |> set_real_param(eyesVarId[11], eye_caustics_light_lerp_factor)
    mat |> set_real_param(eyesVarId[12], eye_caustics_focal_point_offset)
    mat |> set_real_param(eyesVarId[13], eye_caustics_iris_radius)
    mat |> set_real_param(eyesVarId[14], eye_caustics_falloff_strength)
    mat |> set_real_param(eyesVarId[15], eye_caustics_concavity_scale)


[es(on_appear, tag=render, track=(beard_id, mustache_id))]
def facegen_facial_haier_es(
                            evt : Event;
                            eid : EntityId;
                            var attaches_list : EidList&;
                            beard_id, mustache_id : int;
                            facial_hairs, headgen__beards, headgen__mustaches : StringList
                            )

  let facial_nodes_count = length(facial_hairs)
  for i in range(facial_nodes_count)

    for attach_eid in attaches_list
      let result = query(attach_eid) <| $ [es] (slot_attach__slotName : das_string&)
        if facial_hairs[i] == slot_attach__slotName
          destroyEntity(attach_eid)

    let hairId = i == 0 ? beard_id : mustache_id
    if hairId >= 0
      let hairName = i == 0 ? string(headgen__beards[hairId]) : string(headgen__mustaches[hairId])
      let facialHair = createEntity("attachable_facial_hairs") <| $(init)
        init |> set("slot_attach__slotName", facial_hairs[i])
        init |> set("slot_attach__attachedTo", eid)
        init |> set("skeleton_attach__attachedTo", eid)
        init |> set("skeleton_attach__attached", true)
        init |> set("animchar__res",  "{hairName}_char")
        init |> set("collres__res", "{hairName}_collision")
      attaches_list |> push(facialHair)

[es(on_disappear, tag=render, REQUIRE=facial_hairs)]
def destroy_facial_hairs(
                         evt : Event;
                         attaches_list : EidList)

  for eid in attaches_list
    destroyEntity(eid)
