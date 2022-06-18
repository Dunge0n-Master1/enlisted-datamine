options no_aot
require DagorImgui
require DagorConsole


[console_cmd(name="editor.ecs_scene")]
def show_ecs_scene()
  let isVisible = imgui_get_state() != ImGuiState OFF && imgui_window_is_visible("Editor", "Scene")
  let setVisible = !isVisible
  console_command(setVisible ? "imgui.activate" : "imgui.off")
  imgui_window_set_visible("Editor", "Scene", setVisible)


[init]
def init_ecs_inspector_shortcut()
  console_command("consoleKeybindings.bind ctrl+shift+/ editor.ecs_scene")
