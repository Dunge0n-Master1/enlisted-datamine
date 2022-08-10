options no_aot
options persistent_heap
options gc

require DagorTime
require ecs
require DagorImgui
require DagorEditor
require DagorConsole
require imgui/imgui_boost
require daslib/static_let
require daslib/strings_boost
require daslib/safe_addr
require daslib/algorithm
require %danetlibs.imgui_daeditor.daEditor.daEditor_common


struct EntityData
  eid : EntityId
  eidStr : string
  templateStr : string
  distance : float


[imgui_window(name="Scene", group="Editor", hotkey="Ctrl+Shift+/")]
def ecs_scene_window()
  if IsWindowCollapsed()
    return

  static_let_finalize <|
    var filter = new ImGuiTextFilter
  static_let <|
    var allEntities : array<EntityId>
    var prevData : array<EntityData>
    var data : array<EntityData>

    var shingles : array<string>
    var totalFilterLength = 0

    var dataIndex = 0
    var selectedItem = INVALID_ENTITY_ID
    var editedItem = INVALID_ENTITY_ID
    var lastUpdateDate = DagorTime::ref_time_ticks()
    var gcSteps = 0

  gcSteps += 1
  if gcSteps > 1000
    unsafe(heap_collect())
    gcSteps = 0

  SetNextItemWidth(-FLT_MIN)
  *filter |> Draw("##entitiesFilter")

  imgui::BeginChild("sub", float2(0., -20.))

  if BeginTable("split", 2, ImGuiTableFlags BordersOuter | ImGuiTableFlags RowBg)
    TableSetupColumn("eid", ImGuiTableColumnFlags WidthFixed)
    TableSetupColumn("template", ImGuiTableColumnFlags WidthStretch)

    let now = DagorTime::ref_time_ticks()
    let dt = DagorTime::get_time_usec(int64(lastUpdateDate))
    let sec = double(dt) / double(1000_000)
    if sec > 0.2lf && length(allEntities) == 0
      lastUpdateDate = now
      prevData <- data
      allEntities |> clear()
      allEntities |> reserve(4096 * 8)
      delete data
      data |> reserve(1024)

      var filters : table<string; int>
      for filterRange in filter.Filters
        if !filterRange |> empty()
          let filterString = string(filterRange)
          filters[filterString] = length(filterString)

      delete shingles
      totalFilterLength = 0
      for filterString, filterStringLength in keys(filters), values(filters)
        totalFilterLength += filterStringLength
        for i in range(filterStringLength - 1)
          shingles |> push(slice(filterString, i, i + 2))

      entity_obj_editor_for_each_entity() <| $(ent)
        allEntities |> push(ent.eid)

    var selectedEid = INVALID_ENTITY_ID
    query() <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId)
      selectedEid = eid
    let selectedTemplateLength = length("+daeditor_selected")
    var allEntitiesNum = length(allEntities)
    if allEntitiesNum > 0
      let hasFilters = length(shingles) > 0
      var entitiesPerFrame = length(shingles) == 0 ? 10000 : 5000
      let allowedMismatchesByFilterLength <- [[int[] 3; 3; 5; 8; 10; 13]]
      var maxMismatches = 0
      for m in allowedMismatchesByFilterLength
        if totalFilterLength > m
          maxMismatches ++
        else
          break
      while entitiesPerFrame-- > 0 && allEntitiesNum > 0
        let eid = allEntities[--allEntitiesNum]
        allEntities |> resize(allEntitiesNum)
        let eidStr = string(int(uint(eid)))
        let templateStr = getEntityTemplateName(eid)
        if hasFilters
          var misNeighbourCount = 0
          var mismatchCount = 0
          var prevIdx = -1
          if !(*filter |> PassFilter(eidStr))
            for shingle in shingles
              let idx = find(templateStr, shingle)
              if idx == -1
                mismatchCount++
                if mismatchCount > maxMismatches
                  break
              elif prevIdx != -1 && prevIdx + 1 != idx
                misNeighbourCount++
              prevIdx = idx
            if mismatchCount > maxMismatches
              continue
          let templStrLength = length(templateStr) - (eid == selectedEid ? selectedTemplateLength : 0)
          let itemDistance = float(mismatchCount) + abs(float(templStrLength) - float(length(shingles) + 1)) * 0.015 + float(misNeighbourCount) * 0.5
          var value = [[EntityData eid=eid, eidStr=eidStr, templateStr=templateStr, distance=itemDistance]]
          let insertIdx = lower_bound(data, value) <| $(x, y) => x.distance < y.distance
          data |> emplace(value, insertIdx)
        else
          data |> emplace <| [[EntityData eid=eid, eidStr=eidStr, templateStr=templateStr]]

    var selected : bool
    var selectedAddr = safe_addr(selected)

    using() <| $(var clipper : ImGuiListClipper#)
      clipper |> Begin(length(prevData), imgui::GetTextLineHeightWithSpacing())
      while clipper |> Step()
        for idx in range(clipper.DisplayStart, clipper.DisplayEnd)
          let eid = prevData[idx].eid
          let eidStr = prevData[idx].eidStr
          let templateStr = prevData[idx].templateStr
          imgui::TableNextRow()
          imgui::TableNextColumn()
          imgui::Text(eidStr)
          imgui::TableNextColumn()
          selected = selectedItem == eid
          imgui::PushID(eidStr)
          if imgui::Selectable(templateStr, selectedAddr, ImGuiSelectableFlags AllowDoubleClick)
            selectedItem = eid
            if imgui::IsMouseDoubleClicked(ImGuiMouseButton Left)
              if GetIO().KeyCtrl
                editedItem = eid
                entity_object_editor_selectEntity(eid, !has(eid, "daeditor__selected"))
              elif GetIO().KeyShift
                var doSelect = false
                for it in prevData
                  entity_object_editor_selectEntity(it.eid, doSelect)
                  if it.eid == eid || it.eid == editedItem
                    entity_object_editor_selectEntity(it.eid, true)
                    doSelect = !doSelect
              else
                editedItem = eid
                editor_select_eid(eid)
                entity_object_editor_zoomAndCenter()
          imgui::PopID()

    imgui::EndTable()

  imgui::EndChild()

  imgui::Text("Total: {length(prevData)}")


[console_cmd(name="imgui.editor_ecs_scene")]
def show_ecs_scene()
  let isVisible = imgui_get_state() != ImGuiState OFF && imgui_window_is_visible("Editor", "Scene")
  let setVisible = !isVisible
  console_command(setVisible ? "imgui.activate" : "imgui.off")
  imgui_window_set_visible("Editor", "Scene", setVisible)


[init]
def init_ecs_inspector_shortcut()
  console_command("consoleKeybindings.bind ctrl+shift+/ imgui.editor_ecs_scene")