options no_aot
require ecs
require ecs.soa_template
require imgui
require DagorImgui
require DagorConsole
require DagorDataBlock
require EcsUtils
require enlisted.game.es.blk_utils_common
require strings

require daslib/static_let
require daslib/safe_addr


[soa_template]
struct MoveCockpitDebugIkNode
  move_cockpit_node__offset : float3
  move_cockpit_node__rotation : float2


def save_cockpit_nodes(eid : EntityId)
  using <| $(var blk : DataBlock#)
    components_to_blk(eid, blk, "move_cockpit_node__", true)
    let templateName = getEntityTemplateName(eid)
    datablock_get_block(blk, "offset:list<p3>") <| $(offsetArrayBlk)
      save_block_to_origin_template(templateName, "move_cockpit_node__offset:list<p3>", offsetArrayBlk)
    datablock_get_block(blk, "rotation:list<p2>") <| $(rotationArrayBlk)
      save_block_to_origin_template(templateName, "move_cockpit_node__rotation:list<p2>", rotationArrayBlk)


def copy_component_value_to_clipboard(eid : EntityId; component_name : string; component_type : string)
  using <| $(var blk : DataBlock#)
    components_to_blk(eid, blk, component_name, false)
    datablock_get_block(blk, component_type) <| $(offsetArrayBlk)
      SetClipboardText("{offsetArrayBlk}")


[imgui_window(name="Airplane IK Nodes Editor", group="Gameplay")]
def airplane_ik_nodes_editor_debug_window()
  var cockpitFound = false
  query() <| $ [soa_blk, es] (eid : EntityId;
                              cockpit__vehicleEid : EntityId;
                              move_cockpit_node__nodeName : StringList;
                              move_cockpit_ik_node : MoveCockpitDebugIkNode_SOA)
    cockpitFound = true

    let rotPrecision = 0.1
    let minRot = -180.0
    let maxRot = 180.0

    let offsetPrecision = 0.0005
    let minOffset = -0.05
    let maxOffset = 0.05

    imgui::Text("Editing cockpit {getEntityTemplateName(eid)} of {cockpit__vehicleEid}")

    if length(move_cockpit_ik_node) != length(move_cockpit_node__nodeName)
      imgui::TextColored(float4(1.0f, 0.0, 0.0, 1.0),
        "move_cockpit_node__nodeName and move_cockpit_node__offset/rotation length mismatch!")
      return

    imgui::SameLine()
    if imgui::Button("Copy offsets to clipboard")
      copy_component_value_to_clipboard(eid, "move_cockpit_node__offset", ":list<p3>")

    imgui::SameLine()
    if imgui::Button("Copy rotations to clipboard")
      copy_component_value_to_clipboard(eid, "move_cockpit_node__rotation", ":list<p2>")

    if imgui::Button("Save (might change .blk file formatting")
      save_cockpit_nodes(eid)

    for node, nodeName in move_cockpit_ik_node, move_cockpit_node__nodeName
      imgui::Separator()
      imgui::Text("Node: {nodeName}")

      imgui::DragScalar("##{nodeName}rotx", ImGuiDataType Float, safe_addr(node.move_cockpit_node__rotation.x),
        rotPrecision, safe_addr(minRot), safe_addr(maxRot), "%.2f", ImGuiSliderFlags None)
      imgui::SameLine()
      imgui::Text("Rotation X")

      imgui::DragScalar("##{nodeName}roty", ImGuiDataType Float, safe_addr(node.move_cockpit_node__rotation.y),
        rotPrecision, safe_addr(minRot), safe_addr(maxRot), "%.2f", ImGuiSliderFlags None)
      imgui::SameLine()
      imgui::Text("Rotation Y")

      imgui::DragScalar("##{nodeName}offsx", ImGuiDataType Float, safe_addr(node.move_cockpit_node__offset.x),
        offsetPrecision, safe_addr(minOffset), safe_addr(maxOffset), "%.4f", ImGuiSliderFlags None)
      imgui::SameLine()
      imgui::Text("Offset X (Forward)")

      imgui::DragScalar("##{nodeName}offsy", ImGuiDataType Float, safe_addr(node.move_cockpit_node__offset.y),
        offsetPrecision, safe_addr(minOffset), safe_addr(maxOffset), "%.4f", ImGuiSliderFlags None)
      imgui::SameLine()
      imgui::Text("Offset Y (Left)")

      imgui::DragScalar("##{nodeName}offsz", ImGuiDataType Float, safe_addr(node.move_cockpit_node__offset.z),
        offsetPrecision, safe_addr(minOffset), safe_addr(maxOffset), "%.4f", ImGuiSliderFlags None)
      imgui::SameLine()
      imgui::Text("Offset Z (Up)")

  if !cockpitFound
    imgui::Text("Not in a cockpit")
