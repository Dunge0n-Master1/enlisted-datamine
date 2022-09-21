options no_aot
options persistent_heap
options gc
require ecs
require strings
require DagorConsole
require DagorEditor
require DagorImgui
require daslib/static_let
require imgui/imgui_boost
require daslib/array_boost
require danetlibs.imgui_daeditor.daEditor.daEditor_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common


[console_cmd(name="imgui.editor_ecs_inspector")]
def show_ecs_inspector()
  let isVisible = imgui_get_state() != ImGuiState OFF && imgui_window_is_visible("Editor", "Inspector")
  let setVisible = !isVisible
  console_command(setVisible ? "imgui.activate" : "imgui.off")
  imgui_window_set_visible("Editor", "Inspector", setVisible)


[init]
def init_ecs_inspector_shortcut()
  console_command("consoleKeybindings.bind ctrl+shift+; imgui.editor_ecs_inspector")


def private eids_hint(eids : array<EntityId>)
  let n = length(eids)
  if n == 0
    return ""
  if n == 1
    return getEntityTemplateName(eids[0])
  return build_string() <| $(str)
    str |> write(n)
    str |> write("\n")
    var first = true
    let limit = 3
    for eid, _ in eids, range(limit)
      if first
        first = false
      else
        str |> write(",\n")
      str |> write(eid)
      str |> write(": ")
      str |> write(getEntityTemplateName(eid))
    if length(eids) > limit
      str |> write("\n...")


[imgui_window(name="Inspector", group="Editor", hotkey="Ctrl+Shift+;")]
def ecs_inspector()
  if IsWindowCollapsed()
    return

  static_let <|
    let maxUndoRedoStack = 512
    var undoStack : array<array<EntityId>>
    var redoStack : array<array<EntityId>>
    var current_eid : array<EntityId>
    var gcSteps = 0

  gcSteps += 1
  if gcSteps > 1000
    unsafe(heap_collect())
    gcSteps = 0

  var new_eid : array<EntityId>
  query <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId)
    new_eid |> push(eid)

  new_eid |> sort() <| $(left, right : EntityId)
    return uint(left) < uint(right)

  let newSelection = compare_eids(current_eid, new_eid) != 0
  if newSelection
    if length(current_eid) > 0 && (empty(undoStack) || compare_eids(back(undoStack), current_eid) != 0)
      while length(undoStack) > maxUndoRedoStack
        undoStack |> erase(0)
      undoStack |> push_clone(current_eid)
    redoStack |> clear()
    current_eid := new_eid

  if imgui::Button(empty(undoStack) ? "-" : "<") && !empty(undoStack)
    let undoEid <- undoStack |> back()
    undoStack |> pop()
    if length(current_eid) > 0 && (empty(redoStack) || compare_eids(back(redoStack), current_eid) != 0)
      while length(redoStack) > maxUndoRedoStack
        redoStack |> erase(0)
      redoStack |> push_clone(current_eid)
    current_eid := undoEid
    entity_object_unselectAll()
    for eid in undoEid
      entity_object_editor_selectEntity(eid, true)
  if !empty(undoStack) && length(undoStack[length(undoStack) - 1]) > 0
    imgui_hint() <| $() => eids_hint(undoStack |> back())
  imgui::SameLine()

  if imgui::Button(empty(redoStack) ? "-" : ">") && !empty(redoStack)
    let redoEid <- redoStack |> back()
    redoStack |> pop()
    if length(current_eid) > 0 && (empty(undoStack) || compare_eids(back(undoStack), current_eid) != 0)
      while length(undoStack) > maxUndoRedoStack
        undoStack |> erase(0)
      undoStack |> push_clone(current_eid)
    current_eid := redoEid
    entity_object_unselectAll()
    for eid in current_eid
      entity_object_editor_selectEntity(eid, true)
  if !empty(redoStack) && length(redoStack[length(redoStack) - 1]) > 0
    imgui_hint() <| $() => eids_hint(redoStack |> back())
  imgui::SameLine()

  if length(new_eid) > 0
    if imgui::Button("@")
      entity_object_editor_zoomAndCenter()
    imgui_hint("Zoom camera to selected enitity")
    imgui::SameLine()
    inspect_item(unsafe(reinterpret< array<EntityId># > new_eid), newSelection)
  else
    imgui::Text("Select any entity")
