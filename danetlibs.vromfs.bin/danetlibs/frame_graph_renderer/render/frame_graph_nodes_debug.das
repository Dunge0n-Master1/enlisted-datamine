options no_aot
require FrameGraph
require DagorSystem
require DagorShaders
require DagorMath
require WorldRenderer
require danetlibs/frame_graph_renderer/render/node_macro
require ecs
require DagorConsole

def is_forward_rendering()
  return find_query() <| $ [es] (render_settings__forwardRendering : bool)
    return render_settings__forwardRendering

[frame_graph_node]
class DebugVisualizationNode : FrameGraphNode

  def override onDeviceReset() : void { pass; }

  def override declareResources(registrar : ResourceRegistrar)
    if is_forward_rendering()
      registrar |> modifyResource(string_view("target_after_under_water_fog"))
    else
      registrar |> addPreviousNode(string_view("transparent_effects_node"))
      registrar |> addFollowNode(string_view("transparent_scene_late_node"))
    registrar |> setShaderBlockToLayer(ShaderBlockLayer LAYER_FRAME, string_view("global_frame"))

  [unused_argument(accessor)] def override execute(accessor : ResourceAccessor)
    worldRenderer_renderDebug()


//writes into 1-st gbuffer RT with RGB Write mask
[frame_graph_node]
class GbufferDiffuseOverride : FrameGraphNode
  eid : EntityId

  def override onDeviceReset() : void { pass; }

  def override declareResources(registrar : ResourceRegistrar)
    eid = getSingletonEntity("gbuffer_diffuse_override_debug_node")

    registrar |> addPreviousNode(string_view("combine_shadows_node"))
    registrar |> addFollowNode(string_view("resolve_gbuffer_node"))
    registrar |> requestState() <| $(var requirements : NodeStateRequirements#)
      requirements |> set_render_override([[OverrideRenderState colorWr = WriteMask RGB]])

  [unused_argument(accessor)] def override execute(accessor : ResourceAccessor)
    query(eid) <| $ [es] (debug_fill_gbuffer : PostFxRenderer; debug_fill_color : float4)
      __scope_render_target() <| $()
        set_color4(get_shader_variable_id("gbuffer_fix_color", true), debug_fill_color)
        set_int(get_shader_variable_id("debug_fix_gbuffer", true), 0)
        debug_fill_gbuffer |> render()



//writes into 3-rd gbuffer RT with GREEN Write mask
[frame_graph_node]
class GbufferSpecularOverride : FrameGraphNode
  eid : EntityId

  def override onDeviceReset() : void { pass; }

  def override declareResources(registrar : ResourceRegistrar)
    eid = getSingletonEntity("gbuffer_specular_override_debug_node")

    registrar |> addPreviousNode(string_view("combine_shadows_node"))
    registrar |> addFollowNode(string_view("resolve_gbuffer_node"))
    registrar |> requestState() <| $(var requirements : NodeStateRequirements#)
      requirements |> set_render_override([[OverrideRenderState colorWr = WriteMask GREEN]])

  [unused_argument(accessor)] def override execute(accessor : ResourceAccessor)
    query(eid) <| $ [es] (debug_fill_gbuffer : PostFxRenderer; debug_fill_color : float4)
      __scope_render_target() <| $()
        set_color4(get_shader_variable_id("gbuffer_fix_color", true), debug_fill_color)
        set_int(get_shader_variable_id("debug_fix_gbuffer", true), 2)
        debug_fill_gbuffer |> render()


[es(on_event=BeforeLoadLevel)]
def init_debug_nodes(evt : Event)
  createEntity("debug_visualization_node")


def update_debug_entity(enable : bool; color : float; templ : string)

  if is_forward_rendering()
    return

  var eid = getSingletonEntity(templ)
  if !enable && eid != INVALID_ENTITY_ID
    destroyEntity(eid)
  if enable
    if !eid
      eid = createEntity(templ) <| $(init)
        set(init, "debug_fill_color", float4(color))
    else
      query(eid) <| $ [es] (var debug_fill_color : float4&)
        debug_fill_color = float4(color)

[console_cmd(name="render.fixedDiffuse")]
def const_diffuse(enable : bool; shade_of_gray : float = 0.5f)
  update_debug_entity(enable, shade_of_gray, "gbuffer_diffuse_override_debug_node")


[console_cmd(name="render.noSpecular")]
def const_specular(enable : bool)
  update_debug_entity(enable, 0f, "gbuffer_specular_override_debug_node")
