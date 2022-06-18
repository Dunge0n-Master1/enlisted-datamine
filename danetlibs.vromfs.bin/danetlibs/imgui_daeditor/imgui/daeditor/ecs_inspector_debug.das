options no_aot
require ecs
require DagorConsole
require DagorImgui
require daslib/static_let
require imgui/imgui_boost
require danetlibs.imgui_daeditor.daEditor.daEditor_common
require danetlibs.imgui_daeditor.imgui.daEditor.ecs_inspector_common


[console_cmd(name="editor.ecs_inspector")]
def show_ecs_inspector()
  let isVisible = imgui_get_state() != ImGuiState OFF && imgui_window_is_visible("Editor", "Inspector")
  let setVisible = !isVisible
  console_command(setVisible ? "imgui.activate" : "imgui.off")
  imgui_window_set_visible("Editor", "Inspector", setVisible)


[init]
def init_ecs_inspector_shortcut()
  console_command("consoleKeybindings.bind ctrl+shift+; editor.ecs_inspector")


[imgui_window(name="Inspector", group="Editor", hotkey="Ctrl+Shift+;")]
def ecs_inspector()
  static_let <|
    var previuous_eid = INVALID_ENTITY_ID
    var current_eid = INVALID_ENTITY_ID

  let found = find_query <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId)
    if current_eid != eid
      previuous_eid = current_eid
      current_eid = eid

    if IsWindowCollapsed()
      return true

    if previuous_eid != INVALID_ENTITY_ID
      if imgui::Button("Back")
        editor_select_eid(previuous_eid)
      imgui::SameLine()
    inspect_item(eid)
    return true

  if !found
    imgui::Text("Select any entity")
