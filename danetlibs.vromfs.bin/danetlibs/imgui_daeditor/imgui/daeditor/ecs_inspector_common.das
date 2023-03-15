module ecs_inspector_common shared
require ecs
require ecs.common
require imgui
require DagorImgui
require DagorConsole
require DagorSystem
require DagorMath
require DagorEditor
require DagorDataBlock
require DagorDebug3D
require EcsUtils
require imgui/imgui_boost
require strings
require strings_boost
require math.base
require daslib/static_let
require daslib/safe_addr
require daslib/instance_function
require daslib/defer
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require danetlibs.imgui_daeditor.daEditor.daEditor_common
require %danetlibs.imgui_daeditor.imgui.imgui_common


[unused_argument(eid)]
def default_menu(eid : array<EntityId> implicit; name, typeName : string; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>)
  imgui::TableSetColumnIndex(2)
  if imgui::Button("*##{name}")
    imgui::OpenPopup("defaultSubMenuPopup_{name}")

  var res = true
  if imgui::BeginPopup("defaultSubMenuPopup_{name}")

    if imgui::Button("Copy##copyname")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(name)
    imgui::SameLine()
    imgui::Text(name)

    if imgui::Button("Copy##copytypename")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(typeName)
    imgui::SameLine()
    imgui::Text(typeName)

    res = sub_menu |> invoke(changed)

    imgui::EndPopup()
  return res

[unused_argument(eid)]
def default_menu(eid : array<EntityId> implicit;
                 name, typeName : string;
                 val_to_str : block<() : string>;
                 str_to_val : block<(str : string) : void>;
                 blk_val_to_str : block<() : string>;
                 var changed : bool?;
                 sub_menu : block<(var changed : bool?) : bool>)
  imgui::TableSetColumnIndex(2)
  if imgui::Button("*##{name}")
    imgui::OpenPopup("defaultSubMenuPopup_{name}")

  var res = true
  if imgui::BeginPopup("defaultSubMenuPopup_{name}")

    if imgui::Button("Copy")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(name)
    imgui::SameLine()
    imgui::Text(name)

    if imgui::Button("Copy")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(typeName)
    imgui::SameLine()
    imgui::Text(typeName)

    if imgui::Button("Copy value")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(val_to_str |> invoke())
    if imgui::Button("Paste value")
      imgui::CloseCurrentPopup()
      str_to_val |> invoke(imgui::GetClipboardText())
    if imgui::Button("Copy blk value")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(blk_val_to_str |> invoke())

    res = sub_menu |> invoke(changed)

    imgui::EndPopup()
  return res

def to_string(val : DPoint3)
  return "{val.x}, {val.y}, {val.z}"

def to_string(val)
  return "{val}"

def to_string(val : float3x4)
  return "[[{val[0]}] [{val[1]}] [{val[2]}] [{val[3]}]]"

[no_aot]
def to_string_via_blk(compName : string; eid : EntityId)
  var data = ""
  using() <| $(var blk : DataBlock)
    let mgr & = getEntityManager()
    component_to_blk_param(compName, mgr |> getComponentRef(eid, compName), blk)
    data := string(blk)
  return data

def to_int2(str : string)
  let parts <- split(str, ",")
  return int2(length(parts) > 0 ? to_int(strip(parts[0])) : 0,
              length(parts) > 1 ? to_int(strip(parts[1])) : 0)

def to_int3(str : string)
  let parts <- split(str, ",")
  return int3(length(parts) > 0 ? to_int(strip(parts[0])) : 0,
              length(parts) > 1 ? to_int(strip(parts[1])) : 0,
              length(parts) > 2 ? to_int(strip(parts[2])) : 0)

def to_int4(str : string)
  let parts <- split(str, ",")
  return int4(length(parts) > 0 ? to_int(strip(parts[0])) : 0,
              length(parts) > 1 ? to_int(strip(parts[1])) : 0,
              length(parts) > 2 ? to_int(strip(parts[2])) : 0,
              length(parts) > 3 ? to_int(strip(parts[3])) : 0)

def to_float2(str : string)
  let parts <- split(str, ",")
  return float2(length(parts) > 0 ? to_float(strip(parts[0])) : 0.0,
                length(parts) > 1 ? to_float(strip(parts[1])) : 0.0)

def to_float3(str : string)
  let parts <- split(str, ",")
  return float3(length(parts) > 0 ? to_float(strip(parts[0])) : 0.0,
                length(parts) > 1 ? to_float(strip(parts[1])) : 0.0,
                length(parts) > 2 ? to_float(strip(parts[2])) : 0.0)

def to_float4(str : string)
  let parts <- split(str, ",")
  return float4(length(parts) > 0 ? to_float(strip(parts[0])) : 0.0,
                length(parts) > 1 ? to_float(strip(parts[1])) : 0.0,
                length(parts) > 2 ? to_float(strip(parts[2])) : 0.0,
                length(parts) > 3 ? to_float(strip(parts[3])) : 0.0)

def to_DPoint3(str : string)
  let parts <- split(str, ",")
  return DPoint3(length(parts) > 0 ? double(strip(parts[0])) : 0.0lf,
                 length(parts) > 1 ? double(strip(parts[1])) : 0.0lf,
                 length(parts) > 2 ? double(strip(parts[2])) : 0.0lf)

def to_TMatrix(str : string)
  var value : float3x4
  let packedStr = str |> replace(" ", "")
  if packedStr |> starts_with("[[") && packedStr |> ends_with("]]")
    let rows <- split(packedStr |> chop(2, length(packedStr) - 4), "][")
    value[0] = length(rows) > 0 ? to_float3(rows[0]) : float3()
    value[1] = length(rows) > 1 ? to_float3(rows[1]) : float3()
    value[2] = length(rows) > 2 ? to_float3(rows[2]) : float3()
    value[3] = length(rows) > 3 ? to_float3(rows[3]) : float3()
  return value

// [[ 138.485, 99.9427, -648.716, 1; 142.237, 103.802, -645.125, 1]]
def to_bbox3f(str : string)
  var value : bbox3f
  let packedStr = str |> replace(" ", "")
  if packedStr |> starts_with("[[") && packedStr |> ends_with("]]")
    let rows <- split(packedStr |> chop(2, length(packedStr) - 4), ";")
    value.bmin = length(rows) > 0 ? to_float4(rows[0]) : float4()
    value.bmax = length(rows) > 1 ? to_float4(rows[1]) : float4()
  return value


def update_value(new_val;
                 var val_ptr;
                 var changed : bool?)
  *changed ||= (*val_ptr != new_val)
  *val_ptr = new_val

def clone_value(new_val;
                var val_ptr;
                var changed : bool?)
  *changed ||= (*val_ptr != new_val)
  *val_ptr := new_val


[ecs_inspector(type_name="bbox3f")]
def draw_bbox3f(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<bbox3f?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}min", unsafe(addr((val.bmin).x)), "%.4f", ImGuiInputTextFlags None) || *changed
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}max", unsafe(addr((val.bmax).x)), "%.4f", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "bbox3f", $() => to_string(*val),
               $(str) { let newValue = to_bbox3f(str); val.bmin = newValue.bmin; val.bmax = newValue.bmax; *changed = true; },
               $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="ecs::Tag")]
def draw_tag(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  imgui::Text("<Tag>")
  default_menu(eid, name, "ecs::Tag", changed, sub_menu)


[ecs_inspector(type_name="int")]
def draw_int(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<int?> refs[0].rawData)
  let step = 1
  let fastStep = 5
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalar("##{name}", ImGuiDataType S32, val, safe_addr(step), safe_addr(fastStep), "%d", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "int", $() => to_string(*val), $(str) { update_value(to_int(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="DPoint3")]
def draw_DPoint3(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<DPoint3?> refs[0].rawData)
  let step = 0.1
  let fastStep = 0.5
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalarN("##{name}", ImGuiDataType Double, val, 3, safe_addr(step), safe_addr(fastStep), "%.2lf", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "DPoint3", $() => to_string(*val), $(str) { *val = to_DPoint3(str); *changed = true; }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="uint8_t")]
def draw_uint8_t(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<uint8?> refs[0].rawData)
  let step = 1
  let fastStep = 5
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalar("##{name}", ImGuiDataType U8, val, safe_addr(step), safe_addr(fastStep), "%u", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "u8", $() => to_string(*val), $(str) { update_value(uint8(to_uint(str)), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="int64_t")]
def draw_int64(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<int64?> refs[0].rawData)
  let step = 1
  let fastStep = 5
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalar("##{name}", ImGuiDataType S64, val, safe_addr(step), safe_addr(fastStep), "%lld", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "i64", $() => to_string(*val), $(str) { update_value(to_int64(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="uint16")]
def draw_uint16(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<uint16?> refs[0].rawData)
  let step = 1
  let fastStep = 5
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalar("##{name}", ImGuiDataType U16, val, safe_addr(step), safe_addr(fastStep), "%u", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "u16", $() => to_string(*val), $(str) { update_value(uint16(to_uint(str)), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="uint64_t")]
def draw_uint64(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<uint64?> refs[0].rawData)
  let step = 1
  let fastStep = 5
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalar("##{name}", ImGuiDataType U64, val, safe_addr(step), safe_addr(fastStep), "%llx", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "u64", $() => to_string(*val), $(str) { update_value(to_uint64(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="E3DCOLOR")]
def draw_E3DCOLOR(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<E3DCOLOR?> refs[0].rawData)
  let uColor = uint(*val)
  var color = [[float[4] float((uColor >> 16u)& 0xFF) / 255f; float((uColor >> 8u) & 0xFF) / 255f; float(uColor & 0xFF) / 255f; float(uColor >> 24u) / 255f]]
  SetNextItemWidth(-FLT_MIN)
  if ColorEdit4("##{name}", safe_addr(color[0]), ImGuiColorEditFlags None)
    *changed = true
    let res = uint(color[3] * 255f) << 24u | uint(color[0] * 255f) << 16u | uint(color[1] * 255f) << 8u | uint(color[2] * 255f)
    *val = E3DCOLOR(res)
  default_menu(eid, name, "E3DCOLOR",
               $() => to_string(*val),
               $(str) { let newVal = E3DCOLOR(to_uint(str)); *changed ||= (uint(*val) != uint(newVal)); *val = newVal; },
               $() => to_string_via_blk(name, eid[0]),
               changed, sub_menu)


[ecs_inspector(type_name="float")]
def draw_float(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float?> refs[0].rawData)
  let step = 1f
  let fastStep = 5f
  SetNextItemWidth(-FLT_MIN)
  *changed = InputScalar("##{name}", ImGuiDataType Float, val, safe_addr(step), safe_addr(fastStep), "%.4f", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "float", $() => to_string(*val), $(str) { update_value(to_float(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="bool")]
def draw_bool(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<bool?> refs[0].rawData)
  *changed = Checkbox("##{name}", val) || *changed
  default_menu(eid, name, "bool", $() => to_string(*val), $(str) { update_value(to_int(str) != 0, val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="Point2")]
def draw_Point2(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float2?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat2("##{name}", unsafe(addr((*val).x)), "%.4f", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "Point2", $() => to_string(*val), $(str) { update_value(to_float2(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="Point3")]
def draw_Point3(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float3?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}", unsafe(addr((*val).x)), "%.4f", ImGuiInputTextFlags None) || *changed

  default_menu(eid, name, "Point3", $() => to_string(*val), $(str) { update_value(to_float3(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed) <| $ [unused_argument(sub_changed)] (sub_changed)

    if imgui::Button("show me##{name}")
      draw_debug_sphere_buffered(*val, 1.0, E3DCOLOR(0xFFFFFF00), 12, 2500)
      var upPoint = *val
      upPoint.y += 150.0
      draw_debug_line_buffered(*val, upPoint, E3DCOLOR(0xFFFFFF00), 2500)

    return sub_menu |> invoke(changed)


[ecs_inspector(type_name="Point4")]
def draw_Point4(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float4?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat4("##{name}", unsafe(addr((*val).x)), "%.4f", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "Point4", $() => to_string(*val), $(str) { update_value(to_float4(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="IPoint2")]
def draw_IPoint2(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<int2?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputInt2("##{name}", unsafe(addr((*val).x)), ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "IPoint2", $() => to_string(*val), $(str) { update_value(to_int2(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="IPoint3")]
def draw_IPoint3(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<int3?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputInt3("##{name}", unsafe(addr((*val).x)), ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "IPoint3", $() => to_string(*val), $(str) { update_value(to_int3(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="IPoint4")]
def draw_IPoint4(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<int4?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputInt4("##{name}", unsafe(addr((*val).x)), ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "IPoint4", $() => to_string(*val), $(str) { update_value(to_int4(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="vec4f")]
def draw_vec4f(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float4?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat4("##{name}", unsafe(addr((*val).x)), "%.4f", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "vec4f", $() => to_string(*val), $(str) { update_value(vec4f(to_float4(str)), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="TMatrix")]
def draw_TMatrix(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<float3x4?> refs[0].rawData)
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}_0", unsafe(addr((*val)[0].x)), "%.4f", ImGuiInputTextFlags None) || *changed
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}_1", unsafe(addr((*val)[1].x)), "%.4f", ImGuiInputTextFlags None) || *changed
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}_2", unsafe(addr((*val)[2].x)), "%.4f", ImGuiInputTextFlags None) || *changed
  SetNextItemWidth(-FLT_MIN)
  *changed = InputFloat3("##{name}_3", unsafe(addr((*val)[3].x)), "%.4f", ImGuiInputTextFlags None) || *changed
  default_menu(eid, name, "TMatrix", $() => to_string(*val), $(str) { update_value(to_TMatrix(str), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed) <| $(var sub_changed)
    let res = sub_menu |> invoke(sub_changed)
    if !res
      return res

    if imgui::Button("Copy position")
      imgui::CloseCurrentPopup()
      (*val)[3] |> to_string |> imgui::SetClipboardText

    if imgui::Button("Copy rotation")
      imgui::CloseCurrentPopup()
      float4(quat(*val)) |> to_string |> imgui::SetClipboardText

    imgui::Separator()

    if imgui::Button("Identity")
      imgui::CloseCurrentPopup()
      let pos = (*val)[3]
      identity(*val)
      (*val)[3] = pos
      *sub_changed = true

    if imgui::Button("Orthonormalize")
      imgui::CloseCurrentPopup()
      orthonormalize(*val)
      *sub_changed = true

    imgui::Separator()

    if imgui::Button("Show me##{name}")
      let pos = (*val)[3]
      draw_debug_sphere_buffered(pos, 1.0, E3DCOLOR(0xFFFFFF00), 12, 2500)
      var upPoint = pos
      upPoint.y += 150.0
      draw_debug_line_buffered(pos, upPoint, E3DCOLOR(0xFFFFFF00), 2500)

    return res


[ecs_inspector(type_name="ecs::string")]
def draw_das_string(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<das_string?> refs[0].rawData)
  var buf <- ImGuiInputTextBuffer("{*val}", length(*val) + 256)
  SetNextItemWidth(-FLT_MIN)
  if InputText("##{name}", buf, ImGuiInputTextFlags AutoSelectAll)
    *changed = true
    *val := buf |> to_string()
  buf |> clear()
  default_menu(eid, name, "string", $() => to_string(*val), $(str) { clone_value(str, val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


[ecs_inspector(type_name="ecs::EntityId")]
def draw_EntityId(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<EntityId?> refs[0].rawData)
  var uVal = uint(*val)
  let TEXT_BASE_WIDTH = CalcTextSize("A").x
  SetNextItemWidth(imgui::GetColumnWidth() - TEXT_BASE_WIDTH * 12f)
  if InputScalar("##{name}", ImGuiDataType U32, safe_addr(uVal), [[int? ]], [[int? ]], "%d", ImGuiInputTextFlags None)
    *val = EntityId(uVal)
    *changed = true
  if !!*val
    imgui_hint <| $
      return getEntityTemplateName(*val)
  SameLine()
  if imgui::Button("Select##{name}{eid[0]}")
    editor_select_eid(*val)
  SameLine()
  if imgui::Button("*##{name}{eid[0]}")
    imgui::OpenPopup("eid_menu_{name}{eid[0]}")

  if imgui::BeginPopup("eid_menu_{name}{eid[0]}")
    for i in range(1, 4)
      if imgui::Button("Insector #{i+1}##{i+1}")
        imgui::CloseCurrentPopup()
        open_inspector(i, *val, "")
    imgui::EndPopup()

  default_menu(eid, name, "Eid", $() => to_string(*val), $(str) { update_value(EntityId(to_uint(str)), val, changed); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)


def unique_key(keys : array<string>; name = "key")
  var key = name
  if length(keys) == 0
    return key

  for _ in range(10)
    var found = false
    for idx in iter_range(keys)
      if keys[idx] == key
        found = true
    if !found
      break
    key = "_{key}"

  return key


[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::Object>"), no_aot]
def draw_shared_object(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var sharedVal = unsafe(reinterpret<ecs::SharedObject?> refs[0].rawData)
  draw_object(eid, flags, name, "shared<Object>", sharedVal.get, level, changed, sub_menu)


[ecs_inspector(type_name="ecs::Object"), no_aot]
def draw_Object(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<Object?> refs[0].rawData)
  draw_object(eid, flags, name, "Object", val, level, changed, sub_menu)


[no_aot]
def draw_object(eid : array<EntityId> implicit; flags : uint; name, typeName : string; var val : Object?; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  imgui::PushID(name)
  defer <|
    imgui::PopID()
  imgui::TableNextRow()
  imgui::TableSetColumnIndex(0)
  imgui::AlignTextToFramePadding()
  let len = length(*val)
  let isEmpty = len == 0
  var open = false
  let fullName = level == 0 ? item_flags(flags, name) : name
  if isEmpty && level == 0
    imgui::Text(fullName)
    imgui_hint(name)
  else
    let treeflags = isEmpty ? ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet : ImGuiTreeNodeFlags None
    open = TreeNodeEx(fullName, treeflags)
    imgui_hint(name)
  imgui::TableSetColumnIndex(1)

  var keys : array<string>
  for it in *val; { keys |> push(clone_string(it.key)); }

  if imgui::Button("+ i")
    *val |> set(unique_key(keys), 0)
  imgui::SameLine()
  if imgui::Button("+ r")
    *val |> set(unique_key(keys), 0f)
  imgui::SameLine()
  if imgui::Button("+ eid")
    *val |> set(unique_key(keys), INVALID_ENTITY_ID)
  imgui::SameLine()
  if imgui::Button("+ p3")
    *val |> set(unique_key(keys), float3())

  if isEmpty
    imgui::SameLine()
    imgui::Text("{typeName}: 0")
  else
    imgui::SameLine()
    imgui::Text("{typeName}: {len}")

  if !default_menu(eid, name, typeName, $() => to_string(*val), $(str) { logerr("Object to string not implemented! str={str}"); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)
    if open && !isEmpty
      imgui::TreePop()
    return

  if isEmpty
    return

  delete keys
  for it in *val; { keys |> push(clone_string(it.key)); }

  if !isEmpty && open
    var idx = -1
    while ++idx < length(keys)
      let key = keys[idx]
      var t = (*val)[keys[idx]]
      if t == null
        continue
      let it & = unsafe(*t)
      imgui::PushID(key)

      let isCont = is_cont_type(getEntityComponentRef(it).userType)

      if !isCont
        imgui::TableNextRow()
        imgui::TableSetColumnIndex(0)

        let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
        TreeNodeEx(key, itFlags)
        imgui_hint(key)

        imgui::TableSetColumnIndex(1)

      let itRefs <- [{auto[] clone(getEntityComponentRef(it)) }]
      render_item(eid, 0u, key, unsafe(reinterpret<array<EntityComponentRef#>#> itRefs), level + 1, changed) <| $(sub_changed)
        if imgui::Button("dup")
          imgui::CloseCurrentPopup()
          using() <| $(var cop : ChildComponent)
            cop := it
            *val |> set(unique_key(keys, key), cop)
            *sub_changed = true

        if imgui::Button("x")
          imgui::CloseCurrentPopup()
          *val |> erase(key)
          *sub_changed = true
          return false
        return true

      imgui::PopID()

    imgui::TreePop()


[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::Array>"), no_aot]
def draw_shared_array(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var sharedVal = unsafe(reinterpret<ecs::SharedArray?> refs[0].rawData)
  draw_array(eid, flags, name, "shared<Array>", sharedVal.get, level, changed, sub_menu)


[ecs_inspector(type_name="ecs::Array"), no_aot]
def draw_Array(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<Array?> refs[0].rawData)
  draw_array(eid, flags, name, "Array", val, level, changed, sub_menu)


[no_aot]
def draw_array(eid : array<EntityId> implicit; flags : uint; name, typeName : string; var val : Array?; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  imgui::PushID(name)
  defer <|
    imgui::PopID()
  imgui::TableNextRow()
  imgui::TableSetColumnIndex(0)
  imgui::AlignTextToFramePadding()
  let len = length(*val)
  let isEmpty = len == 0
  var open = false
  let fullName = level == 0 ? item_flags(flags, name) : name
  if isEmpty && level == 0
    imgui::Text(fullName)
    imgui_hint(name)
  else
    let treeflags = isEmpty ? ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet : ImGuiTreeNodeFlags None
    open = TreeNodeEx(fullName, treeflags)
    imgui_hint(name)
  imgui::TableSetColumnIndex(1)

  if imgui::Button("+ i")
    *val |> push(0)
  imgui::SameLine()
  if imgui::Button("+ r")
    *val |> push(0f)
  imgui::SameLine()
  if imgui::Button("+ eid")
    *val |> push(INVALID_ENTITY_ID)
  imgui::SameLine()
  if imgui::Button("+ p3")
    *val |> push(float3())

  if isEmpty
    imgui::SameLine()
    imgui::Text("{typeName}: 0")
  else
    imgui::SameLine()
    imgui::Text("{typeName}: {len}")

  if !default_menu(eid, name, typeName, $() => to_string(*val), $(str) { logerr("Array to string not implemented! str={str}"); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)
    if open && !isEmpty
      imgui::TreePop()
    return

  if isEmpty
    return

  if !isEmpty && open
    var idx = -1
    while ++idx < length(*val)
      let key = "[{idx}]"
      let it & = unsafe((*val)[idx])
      imgui::PushID(key)

      let isCont = is_cont_type(getEntityComponentRef(it).userType)

      if !isCont
        imgui::TableNextRow()
        imgui::TableSetColumnIndex(0)

        let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
        TreeNodeEx(key, itFlags)

        imgui::TableSetColumnIndex(1)

      let itRefs <- [{auto[] clone(getEntityComponentRef(it)) }]
      render_item(eid, 0u, key, unsafe(reinterpret<array<EntityComponentRef#>#> itRefs), level + 1, changed) <| $(sub_changed)
        if imgui::Button("dup")
          using() <| $(var cop : ChildComponent)
            cop := it
            *val |> push(cop)
            *sub_changed = true

        if imgui::Button("x")
          *val |> erase(idx)
          *sub_changed = true
          return false
        return true

      imgui::PopID()

    imgui::TreePop()


[generic, no_aot]
def draw_any_list(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<ContType?> refs[0].rawData)
  imgui::PushID(name)
  defer <|
    imgui::PopID()
  imgui::TableNextRow()
  imgui::TableSetColumnIndex(0)
  imgui::AlignTextToFramePadding()
  let len = length(*val)
  let isEmpty = len == 0
  var open = false
  let fullName = level == 0 ? item_flags(flags, name) : name
  if isEmpty && level == 0
    imgui::Text(fullName)
    imgui_hint(name)
  else
    let treeflags = isEmpty ? ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet : ImGuiTreeNodeFlags None
    open = TreeNodeEx(fullName, treeflags)
    imgui_hint(name)
  imgui::TableSetColumnIndex(1)

  if imgui::Button("+")
    let t : SubType = [[SubType()]]
    *val |> push(t)


  if isEmpty
    imgui::SameLine()
    imgui::Text("<empty {typeinfo(typename type<ContType>)}>")

  if !isEmpty
    imgui::SameLine()
    imgui::Text("{typeinfo(typename type<ContType>)} size: {len}")
    imgui::SameLine()
    if imgui::Button("Clear##{name}")
      *val |> clear()

  if !default_menu(eid, name, "{typeinfo(typename type<ContType>)}", $() => to_string(*val), $(str) { logerr("List to string not implemented! str={str}"); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)
    if open && !isEmpty
      imgui::TreePop()
    return

  if isEmpty
    return

  if !isEmpty && open
    var idx = -1
    while ++idx < length(*val)
      let key = "[{idx}]"
      imgui::PushID(key)

      let isCont = is_cont_type(getEntityComponentRef(*val, uint(idx)).userType)

      if !isCont
        imgui::TableNextRow()
        imgui::TableSetColumnIndex(0)

        let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
        TreeNodeEx(key, itFlags)

        imgui::TableSetColumnIndex(1)

      let itRefs <- [{auto[] clone(getEntityComponentRef(*val, uint(idx))) }]
      render_item(eid, 0u, key, unsafe(reinterpret<array<EntityComponentRef#>#> itRefs), level + 1, changed) <| $(sub_changed)
        if imgui::Button("dup")
          *val |> push((*val)[idx])
          *sub_changed = true

        if imgui::Button("x")
          *val |> erase(idx)
          *sub_changed = true
          return false
        return true

      imgui::PopID()

    imgui::TreePop()


[generic, no_aot]
def draw_any_shared_list(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var sharedVal = unsafe(reinterpret<ContType?> refs[0].rawData)
  var val = sharedVal.get
  imgui::PushID(name)
  defer <|
    imgui::PopID()
  imgui::TableNextRow()
  imgui::TableSetColumnIndex(0)
  imgui::AlignTextToFramePadding()
  let len = length(*val)
  let isEmpty = len == 0
  var open = false
  let fullName = level == 0 ? item_flags(flags, name) : name
  if isEmpty && level == 0
    imgui::Text(fullName)
    imgui_hint(name)
  else
    let treeflags = isEmpty ? ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet : ImGuiTreeNodeFlags None
    open = TreeNodeEx(fullName, treeflags)
    imgui_hint(name)
  imgui::TableSetColumnIndex(1)

  if imgui::Button("+")
    let t : SubType = [[SubType()]]
    *val |> push(t)

  if isEmpty
    imgui::SameLine()
    imgui::Text("{typeinfo(typename type<ContType>)}: 0")

  if !isEmpty
    imgui::SameLine()
    imgui::Text("{typeinfo(typename type<ContType>)}: {len}")
    imgui::SameLine()
    if imgui::Button("Clear##{name}")
      *val |> clear()

  if !default_menu(eid, name, "{typeinfo(typename type<ContType>)}", $() => to_string(*val), $(str) { logerr("SharedList to string not implemented! str={str}"); }, $() => to_string_via_blk(name, eid[0]), changed, sub_menu)
    if open && !isEmpty
      imgui::TreePop()
    return

  if isEmpty
    return

  if !isEmpty && open
    var idx = -1
    while ++idx < length(*val)
      let key = "[{idx}]"
      imgui::PushID(key)

      let isCont = is_cont_type(getEntityComponentRef(*val, uint(idx)).userType)

      if !isCont
        imgui::TableNextRow()
        imgui::TableSetColumnIndex(0)

        let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
        TreeNodeEx(key, itFlags)

        imgui::TableSetColumnIndex(1)

      let itRefs <- [{auto[] clone(getEntityComponentRef(*val, uint(idx))) }]
      render_item(eid, 0u, key, unsafe(reinterpret<array<EntityComponentRef#>#> itRefs), level + 1, changed) <| $(sub_changed)
        if imgui::Button("dup")
          *val |> push((*val)[idx])
          *sub_changed = true

        if imgui::Button("x")
          *val |> erase(idx)
          *sub_changed = true
          return false
        return true

      imgui::PopID()

    imgui::TreePop()

def getEntityComponentRef(val : Array; idx)
  return val[idx] |> getEntityComponentRef()

[generic]
def use_this(blk : block<(val : T#) : void>) { using(blk); }
def use_this(blk : block<(val : int#) : void>) { blk |> invoke(0); }
def use_this(blk : block<(val : uint8#) : void>) { blk |> invoke(uint8(0u)); }
def use_this(blk : block<(val : uint16#) : void>) { blk |> invoke(uint16(0u)); }
def use_this(blk : block<(val : uint64#) : void>) { blk |> invoke(uint64(0u)); }
def use_this(blk : block<(val : string#) : void>) { var str : string# = ""; blk |> invoke(str); }
def use_this(blk : block<(val : das_string#) : void>) { using() <| $(var str : das_string) { blk |> invoke(unsafe(reinterpret<das_string#> str)); } }
def use_this(blk : block<(val : EntityId#) : void>) { blk |> invoke(INVALID_ENTITY_ID); }
def use_this(blk : block<(val : float#) : void>) { blk |> invoke(0f); }
def use_this(blk : block<(val : float2#) : void>) { blk |> invoke(float2()); }
def use_this(blk : block<(val : float3#) : void>) { blk |> invoke(float3()); }
def use_this(blk : block<(val : float4#) : void>) { blk |> invoke(float4()); }
def use_this(blk : block<(val : int2#) : void>) { blk |> invoke(int2()); }
def use_this(blk : block<(val : int3#) : void>) { blk |> invoke(int3()); }
def use_this(blk : block<(val : float3x4#) : void>) { var tm : float3x4# = IDENT_TM; blk |> invoke(tm); }
def use_this(blk : block<(val : bool#) : void>) { blk |> invoke(false); }
def use_this(blk : block<(val : E3DCOLOR#) : void>) { blk |> invoke(E3DCOLOR(0x0)); }
def use_this(blk : block<(val : int64#) : void>) { blk |> invoke(0l); }


[ecs_inspector(type_name="ecs::IntList"), no_aot, instance_function::instance_function(draw_any_list, ContType = IntList, SubType = "int")]
def draw_IntList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::UInt8List"), no_aot, instance_function::instance_function(draw_any_list, ContType = UInt8List, SubType = "uint8")]
def draw_UInt8List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::UInt16List"), no_aot, instance_function::instance_function(draw_any_list, ContType = UInt16List, SubType = "uint16")]
def draw_UInt16List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::UInt64List"), no_aot, instance_function::instance_function(draw_any_list, ContType = UInt64List, SubType = "uint64")]
def draw_UInt64List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::StringList"), no_aot, instance_function::instance_function(draw_any_list, ContType = StringList, SubType = "string")]
def draw_StringList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::EidList"), no_aot, instance_function::instance_function(draw_any_list, ContType = EidList, SubType = EntityId)]
def draw_EidList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::FloatList"), no_aot, instance_function::instance_function(draw_any_list, ContType = FloatList, SubType = "float")]
def draw_FloatList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Point2List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Point2List, SubType = "float2")]
def draw_Point2List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Point3List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Point3List, SubType = "float3")]
def draw_Point3List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Point4List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Point4List, SubType = "float4")]
def draw_Point4List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::IPoint2List"), no_aot, instance_function::instance_function(draw_any_list, ContType = IPoint2List, SubType = "int2")]
def draw_IPoint2List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::IPoint3List"), no_aot, instance_function::instance_function(draw_any_list, ContType = IPoint3List, SubType = "int3")]
def draw_IPoint3List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::BoolList"), no_aot, instance_function::instance_function(draw_any_list, ContType = BoolList, SubType = "bool")]
def draw_BoolList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::TMatrixList"), no_aot, instance_function::instance_function(draw_any_list, ContType = TMatrixList, SubType = "float3x4")]
def draw_TMatrixList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::ColorList"), no_aot, instance_function::instance_function(draw_any_list, ContType = ColorList, SubType = "E3DCOLOR")]
def draw_ColorList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Int64List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Int64List, SubType = "int64")]
def draw_Int64List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}


[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::IntList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedIntList, SubType = "int")]
def draw_SharedIntList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::UInt8List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedUInt8List, SubType = "uint8")]
def draw_SharedUInt8List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::UInt16List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedUInt16List, SubType = "uint16")]
def draw_SharedUInt16List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::UInt64List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedUInt64List, SubType = "uint64")]
def draw_SharedUInt64List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::StringList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedStringList, SubType = "string")]
def draw_SharedStringList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::EidList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedEidList, SubType = EntityId)]
def draw_SharedEidList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::FloatList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedFloatList, SubType = "float")]
def draw_SharedFloatList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::Point2List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedPoint2List, SubType = "float2")]
def draw_SharedPoint2List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::Point3List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedPoint3List, SubType = "float3")]
def draw_SharedPoint3List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::Point4List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedPoint4List, SubType = "float4")]
def draw_SharedPoint4List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::IPoint2List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedIPoint2List, SubType = "int2")]
def draw_SharedIPoint2List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::IPoint3List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedIPoint3List, SubType = "int3")]
def draw_SharedIPoint3List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::BoolList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedBoolList, SubType = "bool")]
def draw_SharedBoolList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::TMatrixList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedTMatrixList, SubType = "float3x4")]
def draw_SharedTMatrixList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::ColorList>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedColorList, SubType = "E3DCOLOR")]
def draw_SharedColorList(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::SharedComponent< ::ecs::Int64List>"), no_aot, instance_function::instance_function(draw_any_shared_list, ContType = SharedInt64List, SubType = "int64")]
def draw_SharedInt64List(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}

// TODO: move this to ecs_inspector annotation
def is_cont_type(user_type : uint) : bool
  let typeName = getComponentTypes() |> component_types_findTypeName(user_type)
  return (
         typeName == "ecs::Object"
      || typeName == "ecs::Array"
      || typeName == "ecs::IntList"
      || typeName == "ecs::UInt8List"
      || typeName == "ecs::UInt16List"
      || typeName == "ecs::StringList"
      || typeName == "ecs::EidList"
      || typeName == "ecs::FloatList"
      || typeName == "ecs::Point2List"
      || typeName == "ecs::Point3List"
      || typeName == "ecs::Point4List"
      || typeName == "ecs::IPoint2List"
      || typeName == "ecs::IPoint3List"
      || typeName == "ecs::BoolList"
      || typeName == "ecs::TMatrixList"
      || typeName == "ecs::ColorList"
      || typeName == "ecs::Int64List"
      || typeName == "ecs::SharedComponent< ::ecs::Object>"
      || typeName == "ecs::SharedComponent< ::ecs::Array>"
      || typeName == "ecs::SharedComponent< ::ecs::Object>"
      || typeName == "ecs::SharedComponent< ::ecs::Array>"
      || typeName == "ecs::SharedComponent< ::ecs::IntList>"
      || typeName == "ecs::SharedComponent< ::ecs::UInt8List>"
      || typeName == "ecs::SharedComponent< ::ecs::UInt16List>"
      || typeName == "ecs::SharedComponent< ::ecs::StringList>"
      || typeName == "ecs::SharedComponent< ::ecs::EidList>"
      || typeName == "ecs::SharedComponent< ::ecs::FloatList>"
      || typeName == "ecs::SharedComponent< ::ecs::Point2List>"
      || typeName == "ecs::SharedComponent< ::ecs::Point3List>"
      || typeName == "ecs::SharedComponent< ::ecs::Point4List>"
      || typeName == "ecs::SharedComponent< ::ecs::IPoint2List>"
      || typeName == "ecs::SharedComponent< ::ecs::IPoint3List>"
      || typeName == "ecs::SharedComponent< ::ecs::BoolList>"
      || typeName == "ecs::SharedComponent< ::ecs::TMatrixList>"
      || typeName == "ecs::SharedComponent< ::ecs::ColorList>"
      || typeName == "ecs::SharedComponent< ::ecs::Int64List>"
    )


def compare_eids(a, b : array<EntityId>) : int
  let na = length(a)
  let nb = length(b)
  if na != nb
    return na < nb ? -1 : 1

  for x, y in a, b
    if x != y
      return uint(x) < uint(y) ? -1 : 1

  return 0


def render_item(eid : array<EntityId> implicit; flags : uint; name : string implicit; refs : array<EntityComponentRef#>#; level : int; var changed : bool? implicit; sub_menu : block<(var changed : bool?) : bool>) : void
  let typeName = getComponentTypes() |> component_types_findTypeName(refs[0].userType)
  render_item(eid, flags, name, typeName, refs, level, changed, sub_menu)

def render_item(eid : array<EntityId> implicit; flags : uint; name, type_name : string implicit; refs : array<EntityComponentRef#>#; level : int; var changed : bool? implicit; sub_menu : block<(var changed : bool?) : bool>) : void
  var hasInspector = false
  if has_inspector(type_name)
    hasInspector = call_inspector(type_name, eid, flags, name, refs, level, changed, sub_menu)
  if !hasInspector
    hasInspector = get_ecs_enum_values(type_name) <| $(enumValues)
      var curItem = find_enum_idx(type_name, refs[0])
      imgui::Text("{type_name} {enumValues[curItem]}")
      if ListBox("##{name}", safe_addr(curItem), enumValues)
        update_enum_value(type_name, unsafe(reinterpret<EntityComponentRef> refs[0]), curItem)
        *changed = true

  if !hasInspector
    imgui::Text("{type_name} <{refs[0].userType}>")
    default_menu(eid, name, type_name, changed) <| $ [unused_argument(sub_changed)] (sub_changed)

      if imgui::Button("copy type id##{name}")
        imgui::CloseCurrentPopup()
        imgui::SetClipboardText("{refs[0].userType}")

      return sub_menu |> invoke(changed)


def imgui_hint(desc : string implicit)
  imgui_hint <| $
    return desc

def imgui_hint(desc : block<() : string implicit>)
  if IsItemHovered()
    BeginTooltip()
    PushTextWrapPos(GetFontSize() * 35.0f)
    TextUnformatted(invoke(desc))
    PopTextWrapPos()
    EndTooltip()


def DasHelpMarker(desc : string)
  TextDisabled("(?)")
  if IsItemHovered()
    BeginTooltip()
    PushTextWrapPos(GetFontSize() * 35.0f)
    TextUnformatted(desc)
    PopTextWrapPos()
    EndTooltip()


def item_flags(flags : uint; name : string implicit) : string
  let tracked = (flags & FLAG_CHANGE_EVENT) != 0u
  let replicated = (flags & FLAG_REPLICATED) != 0u
  return build_string <| $(str)
    if tracked
      str |> write("[t]")
    if replicated
      str |> write("[r]")
    if tracked || replicated
      str |> write(" ")
    str |> write(name)


def match(arr : array<string>; str : string) : bool
  for s in arr
    if find(str, s) >= 0
      return true
  return false

def open_inspector(idx : int; eid : EntityId; filter_str : string)
  if idx < 1 || idx > 3
    logerr("wrong inspector idx {idx}. Expected values are 1, 2, 3")

  imgui_set_blk_val("ecs_inspector_{idx}", "eid", int(uint(eid)))
  imgui_set_blk_val("ecs_inspector_{idx}", "filter", filter_str)
  imgui_window_set_visible("Editor", "Inspector {idx+1}", true)

[no_aot]
def inspect_item(uid : int; var filter : ImGuiTextFilter; eids : array<EntityId>#; new_selection : bool)
  if length(eids) == 0
    return
  static_let <|
    var selectedItem = 0
    var inflateListNum = 0
  if new_selection || selectedItem >= length(eids)
    selectedItem = 0
    inflateListNum = 0

  let eid = eids[selectedItem]

  let templateName = getEntityTemplateName(eid)
  let TEXT_BASE_WIDTH = CalcTextSize("A").x

  PushID(uid)

  if imgui::Button("*##{templateName}")
    imgui::OpenPopup("template_menu_{templateName}")

  if imgui::BeginPopup("template_menu_{templateName}")

    for i in range(1, 4)
      if i > 1
        imgui::SameLine()
      if imgui::Button("Insector #{i+1}##{i+1}")
        imgui::CloseCurrentPopup()
        open_inspector(i, eid, imgui_get_blk_val("ecs_inspector_{uid}", "filter", ""))

    if imgui::Button("copy eid")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText("{eid}")

    imgui::SameLine()
    if imgui::Button("copy blk")
      imgui::CloseCurrentPopup()
      using() <| $(var blk : DataBlock)
        blk |> datablock_add_new_block("entity") <| $(sub)
          var tName = getEntityTemplateName(eid)
          tName = remove_sub_template_name(tName, "daeditor_selected")
          eid |> components_to_blk(sub, "", false)
          sub |> add("_template", tName)
        imgui::SetClipboardText(string(blk))

    imgui::SameLine()
    if imgui::Button("copy blk diff")
      imgui::CloseCurrentPopup()
      using() <| $(var blk : DataBlock)
        editor_save_entity(eid, blk)
        imgui::SetClipboardText(string(blk))

    if imgui::Button("copy")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText(templateName |> replace("+daeditor_selected+", "+") |> replace("+daeditor_selected", ""))

    imgui::SameLine()
    imgui::Text(templateName)
    imgui::SameLine()

    imgui::Separator()

    let names <- split_template(templateName)
    for idx, n in iter_range(names), names
      if imgui::Button("copy##{idx}")
        imgui::CloseCurrentPopup()
        imgui::SetClipboardText(n)
      imgui::SameLine()
      imgui::Text(n)

    imgui::EndPopup()

  imgui::SameLine()
  if length(eids) == 1
    imgui::TextUnformatted("{eid}: {templateName}")
    imgui_hint(templateName)
  else
    if BeginCombo("##selectEid", "{eid}: {templateName}", ImGuiComboFlags None) //  NoArrowButton
      for idx, e in iter_range(eids), eids
        var selected = idx == selectedItem
        var selectedAddr = safe_addr(selected)
        if imgui::Selectable("{e}: {getEntityTemplateName(e)}", selectedAddr)
          selectedItem = idx // selected eid will be changed in next frame
      EndCombo()

  imgui::Separator()
  call_editor(/*prefix*/true, eids)

  DasHelpMarker("Filter (\"incl,-excl\")\nt:typeName (t:EntityId, t:EidList)")
  imgui::SameLine()
  SetNextItemWidth(-55.)

  let mgr & = getEntityManager()
  let dataComps & = getDataComponents()
  let compTypes & = getComponentTypes()

  filter |> set() <| imgui_get_blk_val("ecs_inspector_{uid}", "filter", "")

  filter |> Draw("##{eid}")

  SameLine()
  if imgui::Button("Clear")
    filter |> Clear()

  imgui_set_blk_val("ecs_inspector_{uid}", "filter", to_string(filter))

  imgui::BeginChild("sub", float2(0, 0))
  let tmp = getTemplateByName(templateName)
  if BeginTable("split", 3, ImGuiTableFlags Resizable | ImGuiTableFlags BordersOuter | ImGuiTableFlags RowBg)
    TableSetupColumn("name", ImGuiTableColumnFlags WidthStretch)
    TableSetupColumn("value", ImGuiTableColumnFlags WidthStretch)
    TableSetupColumn("menu", ImGuiTableColumnFlags WidthFixed, TEXT_BASE_WIDTH * 2f)

    let componentsNum = mgr |> getNumComponents(eid)
    var comps : array<tuple<name : string; cid : uint>>
    for idx in urange(componentsNum >= 0 ? componentsNum : 0)
      let name = dataComps |> data_components_getComponentNameById((mgr |> getEntityComponentRef(eid, idx)).componentId)
      comps |> emplace([[auto name, idx]])

    comps |> sort() <| $(left; right)
      return left.name < right.name

    var filters : array<string>
    var excludeFilters : array<string>
    var typeFilters : array<string>
    var excludeTypeFilters : array<string>
    for filterRange in filter.Filters
      if filterRange |> empty()
        continue
      let filterString = string(filterRange)
      if filterString |> starts_with("t:") && length(filterString) > 2
        typeFilters |> push(unsafe(slice(filterString, 2) |> strip() |> to_lower_in_place()))
      elif filterString |> starts_with("-t:") && length(filterString) > 3
        excludeTypeFilters |> push(unsafe(slice(filterString, 3) |> strip() |> to_lower_in_place()))
      elif filterString |> starts_with("-") && length(filterString) > 1
        excludeFilters |> push(unsafe(slice(filterString, 1) |> strip() |> to_lower_in_place()))
      else
        filters |> push(unsafe(filterString |> to_lower_in_place()))

    var skipItems = max(0, floori(GetScrollY() / imgui::GetTextLineHeightWithSpacing()) - inflateListNum)
    var showItems = ceili(GetWindowHeight() / imgui::GetTextLineHeightWithSpacing()) + inflateListNum
    inflateListNum = 0
    for c in comps
      if showItems <= 0
        TableNextRow()
        TableNextColumn()
        imgui::Text("1")
        TableNextColumn()
        continue

      let type_info <- mgr |> getEntityComponentRef(eid, c.cid)
      let comp = dataComps |> data_components_getComponentById(type_info.componentId)
      if (uint(comp.flags) & uint(IS_COPY)) != 0u
        // if skipItems > 0
        //   skipItems -= 1
        continue

      let name = c.name
      let lowerName = name |> to_lower()
      if (length(filters) > 0 && !match(filters, lowerName)) || (length(excludeFilters) > 0 && match(excludeFilters, lowerName))
        // if skipItems > 0
        //   skipItems -= 1
        continue

      let typeName = compTypes |> component_types_findTypeName(type_info.userType)
      let lowerTypeName = typeName |> to_lower()
      if (length(typeFilters) > 0 && !match(typeFilters, lowerTypeName)) || (length(excludeTypeFilters) > 0 && match(excludeTypeFilters, lowerTypeName))
        // if skipItems > 0
        //   skipItems -= 1
        continue

      if skipItems > 0
        skipItems -= 1
        TableNextRow()
        TableNextColumn()
        imgui::Text("0")
        TableNextColumn()
        continue

      let flags = tmp != null && !empty(name) ? getRegExpInheritedFlags(tmp, name) : 0u
      let idxBefore = TableGetRowIndex()
      if !is_cont_type(type_info.userType)
        TableNextRow()
        TableNextColumn()
        imgui::Text(item_flags(flags, name))
        imgui_hint(name)
        TableNextColumn()

      var changed = false
      let refs <- [{auto[] clone(type_info) }]
      render_item(eids, flags, name, typeName, unsafe(reinterpret<array<EntityComponentRef#>#> refs), 0, safe_addr(changed)) <| $ [unused_argument(_)] (_) => true
      if changed
        entity_obj_editor_saveComponent(eid, name)
        invalidate_item(eid, unsafe(reinterpret<array<EntityComponentRef#>#> refs))

      let rowsNum = TableGetRowIndex() - idxBefore
      inflateListNum += rowsNum > 1 ? rowsNum + 5 : 0 // + 5 works, maybe + 10 works too
      showItems -= rowsNum

    EndTable()

  call_editor(/*prefix*/false, eids)
  imgui::EndChild()

  PopID()


[no_aot]
def invalidate_item(eid : EntityId; refs : array<EntityComponentRef#>#)
  for ref in refs
    nada(getEntityManagerRW() |> getComponentRefRW(eid, ref.componentId))


[sideeffects, unused_argument(ref)]
def nada(var ref : EntityComponentRef)
  pass

