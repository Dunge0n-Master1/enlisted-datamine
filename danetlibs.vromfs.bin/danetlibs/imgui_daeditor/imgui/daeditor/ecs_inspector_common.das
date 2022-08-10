module ecs_inspector_common shared
require ecs
require ecs.common
require imgui
require DagorImgui
require DagorConsole
require DagorMath
require DagorEditor
require DagorDataBlock
require DagorDebug3D
require EcsUtils
require imgui/imgui_boost
require strings
require math.base
require daslib/static_let
require daslib/safe_addr
require daslib/instance_function
require daslib/defer
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require danetlibs.imgui_daeditor.daEditor.daEditor_common


[unused_argument(eid)]
def default_menu(eid : EntityId; name, typeName : string; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>)
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

    res = sub_menu |> invoke(changed)

    imgui::EndPopup()
  return res

[unused_argument(eid)]
def default_menu(eid : EntityId; name, typeName : string; val : block<() : string>; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>)
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
      imgui::SetClipboardText(val |> invoke())

    res = sub_menu |> invoke(changed)

    imgui::EndPopup()
  return res

def to_string(val : DPoint3)
  return "{val.x}, {val.y}, {val.z}"

def to_string(val)
  return "{val}"

def to_string(val : float3x4)
  return "[[{val[0]}] [{val[1]}] [{val[2]}] [{val[3]}]]"


[ecs_inspector(type_name="ecs::Tag")]
def draw_tag(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  imgui::Text("<Tag>")
  default_menu(eid, name, "ecs::Tag", changed, sub_menu)


[ecs_inspector(type_name="int")]
def draw_int(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<int?> ref.rawData
    let step = 1
    let fastStep = 5
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalar("##{name}", ImGuiDataType S32, val, safe_addr(step), safe_addr(fastStep), "%d", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "int", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="DPoint3")]
def draw_DPoint3(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<DPoint3?> ref.rawData
    let step = 0.1
    let fastStep = 0.5
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalarN("##{name}", ImGuiDataType Double, val, 3, safe_addr(step), safe_addr(fastStep), "%.2lf", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "DPoint3", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="uint8_t")]
def draw_uint8_t(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<uint8?> ref.rawData
    let step = 1
    let fastStep = 5
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalar("##{name}", ImGuiDataType U8, val, safe_addr(step), safe_addr(fastStep), "%u", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "u8", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="int64_t")]
def draw_int64(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<int64?> ref.rawData
    let step = 1
    let fastStep = 5
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalar("##{name}", ImGuiDataType S64, val, safe_addr(step), safe_addr(fastStep), "%lld", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "i64", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="uint16")]
def draw_uint16(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<uint16?> ref.rawData
    let step = 1
    let fastStep = 5
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalar("##{name}", ImGuiDataType U16, val, safe_addr(step), safe_addr(fastStep), "%u", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "u16", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="uint64_t")]
def draw_uint64(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<uint64?> ref.rawData
    let step = 1
    let fastStep = 5
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalar("##{name}", ImGuiDataType U64, val, safe_addr(step), safe_addr(fastStep), "%llx", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "u64", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="E3DCOLOR")]
def draw_E3DCOLOR(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<E3DCOLOR?> ref.rawData
    let uColor = uint(*val)
    var color = [[float[4] float((uColor >> 16u)& 0xFF) / 255f; float((uColor >> 8u) & 0xFF) / 255f; float(uColor & 0xFF) / 255f; float(uColor >> 24u) / 255f]]
    SetNextItemWidth(-FLT_MIN)
    if ColorEdit4("##{name}", safe_addr(color[0]), ImGuiColorEditFlags None)
      *changed = true
      let res = uint(color[3] * 255f) << 24u | uint(color[0] * 255f) << 16u | uint(color[1] * 255f) << 8u | uint(color[2] * 255f)
      *val = E3DCOLOR(res)
    default_menu(eid, name, "E3DCOLOR", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="float")]
def draw_float(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<float?> ref.rawData
    let step = 1f
    let fastStep = 5f
    SetNextItemWidth(-FLT_MIN)
    *changed = InputScalar("##{name}", ImGuiDataType Float, val, safe_addr(step), safe_addr(fastStep), "%.4f", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "float", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="bool")]
def draw_bool(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<bool?> ref.rawData
    *changed = Checkbox("##{name}", val) || *changed
    default_menu(eid, name, "bool", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="Point2")]
def draw_Point2(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<float2?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat2("##{name}", addr((*val).x), "%.4f", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "Point2", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="Point3")]
def draw_Point3(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<float3?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat3("##{name}", addr((*val).x), "%.4f", ImGuiInputTextFlags None) || *changed

    default_menu(eid, name, "Point3", $() => to_string(*val), changed) <| $ [unused_argument(sub_changed)] (sub_changed)
      if imgui::Button("show me##{name}")
        draw_debug_sphere_buffered(*val, 1.0, E3DCOLOR(0xFFFFFF00), 12, 2500)
        var upPoint = *val
        upPoint.y += 150.0
        draw_debug_line_buffered(*val, upPoint, E3DCOLOR(0xFFFFFF00), 2500)

      return sub_menu |> invoke(changed)


[ecs_inspector(type_name="Point4")]
def draw_Point4(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<float4?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat4("##{name}", addr((*val).x), "%.4f", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "Point4", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="IPoint2")]
def draw_IPoint2(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<int2?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputInt2("##{name}", addr((*val).x), ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "IPoint2", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="IPoint3")]
def draw_IPoint3(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<int3?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputInt3("##{name}", addr((*val).x), ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "IPoint3", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="IPoint4")]
def draw_IPoint4(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<int4?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputInt4("##{name}", addr((*val).x), ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "IPoint4", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="TMatrix")]
def draw_TMatrix(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<float3x4?> ref.rawData
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat3("##{name}_0", addr((*val)[0].x), "%.4f", ImGuiInputTextFlags None) || *changed
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat3("##{name}_1", addr((*val)[1].x), "%.4f", ImGuiInputTextFlags None) || *changed
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat3("##{name}_2", addr((*val)[2].x), "%.4f", ImGuiInputTextFlags None) || *changed
    SetNextItemWidth(-FLT_MIN)
    *changed = InputFloat3("##{name}_3", addr((*val)[3].x), "%.4f", ImGuiInputTextFlags None) || *changed
    default_menu(eid, name, "TMatrix", $() => to_string(*val), changed) <| $(var sub_changed)
      let res = sub_menu |> invoke(sub_changed)
      if !res
        return res

      if imgui::Button("Copy position")
        imgui::CloseCurrentPopup()
        (*val)[3] |> to_string |> imgui::SetClipboardText

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
def draw_das_string(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<das_string?> ref.rawData
    var buf <- ImGuiInputTextBuffer("{*val}", length(*val) + 256)
    SetNextItemWidth(-FLT_MIN)
    if InputText("##{name}", buf, ImGuiInputTextFlags AutoSelectAll)
      *changed = true
      *val := buf |> to_string()
    buf |> clear()
    default_menu(eid, name, "string", $() => to_string(*val), changed, sub_menu)


[ecs_inspector(type_name="ecs::EntityId")]
def draw_EntityId(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<EntityId?> ref.rawData
    var uVal = uint(*val)
    let TEXT_BASE_WIDTH = CalcTextSize("A").x
    SetNextItemWidth(imgui::GetColumnWidth() - TEXT_BASE_WIDTH * 10f)
    if InputScalar("##{name}", ImGuiDataType U32, safe_addr(uVal), [[int? ]], [[int? ]], "%d", ImGuiInputTextFlags None)
      *val = EntityId(uVal)
      *changed = true
    if !!*val
      imgui_hint <| $
        return getEntityTemplateName(*val)
    SameLine()
    if Button("Select##{name}")
      editor_select_eid(*val)
    default_menu(eid, name, "Eid", $() => to_string(*val), changed, sub_menu)


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


[ecs_inspector(type_name="ecs::Object"), no_aot]
def draw_Object(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val : Object?
  unsafe
    val = reinterpret<Object?> ref.rawData

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
    imgui::Text("<empty object>")
  else
    imgui::SameLine()
    imgui::Text("object size: {len}")

  if !default_menu(eid, name, "Object", $() => to_string(*val), changed, sub_menu)
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

      unsafe
        let itRef <- it |> getEntityComponentRef() |> clone()
        let isCont = is_cont_type(itRef.userType)

        if !isCont
          imgui::TableNextRow()
          imgui::TableSetColumnIndex(0)

          let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
          TreeNodeEx(key, itFlags)
          imgui_hint(key)

          imgui::TableSetColumnIndex(1)

        render_item(eid, 0u, key, itRef, level + 1, changed) <| $(sub_changed)
          if imgui::Button("dup")
            imgui::CloseCurrentPopup()
            using <| $(var cop : ChildComponent#)
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


[ecs_inspector(type_name="ecs::Array"), no_aot]
def draw_Array(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val : Array?
  unsafe
    val = reinterpret<Array?> ref.rawData
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
    imgui::Text("<empty array>")
  else
    imgui::SameLine()
    imgui::Text("array size: {len}")

  if !default_menu(eid, name, "Array", $() => to_string(*val), changed, sub_menu)
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
      unsafe

        let itRef <- it |> getEntityComponentRef() |> clone()
        let isCont = is_cont_type(itRef.userType)

        if !isCont
          imgui::TableNextRow()
          imgui::TableSetColumnIndex(0)

          let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
          TreeNodeEx(key, itFlags)

          imgui::TableSetColumnIndex(1)

        render_item(eid, 0u, key, itRef, level + 1, changed) <| $(sub_changed)
          if imgui::Button("dup")
            using <| $(var cop : ChildComponent#)
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
def draw_any_list(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val : ContType?
  unsafe
    val = reinterpret<ContType?> ref.rawData
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
    use_this() <| $(t : SubType#)
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

  if !default_menu(eid, name, "{typeinfo(typename type<ContType>)}", $() => to_string(*val), changed, sub_menu)
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

      unsafe
        let itRef <- *val |> getEntityComponentRef(uint(idx)) |> clone()
        let isCont = is_cont_type(itRef.userType)

        if !isCont
          imgui::TableNextRow()
          imgui::TableSetColumnIndex(0)

          let itFlags = ImGuiTreeNodeFlags Leaf | ImGuiTreeNodeFlags NoTreePushOnOpen | ImGuiTreeNodeFlags Bullet
          TreeNodeEx(key, itFlags)

          imgui::TableSetColumnIndex(1)

        render_item(eid, 0u, key, itRef, level + 1, changed) <| $(sub_changed)
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
  unsafe
    return <- val[idx] |> getEntityComponentRef()

[generic]
def use_this(blk : block<(val : T#) : void>) { using(blk); }
def use_this(blk : block<(val : int#) : void>) { blk |> invoke(0); }
def use_this(blk : block<(val : uint16#) : void>) { blk |> invoke(uint16(0u)); }
def use_this(blk : block<(val : uint64#) : void>) { blk |> invoke(uint64(0u)); }
def use_this(blk : block<(val : string#) : void>) { var str : string# = ""; blk |> invoke(str); }
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
def draw_IntList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::UInt16List"), no_aot, instance_function::instance_function(draw_any_list, ContType = UInt16List, SubType = "uint16")]
def draw_UInt16List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::UInt64List"), no_aot, instance_function::instance_function(draw_any_list, ContType = UInt64List, SubType = "uint64")]
def draw_UInt64List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::StringList"), no_aot, instance_function::instance_function(draw_any_list, ContType = StringList, SubType = "string")]
def draw_StringList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::EidList"), no_aot, instance_function::instance_function(draw_any_list, ContType = EidList, SubType = EntityId)]
def draw_EidList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::FloatList"), no_aot, instance_function::instance_function(draw_any_list, ContType = FloatList, SubType = "float")]
def draw_FloatList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Point2List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Point2List, SubType = "float2")]
def draw_Point2List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Point3List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Point3List, SubType = "float3")]
def draw_Point3List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Point4List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Point4List, SubType = "float4")]
def draw_Point4List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::IPoint2List"), no_aot, instance_function::instance_function(draw_any_list, ContType = IPoint2List, SubType = "int2")]
def draw_IPoint2List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::IPoint3List"), no_aot, instance_function::instance_function(draw_any_list, ContType = IPoint3List, SubType = "int3")]
def draw_IPoint3List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::BoolList"), no_aot, instance_function::instance_function(draw_any_list, ContType = BoolList, SubType = "bool")]
def draw_BoolList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::TMatrixList"), no_aot, instance_function::instance_function(draw_any_list, ContType = TMatrixList, SubType = "float3x4")]
def draw_TMatrixList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::ColorList"), no_aot, instance_function::instance_function(draw_any_list, ContType = ColorList, SubType = "E3DCOLOR")]
def draw_ColorList(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}
[ecs_inspector(type_name="ecs::Int64List"), no_aot, instance_function::instance_function(draw_any_list, ContType = Int64List, SubType = "int64")]
def draw_Int64List(eid : EntityId; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void {}

def is_cont_type(user_type : uint) : bool
  let typeName = getComponentTypes() |> component_types_findTypeName(user_type)
  return (
         typeName == "ecs::Object"
      || typeName == "ecs::Array"
      || typeName == "ecs::IntList"
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
    )


def render_item(eid : EntityId; flags : uint; name : string implicit; ref : EntityComponentRef# implicit; level : int; var changed : bool? implicit; sub_menu : block<(var changed : bool?) : bool>) : void
  let typeName = getComponentTypes() |> component_types_findTypeName(ref.userType)
  var hasInspector = false
  if has_inspector(typeName)
    hasInspector = call_inspector(typeName, eid, flags, name, ref, level, changed, sub_menu)
  if !hasInspector
    imgui::Text("{typeName} <{ref.userType}>")
    default_menu(eid, name, typeName, changed) <| $ [unused_argument(sub_changed)] (sub_changed)

      if imgui::Button("copy type id##{name}")
        imgui::SetClipboardText("{ref.userType}")

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


def inspect_item(eid : EntityId)
  let templateName = getEntityTemplateName(eid)
  let TEXT_BASE_WIDTH = CalcTextSize("A").x

  if imgui::Button("*##{templateName}")
    imgui::OpenPopup("template_menu_{templateName}")

  if imgui::BeginPopup("template_menu_{templateName}")

    if imgui::Button("copy eid")
      imgui::CloseCurrentPopup()
      imgui::SetClipboardText("{eid}")

    imgui::SameLine()
    if imgui::Button("copy blk")
      imgui::CloseCurrentPopup()
      using <| $(var blk : DataBlock#)
        var sub = blk |> datablock_add_new_block("entity")
        var tName = getEntityTemplateName(eid)
        tName = remove_sub_template_name(tName, "daeditor_selected")
        eid |> components_to_blk(*sub, "", false)
        sub |> datablock_addStr("_template", tName)
        imgui::SetClipboardText(string(blk))

    imgui::SameLine()
    if imgui::Button("copy blk diff")
      imgui::CloseCurrentPopup()
      using <| $(var blk : DataBlock#)
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
  imgui::TextUnformatted("{eid}: {templateName}")
  imgui_hint(templateName)

  imgui::Separator()
  call_editor(/*prefix*/true, eid)

  DasHelpMarker("Filter (\"incl,-excl\")")
  imgui::SameLine()
  SetNextItemWidth(-FLT_MIN)
  static_let_finalize <|
    var filter = new ImGuiTextFilter
  static_let <|
    var componentsNum = 0

  *filter |> Draw("##{eid}")
  imgui::BeginChild("sub", float2(0, 0))
  let tmp = getTemplateByName(templateName)
  if BeginTable("split", 3, ImGuiTableFlags Resizable | ImGuiTableFlags BordersOuter | ImGuiTableFlags RowBg)
    TableSetupColumn("name", ImGuiTableColumnFlags WidthStretch)
    TableSetupColumn("value", ImGuiTableColumnFlags WidthStretch)
    TableSetupColumn("menu", ImGuiTableColumnFlags WidthFixed, TEXT_BASE_WIDTH * 2f)
    using() <| $(var clipper : ImGuiListClipper#)
      clipper |> Begin(componentsNum, imgui::GetTextLineHeightWithSpacing())
      let isClipperValid = clipper |> Step()
      componentsNum = 0
      var currentIndex = 0
      getComponentsIterator(eid) <| $(name, type_info)
        let comp = getDataComponents() |> data_components_getComponentById(type_info.componentId)
        if (uint(comp.flags) & uint(IS_COPY)) != 0u
          return
        if !(*filter |> PassFilter(name))
          return

        if !isClipperValid || currentIndex < clipper.DisplayStart || currentIndex >= clipper.DisplayEnd
          componentsNum += 1
          currentIndex += 1
          return

        let flags = tmp != null ? getRegExpInheritedFlags(tmp, name) : 0u
        let idxBefore = TableGetRowIndex()
        if !is_cont_type(type_info.userType)
          TableNextRow()
          TableNextColumn()
          imgui::Text(item_flags(flags, name))
          imgui_hint(name)
          TableNextColumn()

        var changed = false
        render_item(eid, flags, name, type_info, 0, safe_addr(changed)) <| $ [unused_argument(_)] (_) => true
        if changed
          entity_obj_editor_saveComponent(eid, name)
          invalidate_item(eid, type_info)

        let rowsNum = TableGetRowIndex() - idxBefore
        componentsNum += rowsNum
        currentIndex += rowsNum

      clipper |> End()

    EndTable()

  call_editor(/*prefix*/false, eid)
  imgui::EndChild()


[no_aot]
def invalidate_item(eid : EntityId; ref : EntityComponentRef# implicit)
  nada(getComponentRefRW(eid, ref.componentId))


[sideeffects, unused_argument(ref)]
def nada(var ref : EntityComponentRef)
  pass

