require ecs
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require imgui
require daslib/safe_addr


[unused_argument(level)]
def draw_float4_as_color(eid : array<EntityId> const#; name, typeName : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val : float4?
  unsafe
    val = reinterpret<float4?> ref.rawData
  var color = [[float[4] (*val).x; (*val).y; (*val).z; (*val).w]]
  SetNextItemWidth(-FLT_MIN)
  if ColorEdit4("##{name}", safe_addr(color[0]), ImGuiColorEditFlags Float)
    *changed = true
    (*val).x = color[0]
    (*val).y = color[1]
    (*val).z = color[2]
    (*val).w = color[3]
  default_menu(eid, name, typeName, $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="Point4", tag="color_grading")]
def draw_postfx_vectors(eid : array<EntityId> const#; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  draw_float4_as_color(eid, name, "Point4", ref, level, changed, sub_menu)


[ecs_inspector(type_name="Point4", tag="edit_color_grading")]
def draw_edit_color_grading_vectors(eid : array<EntityId> const#; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  draw_float4_as_color(eid, name, "Point4", ref, level, changed, sub_menu)