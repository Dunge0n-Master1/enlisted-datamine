options no_aot
options persistent_heap
options gc
require ecs
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


[imgui_window(name="Inspector", group="Editor", hotkey="Ctrl+Shift+;")]
def ecs_inspector()
  if IsWindowCollapsed()
    return

  static_let <|
    let maxUndoRedoStack = 512
    var undoStack : array<EntityId>
    var redoStack : array<EntityId>
    var current_eid = INVALID_ENTITY_ID
    var gcSteps = 0

  gcSteps += 1
  if gcSteps > 1000
    unsafe(heap_collect())
    gcSteps = 0

  var new_eid = INVALID_ENTITY_ID
  var amount = 0
  find_query <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId)
    if !new_eid
      new_eid = eid
    amount ++
    return amount > 1

  if amount <= 1 && current_eid != new_eid
    if !!current_eid && (empty(undoStack) || back(undoStack) != current_eid)
      while length(undoStack) > maxUndoRedoStack
        undoStack |> erase(0)
      undoStack |> push(current_eid)
    redoStack |> clear()
    current_eid = new_eid
    if !!current_eid
      editor_select_eid(current_eid)

  if imgui::Button(empty(undoStack) ? "-" : "<") && !empty(undoStack)
    let undoEid = undoStack |> back()
    undoStack |> pop()
    if !!current_eid && (empty(redoStack) || back(redoStack) != current_eid)
      while length(redoStack) > maxUndoRedoStack
        redoStack |> erase(0)
      redoStack |> push(current_eid)
    current_eid = undoEid
    editor_select_eid(undoEid)
  if !empty(undoStack)
    imgui_hint(getEntityTemplateName(undoStack |> back()))
  imgui::SameLine()

  if imgui::Button(empty(redoStack) ? "-" : ">") && !empty(redoStack)
    let redoEid = redoStack |> back()
    redoStack |> pop()
    if !!current_eid && (empty(undoStack) || back(undoStack) != current_eid)
      while length(undoStack) > maxUndoRedoStack
        undoStack |> erase(0)
      undoStack |> push(current_eid)
    current_eid = redoEid
    editor_select_eid(current_eid)
  if !empty(redoStack)
    imgui_hint(getEntityTemplateName(redoStack |> back()))
  imgui::SameLine()

  if !!new_eid
    if imgui::Button("@")
      entity_object_editor_zoomAndCenter()
    imgui_hint("Zoom camera to selected enitity")
    imgui::SameLine()
    inspect_item(new_eid)
  else
    imgui::Text("Select any entity")
