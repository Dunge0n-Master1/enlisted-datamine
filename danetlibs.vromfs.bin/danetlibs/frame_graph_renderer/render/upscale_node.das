
require FrameGraph
require DagorShaders
require danetlibs/frame_graph_renderer/render/node_macro
require danetlibs/renderer/includes/upscale_sampling
require ecs

let
  upscale_sampling_texVarId = get_shader_variable_id("upscale_sampling_tex", false)

[frame_graph_node]
class UpscaleTexGenerationNode : FrameGraphNode
  globalFrameBlockId = getBlockId("global_frame")

  def override declareResources(registrar : ResourceRegistrar)
    registrar |> addPreviousNode(string_view("prepare_lights_node"))
    registrar |> addFollowNode(string_view("combine_shadows_node"))

    registrar |> requestInputResource(string_view("checkerboard_depth"), true)

    using() <| $(var desc : TextureResourceDescription#)
      desc.activation = ResourceActivationAction DISCARD_AS_RTV_DSV
      desc.cFlags = TEXCF_RTARGET | TEXFMT_R8
      desc.mipLevels = 1u
      registrar |> createRenderTarget(string_view("upscale_sampling_tex"), desc, ResolutionType MainView)

  def override execute(accessor : ResourceAccessor)
    query() <| $ [es] (upscale_shader : PostFxRenderer)
      let upscaleSamplingTex = accessor |> getTexture(string_view("upscale_sampling_tex"))

      setBlock(globalFrameBlockId, LAYER_FRAME)
      upscale_render(upscaleSamplingTex.getTex2D, upscale_shader)
      set_texture(upscale_sampling_texVarId, upscaleSamplingTex.getTexId)

  def override onDeviceReset()
    query() <| $ [es] (var upscale_weights_buffer : UniqueBufHolder)
      upload_weights(upscale_weights_buffer)

[cpp_event(broadcast)]
struct OnRenderSettingsReady {}

[es(on_event=OnRenderSettingsReady, track=render_settings__upscaleSamplingTex)]
def init_upscale_node(evt : Event; render_settings__upscaleSamplingTex : bool)
  if render_settings__upscaleSamplingTex
    createEntitySync("upscale_node")//we should create this entity sync, because framegraph requere to know about this node immediately

    //need to init buffers after entity creation, because we can have acces to it onDeviceReset before declareResources
    query() <| $ [es] (var upscale_weights_buffer : UniqueBufHolder)
      init_upscale(upscale_weights_buffer)
      upload_weights(upscale_weights_buffer)
  else
    destroyEntity(getSingletonEntity("upscale_node"))
    // TODO: replace with FG-based shadervar tracking
    set_texture(upscale_sampling_texVarId, BAD_TEXTUREID)