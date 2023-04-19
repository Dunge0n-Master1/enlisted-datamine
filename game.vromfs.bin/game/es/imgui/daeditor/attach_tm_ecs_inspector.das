require ecs
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require imgui
require DagorMath
require daslib/safe_addr
require math.base


[ecs_inspector(field_name="seats_attach_nodes__attachTm", type_name="TMatrix")]
def draw_edit_seat_attach_nodes_tm(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float3x4?> refs[0].rawData)

  let rotMin = -180.0
  let rotMax = 180.0
  let rotStep = 1.0

  let posMin = -1.5
  let posMax = 1.5
  let posStep = 0.01

  var scale = float3(length((*val)[0]), length((*val)[1]), length((*val)[2]))
  var euler = float3(0.0)
  matrix_to_euler(*val, euler.x, euler.y, euler.z)

  euler = rad_to_deg(euler)

  imgui::Text("Scale: ")
  imgui::SameLine()
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}_0", unsafe(addr(scale.x)), "%.4f", ImGuiInputTextFlags None) || *changed

  imgui::Text("Rot: ")
  imgui::SameLine()
  SetNextItemWidth(-FLT_MIN)
  *changed = imgui::DragScalarN("##{name}_1", ImGuiDataType Float, unsafe(addr(euler.x)), 3,
    rotStep, safe_addr(rotMin), safe_addr(rotMax), "%.4f", ImGuiSliderFlags None) || *changed

  imgui::Text("Pos: ")
  imgui::SameLine()
  SetNextItemWidth(-FLT_MIN)
  *changed = imgui::DragScalarN("##{name}_2", ImGuiDataType Float, unsafe(addr((*val)[3].x)), 3,
    posStep, safe_addr(posMin), safe_addr(posMax), "%.4f", ImGuiSliderFlags None) || *changed

  euler = deg_to_rad(euler)

  var q : quat
  euler_to_quat(euler.x, euler.y, euler.z, q)
  var rotTm : float3x4
  make_tm(q, float3(0.0f, 0.0f, 0.0f), rotTm)

  rotTm[0] *= scale.x
  rotTm[1] *= scale.y
  rotTm[2] *= scale.z

  rotTm[3] = (*val)[3]

  (*val) = rotTm

  default_menu(eid, name, "TMatrix", $() => to_string(*val), $(str) { update_value(to_TMatrix(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)
