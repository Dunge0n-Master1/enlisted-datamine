require ecs
require BehNodes
require DagorDataBlock
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require imgui
require walkerai


[ecs_inspector(type_name="BehaviourTree")]
def draw_BehaviourTree(eid : array<EntityId> implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<BehaviourTree ??> refs[0].rawData)
  assume behTree = **val
  imgui::AlignTextToFramePadding()
  imgui::Text("{behTree.root.name}")
  imgui::SameLine()
  if imgui::Button("blackboard")
    print("{eid}: beh tree {behTree.root.name} blackboard:")
    print(behTree.blackBoard |> string())
  default_menu(eid, name, "BehaviourTree", changed, sub_menu)


[ecs_inspector(type_name="walkerai::Target")]
def draw_walkeraiTarget(eid : array<EntityId> const implicit; flags : uint; name : string; refs : array<EntityComponentRef#>#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  var val = unsafe(reinterpret<Target?> refs[0].rawData)
  assume target = *val
  imgui::AlignTextToFramePadding()
  imgui::Text("ai::Target hidden:{target.isHidden} downed:{target.isDowned}")
  default_menu(eid, name, "walkerai::Target", changed, sub_menu)
