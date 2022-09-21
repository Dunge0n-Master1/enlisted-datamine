require ecs
require DagorImgui
require danetlibs/motion_matching/debug_ui/motion_matching_ui_common
require imgui

require imgui/imgui_node_editor_boost
require daslib/static_let
require daslib/safe_addr

[imgui_window(name="motion matching", group="Anim")]
def motion_matching_imgui_es()
  if IsWindowCollapsed()
    return

  let found = find_query <| $ [es(REQUIRE=watchedByPlr)] (eid : EntityId)
    motion_matching_imgui(eid)
    return true

  if !found
    imgui::Text("Select any entity")