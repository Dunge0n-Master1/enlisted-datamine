require ecs
require DagorImgui
require DagorEditor
require DagorConsole
require imgui/imgui_boost
require daslib/static_let
require daslib/safe_addr


[imgui_window(name="Scene", group="Editor", hotkey="Ctrl+Shift+/")]
def ecs_scene_window()

  static_let_finalize <|
    var filter = new ImGuiTextFilter
  static_let <|
    var selectedItem = INVALID_ENTITY_ID

  if IsWindowCollapsed()
    return

  SetNextItemWidth(-FLT_MIN)
  *filter |> Draw("##entitiesFilter")

  imgui::BeginChild("sub", float2(0., -20.))

  var totalNum = 0

  if BeginTable("split", 2, ImGuiTableFlags BordersOuter | ImGuiTableFlags RowBg)
    TableSetupColumn("eid", ImGuiTableColumnFlags WidthFixed)
    TableSetupColumn("template", ImGuiTableColumnFlags WidthStretch)
    entity_obj_editor_for_each_entity() <| $(ent)
      let eidStr = "{int(uint(ent.eid))}"
      let templateStr = getEntityTemplateName(ent.eid)
      if !(*filter |> PassFilter(eidStr)) && !(*filter |> PassFilter(templateStr))
        return
      imgui::TableNextRow()
      imgui::TableNextColumn()
      imgui::Text(eidStr)
      imgui::TableNextColumn()
      var selected = selectedItem == ent.eid
      if imgui::Selectable("{templateStr}##{eidStr}", safe_addr(selected), ImGuiSelectableFlags AllowDoubleClick)
        selectedItem = ent.eid
        if imgui::IsMouseDoubleClicked(ImGuiMouseButton Left)
          console_command("daEd4.selectEid {eidStr}")
          console_command("daEd4.zoom")

      totalNum += 1

    imgui::EndTable()

  imgui::EndChild()

  imgui::Text("Total: {totalNum}")
