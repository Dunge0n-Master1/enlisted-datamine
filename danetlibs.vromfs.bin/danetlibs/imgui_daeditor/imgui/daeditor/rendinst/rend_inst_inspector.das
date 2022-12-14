
require ecs
require DagorSystem
require DagorDataBlock
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require imgui
require RendInst


[ecs_inspector(type_name="RiExtraComponent")]
def draw_RiExtraComponent(eid : array<EntityId>#; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<RiExtraComponent?> refs[0].rawData)
  Text("handle={val.handle} {intptr(val)}")
  default_menu(eid, name, "RiExtraComponent", $() => to_string(val.handle), $(str) { logerr("RiExtraComponent to string not implemented! str={str}"); }, $() => "ri_extra\{}", changed, sub_menu)
