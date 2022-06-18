options no_aot
require ecs
require imgui
require DagorImgui
require DagorConsole
require strings

require daslib/static_let
require daslib/safe_addr


struct RespawnInfo
  eid : EntityId
  pos : float3
  respawnBaseGroup : int
  team : int

def operator <(a, b : RespawnInfo)
  return uint(a.eid) < uint(b.eid)

def imgui_click_to_select_in_editor(eid)
  if imgui::IsItemHovered()
    imgui::BeginTooltip()
    imgui::PushTextWrapPos(GetFontSize() * 35.0f)
    imgui::TextUnformatted("LMB click to select in editor")
    imgui::PopTextWrapPos()
    imgui::EndTooltip()
    if imgui::IsMouseClicked(ImGuiMouseButton Left)
      console_command("daEd4.selectEid {eid}")
      console_command("daEd4.zoom")

[imgui_window(name="Respawns Debug", group="Gameplay")]
def mission_respawns_debug_window()
  var respawnByGroupName : table<string; array<RespawnInfo>>
  query() <| $ [es(REQUIRE_NOT=vehicleRespbase)] (eid : EntityId;
                                                  transform : float3x4;
                                                  team : int;
                                                  respawnBaseGroup : int;
                                                  groupName : string)
    if team != -1
      respawnByGroupName[groupName] |> push([[RespawnInfo eid=eid, pos=transform[3], respawnBaseGroup = respawnBaseGroup, team = team]])
      sort(respawnByGroupName[groupName])

  static_let <|
    var showProblemsOnly = true
    var maxTeamSpawnsDist = 50.0
    var minEnemySpawnsDist = 100.0
  let min = 1.0
  let max = 300.0
  imgui::Checkbox("Problems only", safe_addr(showProblemsOnly))
  imgui::SameLine()
  SetNextItemWidth(100.0)
  imgui::DragScalar("Max Team Spawns Dist", ImGuiDataType Float, safe_addr(maxTeamSpawnsDist),
    1.0, safe_addr(min), safe_addr(max), "%.2f", ImGuiSliderFlags None)
  imgui::SameLine()
  SetNextItemWidth(100.0)
  imgui::DragScalar("Min Enemy Spawns Dist", ImGuiDataType Float, safe_addr(minEnemySpawnsDist),
    1.0, safe_addr(min), safe_addr(max), "%.2f", ImGuiSliderFlags None)

  for key, value in keys(respawnByGroupName), values(respawnByGroupName)
    imgui::Text("{key}")
    if BeginTable("respawns_{key}", 6, ImGuiTableFlags BordersOuter | ImGuiTableFlags RowBg)
      TableSetupColumn("Respawn", ImGuiTableColumnFlags WidthFixed)
      TableSetupColumn("Team", ImGuiTableColumnFlags WidthFixed)
      TableSetupColumn("Respawn 2", ImGuiTableColumnFlags WidthFixed)
      TableSetupColumn("Distance", ImGuiTableColumnFlags WidthFixed)
      TableSetupColumn("Problem", ImGuiTableColumnFlags WidthFixed)

      while length(value) > 0
        let respawn = value[0]
        for otherRespawn in value
          if respawn.eid == otherRespawn.eid
            continue
          let distance = length(respawn.pos - otherRespawn.pos)

          let isOpposingTeams = respawn.team != otherRespawn.team
          let isSameRespawnBaseGroup = respawn.respawnBaseGroup == otherRespawn.respawnBaseGroup

          var note : string
          if isOpposingTeams && distance < minEnemySpawnsDist
            note = "Opposing teams spawns are too close!"
          elif !isOpposingTeams && isSameRespawnBaseGroup && distance > maxTeamSpawnsDist
            note = "Respawns from one group are too far apart!"
          elif showProblemsOnly
            continue

          imgui::TableNextRow()
          imgui::TableNextColumn()
          imgui::Text("{respawn.eid}")
          imgui_click_to_select_in_editor(respawn.eid)
          imgui::TableNextColumn()
          imgui::TextColored(isOpposingTeams ? float4(1.0f, 0.0, 0.0, 1.0) : float4(0.0, 1.0, 0.0, 1.0),
            isOpposingTeams ? "xx" : "<>")
          imgui::TableNextColumn()
          imgui::Text("{otherRespawn.eid}")
          imgui_click_to_select_in_editor(otherRespawn.eid)
          imgui::TableNextColumn()
          imgui::Text(format("%.1f", distance))
          imgui::TableNextColumn()
          imgui::TextColored(float4(1.0, 0.0, 0.0, 1.0), note)
        value |> erase(0)

    EndTable()