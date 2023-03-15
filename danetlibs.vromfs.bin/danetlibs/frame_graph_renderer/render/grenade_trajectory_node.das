
require FrameGraph
require DagorShaders
require DagorMath
require danetlibs/frame_graph_renderer/render/node_macro
require ecs

struct Trajectory
  start, vel : float3
  time, gravity, wideStart, wideEnd, colorGamma : float
  center, border : Color4

def render_grenade_trajectory(t : Trajectory)
  let numSegments = clamp(int(4. + t.time * 24.), 2, 512)
  query() <| $ [es] (trajectory_start_gravity : ShaderVar;
                     trajectory_vel_time : ShaderVar;
                     trajectory_center : ShaderVar;
                     trajectory_border : ShaderVar;
                     trajectory_total_thickness_gamma : ShaderVar)
    DagorShaders::set_color4(trajectory_start_gravity.varId, t.start, t.gravity)
    DagorShaders::set_color4(trajectory_vel_time.varId, t.vel, t.time)
    DagorShaders::set_color4(trajectory_center.varId, t.center)
    DagorShaders::set_color4(trajectory_border.varId, t.border)
    DagorShaders::set_color4(trajectory_total_thickness_gamma.varId, float(numSegments), t.wideStart, t.wideEnd, t.colorGamma)
  d3d_draw(PRIM_TRISTRIP, 0, 2 * numSegments)

def render_grenade_trajectories()
  var statesSet = false
  query() <| $ [es] (trajectory__start : float3;
                     trajectory__vel : float3;
                     trajectory__time : float;
                     trajectory__enabled : bool;
                     trajectory__center : E3DCOLOR const?;
                     trajectory__border : E3DCOLOR const?;
                     trajectory__wide_start : float = 0.3;
                     trajectory__wide_end : float = 0.2;
                     trajectory__color_gamma : float = 8.;
                     trajectory__gravity : float = 9.81)
    let centerColor = Color4(trajectory__center ?? E3DCOLOR(0xFFFFFFFF))
    let borderColor = Color4(trajectory__border ?? E3DCOLOR(0x7F7FFFFF))
    if (!trajectory__enabled || (borderColor.a == 0.0 && centerColor.a == 0.0))
      return

    if (!statesSet)
      d3d_setvsrc(0, null, 0)
      query() <| $ [es] (trajectory_renderer_shader : ShadersECS)
        setStates(trajectory_renderer_shader)
      statesSet = true

    render_grenade_trajectory([[Trajectory
                                start=trajectory__start,
                                vel=trajectory__vel,
                                time=trajectory__time,
                                gravity=trajectory__gravity,
                                wideStart=trajectory__wide_start,
                                wideEnd=trajectory__wide_end,
                                colorGamma=trajectory__color_gamma,
                                center=centerColor,
                                border=borderColor]])

def is_forward_render()
  return find_query() <| $ [es] (render_settings__forwardRendering : bool)
    return render_settings__forwardRendering

[frame_graph_node]
class GrenadeTrajectoryNode : FrameGraphNode
  globalFrameBlockId = getBlockId("global_frame")

  def override onDeviceReset() : void { pass; }

  def override declareResources(registrar : ResourceRegistrar)
    if is_forward_render()
      registrar |> modifyResource(string_view("target_after_transparent_scene_late"))
      registrar |> bindResourceToShaderVar(string_view("depth_gbuf"),
                                           string_view("depth_for_transparent_effects"),
                                           ResourceUsageStage POST_RASTER,
                                           false)
    else
      registrar |> addPreviousNode(string_view("transparent_scene_late_node"))
      registrar |> addFollowNode(string_view("after_world_render_node"))
      registrar |> bindResourceToShaderVar(string_view("downsampled_far_depth_tex"),
                                           string_view("far_downsampled_depth"),
                                           ResourceUsageStage POST_RASTER,
                                           false)

  [unused_argument(accessor)] def override execute(accessor : ResourceAccessor)
    d3d_set_depth(null, false)
    ecs::query() <| $ [es] (render_settings__forwardRendering : bool)
      if render_settings__forwardRendering
        DagorShaders::setBlock(-1, LAYER_FRAME)

    render_grenade_trajectories()
