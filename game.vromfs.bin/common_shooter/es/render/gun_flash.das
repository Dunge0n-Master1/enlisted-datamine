require ecs
require AnimV20
require GeomNodeTree
require DagorSystem
require math.base
require enlisted.events_enlisted
require DagorMath
require game.utils.hero
require DagorShaders

[es(tag=render, on_appear)]
def gun_flash_fx_init(evt : Event;
                      eid : EntityId;
                      animchar : AnimcharBaseComponent;
                      [[shared_comp]] gun_flash_fx__nodes : StringList;
                      [[shared_comp]] gun_flash_fx__template : StringList;
                      [[shared_comp]] gun_flash_fx__scale : FloatList;
                      var gun_flash_fx__nodeIds : IntList&)
  let numFx = length(gun_flash_fx__nodes)
  gun_flash_fx__nodeIds |> resize(numFx)
  if length(gun_flash_fx__template) != numFx || length(gun_flash_fx__scale) != numFx
    logerr("[{eid}] {getEntityTemplateName(eid)}: gun_flash_fx has wrong number of elements in lists")
  for id, node in gun_flash_fx__nodeIds, gun_flash_fx__nodes
    id = geomtree_findNodeIndex(*animchar.nodeTree, string(node))
    if id < 0
      logerr("[{eid}] {getEntityTemplateName(eid)}: gun_flash_fx node {node} not found")

[es(tag=render, on_event=(CmdNetShot, EventShot))]
def gun_flash_fx_on_shot(evt : Event;
                         eid : EntityId;
                         animchar : AnimcharBaseComponent;
                         animchar__visible : bool = true;
                         auto_gun_controller__enabled : bool = false;
                         [[shared_comp]] gun_flash_fx__template : StringList;
                         [[shared_comp]] gun_flash_fx__scale : FloatList;
                         gun_flash_fx__nodeIds : IntList;
                         gun__barrelTipNode : string = "gunFx_main";
                         gun__owner : EntityId = INVALID_ENTITY_ID;
                         gun_flash_fx__reflection_color : float3 = float3(-1.0, -1.0, -1.0);
                         gun_flash_fx__reflection_lifetime : float = -1.0;
                         gun_flash_fx__reflection_size : float = -1.0;
                         gun_flash_fx__reflection_strength : float = -1.0)
  if !animchar__visible && !auto_gun_controller__enabled
    return
  for nodeId, fxTemplate, scale in gun_flash_fx__nodeIds, gun_flash_fx__template, gun_flash_fx__scale
    if nodeId < 0
      continue
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, tm)
    for i in 0..3
      tm[i] *= scale
    createEntity(string(fxTemplate)) <| $(var init : ComponentsInitializer)
      init |> set("transform", tm)
      init |> set("gun_fx__gunEid", eid)
      init |> set("gun_fx__nodeId", nodeId)

  if gun__owner == get_controlled_hero()
    let barrelTipNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gun__barrelTipNode)
    if barrelTipNodeId >= 0
      var barrelTipTm : float3x4
      var rootTm : float3x4
      geomtree_getNodeWtmScalar(*animchar.nodeTree, 0, rootTm)
      geomtree_getNodeWtmScalar(*animchar.nodeTree, barrelTipNodeId, barrelTipTm)
      query() <| $ [es] (muzzle_flash_manager__base_effect_color : float3;
                         muzzle_flash_manager__base_effect_lifetime : float;
                         muzzle_flash_manager__base_effect_size : float;
                         muzzle_flash_manager__base_effect_stength : float;
                         muzzle_flash_manager__effect_offset : float;
                         var muzzle_flash_manager__effect_pos : float3&;
                         var muzzle_flash_manager__effect_lifetime : float&;
                         var muzzle_flash_manager__effect_color : float3&;
                         var muzzle_flash_manager__effect_stength : float&;
                         var muzzle_flash_manager__effect_size : float&)
        let offset = muzzle_flash_manager__effect_offset * normalize(barrelTipTm[3] - rootTm[3])
        muzzle_flash_manager__effect_pos = barrelTipTm[3] + offset
        if gun_flash_fx__reflection_lifetime >= 0.0
          muzzle_flash_manager__effect_lifetime = gun_flash_fx__reflection_lifetime
        else
          muzzle_flash_manager__effect_lifetime = muzzle_flash_manager__base_effect_lifetime
        if gun_flash_fx__reflection_color.x >= 0.0
          muzzle_flash_manager__effect_color = gun_flash_fx__reflection_color
        else
          muzzle_flash_manager__effect_color = muzzle_flash_manager__base_effect_color
        if gun_flash_fx__reflection_size >= 0.0
          muzzle_flash_manager__effect_size = gun_flash_fx__reflection_size
        else
          muzzle_flash_manager__effect_size = muzzle_flash_manager__base_effect_size
        if gun_flash_fx__reflection_strength >= 0.0
          muzzle_flash_manager__effect_stength = gun_flash_fx__reflection_strength
        else
          muzzle_flash_manager__effect_stength = muzzle_flash_manager__base_effect_stength

[es(on_appear, tag=render, REQUIRE=effect__name)]
def gun_flash_fx_init_es(evt : Event;
                         var transform : float3x4&;
                         gun_flash_fx__scaleMultiplier : float)
  transform = transform * scale_tm(gun_flash_fx__scaleMultiplier)

[es(tag=render, no_order)]
def gun_flash_fx_check_destruction_time(info : ParallelUpdateFrameDelayed; eid : EntityId; var gun_flash_fx__timeToDestroy : float&)
  gun_flash_fx__timeToDestroy -= info.dt
  if gun_flash_fx__timeToDestroy <= 0.
    destroyEntity(eid)

let
  analytic_light_sphere_pos_rVarId = get_shader_variable_id("analytic_light_sphere_pos_r", true)
  analytic_light_sphere_colorVarId = get_shader_variable_id("analytic_light_sphere_color", true)

[es(tag=render, after=gun_flash_fx_inserter_es)]
def set_gun_flash_analytic_sphere(info : UpdateStageInfoAct;
                                  muzzle_flash_manager__base_effect_lifetime : float;
                                  muzzle_flash_manager__effect_size : float;
                                  muzzle_flash_manager__fadeout : float;
                                  muzzle_flash_manager__effect_color : float3;
                                  muzzle_flash_manager__effect_pos : float3;
                                  muzzle_flash_manager__effect_stength : float;
                                  var muzzle_flash_manager__effect_lifetime : float&)
  muzzle_flash_manager__effect_lifetime -= info.dt
  let q = muzzle_flash_manager__effect_lifetime / muzzle_flash_manager__base_effect_lifetime
  let end_fadeout = 1.0 - saturate((q - muzzle_flash_manager__fadeout) / (1.0 - muzzle_flash_manager__fadeout))
  let effect_size = muzzle_flash_manager__effect_size * end_fadeout

  if (muzzle_flash_manager__effect_lifetime > 0.0)
    DagorShaders::set_color4(analytic_light_sphere_pos_rVarId,
                             muzzle_flash_manager__effect_pos.x, muzzle_flash_manager__effect_pos.y,
                             muzzle_flash_manager__effect_pos.z, effect_size)
    DagorShaders::set_color4(analytic_light_sphere_colorVarId,
                             muzzle_flash_manager__effect_color.x, muzzle_flash_manager__effect_color.y,
                             muzzle_flash_manager__effect_color.z, muzzle_flash_manager__effect_stength)
  else
    DagorShaders::set_color4(analytic_light_sphere_pos_rVarId, 0.0, 0.0, 0.0, 0.0)