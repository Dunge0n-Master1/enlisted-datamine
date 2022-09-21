require ecs
require BehNodes
require DagorDataBlock
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspectors_macro
require imgui

[ecs_inspector(type_name="BehaviourTree")]
def draw_BehaviourTree(eid : array<EntityId> const#; flags : uint; name : string; ref : EntityComponentRef#; level : int; var changed : bool?; sub_menu : block<(var changed : bool?) : bool>) : void
  unsafe
    var val = reinterpret<BehaviourTree ??> ref.rawData
    let behTree & = **val
    imgui::AlignTextToFramePadding()
    imgui::Text("{behTree.root.name}")
    imgui::SameLine()
    if imgui::Button("blackboard")
      print("{eid}: beh tree {behTree.root.name} blackboard:")
      print(behTree.blackBoard |> string())
    default_menu(eid, name, "BehaviourTree", changed, sub_menu)
