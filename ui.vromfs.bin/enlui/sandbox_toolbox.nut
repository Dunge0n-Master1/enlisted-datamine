from "%enlSqGlob/ui_library.nut" import *
from "%darg/laconic.nut" import *
import "%dngscripts/ecs.nut" as ecs

let fa = require("%ui/components/fontawesome.map.nut")
let {fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let cursors = require("%daeditor/components/cursors.nut")
let textButton = require("%daeditor/components/textButton.nut")
let {slider} = require("%daeditor/components/slider.nut")
let {round_by_value} = require("%sqstd/math.nut")

let {showPointAction, namePointAction, propPanelVisible} = require("%daeditor/state.nut")

let {terraformParams, beginTerraforming, isTerraforming, isTerraformingMode,
  POINTACTION_MODE_TERRAFORMING, POINTACTION_MODE_CLEAR_ELEVATIONS,
  POINTACTION_MODE_ERASE_GRASS,  POINTACTION_MODE_DELETE_GRASS_ERASERS } = require("%ui/editorTerraforming.nut")

let {isRIToolMode, beginRIToolMode, clearRIToolSelected, riToolSelected, getRIToolRemovedCount,
     unbakeRIToolSelected, enbakeRIToolSelected, rebakeRIToolSelected,
     removeRIToolSelected, instanceRIToolSelected, selectRIToolInside,
     restoreRemovedByRITool, spawnNewRIEntity} = require("%ui/editorToolRendInsts.nut")

let {groupsList, updateGroupsList, mkGroupListItemName, mkGroupListItemTooltip,
     toggleGroupListItem} = require("%ui/editorGroupsControl.nut")

let {getEditMode=null, DE4_MODE_POINT_ACTION=null} = require_optional("daEditor4")

let {EventNavMeshRebuildStarted, EventNavMeshRebuildProgress,
     EventNavMeshRebuildComplete, EventNavMeshRebuildCancelled} = require("dasevents")

let {get_scene_filepath = null} = require_optional("entity_editor")
let {system = null} = require_optional("system")


local toolboxShowMsgbox = @(_) null
let function setToolboxShowMsgbox(fn) {
  toolboxShowMsgbox = fn
}

let toolboxShown = Watched(false)
let toolboxModes = Watched({
  dev = false
  coll = false
  nav = false
  polyAreas = false
  capZones = false
  capZonesPoly = false
  respawns = 0
  showGroups = false
  showCommands = false
  rebuildNavMeshState = ""
  rebuildingNavMesh = false
})

let function setToolboxMode(mode, val) {
  toolboxModes.value[mode] = val
  toolboxModes.trigger()
}

let function toggleGroups() {
  if (!toolboxModes.value.showGroups)
    updateGroupsList()
  setToolboxMode("showGroups", !toolboxModes.value.showGroups)
}

let function toggleCommands() {
  setToolboxMode("showCommands", !toolboxModes.value.showCommands)
}

let function toolboxRunCmd(cmd, cmd2 = null, mode = null, val = null) {
  if (cmd == "dev_mode_restart") {
    toolboxShowMsgbox({text="Restart required to disable DevMode"})
    return
  }
  if (cmd2 == "close")
    toolboxShown(false)
  console_command(cmd)
  if (cmd2 != null && cmd2 != "close")
    console_command(cmd2)
  if (mode != null)
    setToolboxMode(mode, val)
}

let function toolboxCmd_RebuildNavMesh() {
  if (toolboxModes.value.rebuildingNavMesh)
    console_command("navmesh.rebuild_cancel")
  else if (toolboxModes.value.rebuildNavMeshState != "") {
    toolboxModes.value.rebuildNavMeshState = ""
    toolboxModes.trigger()
  }
  else
    console_command("navmesh.rebuild_start")
}

ecs.register_es("sandbox_navmesh_rebuild_es",
  {
    [EventNavMeshRebuildStarted] = function(_evt, _eid, _c){
      toolboxModes.value.rebuildNavMeshState = ""
      toolboxModes.value.rebuildingNavMesh = true
      toolboxModes.trigger()
    },

    [EventNavMeshRebuildProgress] = function(evt, _eid, _c){
      toolboxModes.value.rebuildNavMeshState = $"{evt?["progress"]}%"
      toolboxModes.value.rebuildingNavMesh = true
      toolboxModes.trigger()
    },

    [EventNavMeshRebuildComplete] = function(evt, _eid, _c){
      let numErrors = evt?["numErrors"]
      if (!numErrors || numErrors <= 0)
        toolboxModes.value.rebuildNavMeshState = "OK"
      else
        toolboxModes.value.rebuildNavMeshState = "ERR"
      toolboxModes.value.rebuildingNavMesh = false
      toolboxModes.trigger()
    },

    [EventNavMeshRebuildCancelled] = function(_evt, _eid, _c){
      toolboxModes.value.rebuildNavMeshState = ""
      toolboxModes.value.rebuildingNavMesh = false
      toolboxModes.trigger()
    }
  }
)

const MODS_TO_EDIT_FOLDER = "userGameMods"
const DEF_SCENE_FILENAME = "scene.blk"

let function toolboxCmd_BuildModVROM() {
  let scenePath = get_scene_filepath?()
  let modName = scenePath?.replace($"{MODS_TO_EDIT_FOLDER}/", "").replace($"/{DEF_SCENE_FILENAME}", "")
  if (!modName) {
    console_print("buildModVROM: Failed to retrieve mod name")
    return
  }
  console_print($"Building mod VROM... {MODS_TO_EDIT_FOLDER}/{modName}.vromfs.bin")
  system?($"@start modsPacker.bat \"{modName}\"")
}

let toolboxButtonStyle    = {boxStyle  = {normal = {fillColor = Color(0,0,0,120)}}}
let toolboxButtonStyleOn  = {textStyle = {normal = {color = Color(0,0,0,255)}},
                             boxStyle  = {normal = {fillColor = Color(255,255,255)}, hover = {fillColor = Color(245,250,255)}}}
let toolboxButtonStyleOff = {textStyle = {normal = {color = Color(120,120,120,255)}, hover = {color = Color(120,120,120,255)}}, off = true,
                             boxStyle  = {normal = {fillColor = Color(0,0,0,120)}, hover = {fillColor = Color(0,0,0,120)}}}

let toolboxTooltipShow = Watched(false)
let toolboxTooltipData = {text = "", row = 0}
let toolboxTooltip = @() {
  pos = [-hdpx(240), 10 + toolboxTooltipData.row]
  hplace = ALIGN_RIGHT

  rendObj = ROBJ_BOX
  fillColor = Color(30, 30, 30, 160)
  borderColor = Color(50, 50, 50, 20)
  size = SIZE_TO_CONTENT
  borderWidth = hdpx(1)
  padding = fsh(1)
  children = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    maxWidth = hdpx(500)
    text = toolboxTooltipData.text
    color = Color(180, 180, 180, 120)
  }
}

let function toolboxButton(name, func, style, tooltip, row=0) {
  return textButton(name, func, style.__merge({
    onHover = function(on) {
      toolboxTooltipData.text = on ? tooltip : ""
      toolboxTooltipData.row = row
      toolboxTooltipShow(on)
    }
  }))
}

const TOOLTIP_PLAYTEST  = "Teleports hero to camera position and resumes gameplay"
const TOOLTIP_DEVMODE   = "Disables different gameplay cooldowns and limitations for easier testing, but to exit DevMode you will have to Restart scene"
const TOOLTIP_COLLGEOM  = "Toggles visibility of collision geometry"
const TOOLTIP_NAVMESH   = "Toggles visibility of AI Navigation Mesh, which is vital for bots AI navigation across level and requires correctly defined Battle Areas to specify where NavMesh will be loaded. You will have to Restart scene after Battle Areas redefined"
const TOOLTIP_TERRAFORM = "Toggles Terraforming mode which allows to setup terraforming brush parameters, raise/lower landscape, and delete grass and trees"
const TOOLTIP_RENDINSTS = "Toggles RendInsts mode which allows to select level scenery models and move (Unbake), delete (Remove) and copy (Instance) them"
const TOOLTIP_POLYBA    = "Toggles visibility of active polygonal Battle Areas"
const TOOLTIP_REFRESHBA = "Updates displayed polygonal Battle Areas from polygon points (battle_area_polygon_point)"
const TOOLTIP_POLYCZ    = "Toggles visibility of active polygonal Capture Zones"
const TOOLTIP_REFRESHCZ = "Updates displayed polygonal Capture Zones from polygon points (capzone_area_polygon_point)"
const TOOLTIP_CAPZONES  = "Toggles visibility of all active Capture Zones"
const TOOLTIP_RESPAWNS  = "Toggles visibility of active / all Respawns"
const TOOLTIP_GROUPS    = "Toggles list to activate and deactivate Groups for testing purposes"
const TOOLTIP_REFRESHGR = "Updates list of displayed Groups"
const TOOLTIP_COMMANDS  = "Toggles list of build commands"

const TOOLTIP_REBUILD_NAVMESH = "Generates NavMesh for modified terrain and placed RI, which then saved to patch_nav_mesh.bin file in mod directory"
const TOOLTIP_BUILD_MOD_VROM  = "Packages contents of mod directory to <mod_name>.vromfs.bin file placed to userGameMods/ folder, which then could be uploaded to mods portal"

const TOOLTIP_CREATE_RI_ENTITY    = "Creates new 'game_rendinst' entity"
const TOOLTIP_CREATE_RI_DECOR     = "Creates new 'game_rendinst_decor' entity"
const TOOLTIP_ADD_SCENERY_REMOVER = "Creates new 'scenery_remover' entity"
const TOOLTIP_RESTORE_REMOVED     = "Restores removed baked RI one by one"

const TOOLTIP_RI_UNBAKE   = "Converts selected baked RI to unbaked RI entities, and enbaked RI entities to normal RI entities (show their boxes)"
const TOOLTIP_RI_ENBAKE   = "Converts selected RI entities to enbaked RI entities (hide their boxes)"
const TOOLTIP_RI_REBAKE   = "Converts selected unbaked RI entities (shown in violet) to baked RI at their original positions"
const TOOLTIP_RI_REMOVE   = "Deletes selected baked RI or RI entities, and you can Restore removed baked RI later (doors/windows will require Restart)"
const TOOLTIP_RI_INSTANCE = "Clones RI or RI entities as new game RI entities (detects decor RI entities, but properties like ri_extra__overrideHitPoitns not copied here)"
const TOOLTIP_RI_WITHIN   = "Selects all other RI within (inside) selected RI"

//                               Unbake                                          Enbake                    Rebake                                Remove                    Instance
// baked RI/rebaked_rendinst     => riunb + unbaked_rendinst                     ---                       ---                                   ~rirmv + del_entity       => game_rendinst
// game_rendinst/decor           ---                                             add enbaked_ri            ---                                   del_entity                => game_rendinst/decor
// unbaked_rendinst              ---                                             add enbaked_ri            ~riunb + rebaked_rendinst             del_entity                => game_rendinst
// if not clonedRIDoorTag        create clone+unbaked_door_ri + riunb + delgen   ---                       ---                                   ~rirmv + del_entity       => create clone with clonedRIDoorTag
// if has unbaked_door_ri        ---                                             add enbaked_ri            ~riunb+rebaked_rendinst(need restart) del_entity                => create clone with clonedRIDoorTag
// if has enbaked_ri             remove enbaked_ri

let toolboxPopupBox = function() {
  let ROW_H = hdpx(34)
  let riLen = riToolSelected.value.len()
  let riHas = riLen > 0
  let row0 = 6*ROW_H-hdpx(7)+((riLen > 15 ? 16 : riLen)*hdpx(20))
  let row1 = isTerraforming.value ? (terraformParams.lastName != "EV" ? 8*ROW_H-hdpx(5) : 11*ROW_H+hdpx(10))
             : isRIToolMode() ? (riLen <= 0 ? 10*ROW_H-hdpx(20) : (riLen <= 15) ? 9*ROW_H+(riLen*hdpx(20)) : 9*ROW_H+hdpx(16*20))
             : 3*ROW_H
  let row2 = row1 + ROW_H
  let row3 = row2 + ROW_H
  let row4 = row3 + ROW_H

  return {
    behavior = Behaviors.Button

    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    borderRadius = hdpx(7)
    borderColor = Color(120,120,120, 160)
    fillColor = Color(40,40,40, 160)

    size = [hdpx(230), SIZE_TO_CONTENT]
    padding = hdpx(10)

    cursor = cursors.normal
    hotkeys = [["Esc", @() toolboxShown(false)]]

    watch = [showPointAction, namePointAction, toolboxModes, riToolSelected]

    flow = FLOW_VERTICAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        children = [
          toolboxButton("Playtest", @() toolboxRunCmd("editor.test_mode", "close"), toolboxButtonStyle, TOOLTIP_PLAYTEST)
          !toolboxModes.value.dev ? toolboxButton("DevMode", @() toolboxRunCmd("sandbox.enable_devmode", null, "dev", true), toolboxButtonStyle, TOOLTIP_DEVMODE)
                                  : toolboxButton("DevMode", @() toolboxRunCmd("dev_mode_restart", null), toolboxButtonStyleOn, TOOLTIP_DEVMODE)
        ]
      }
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          !toolboxModes.value.coll ? toolboxButton("CollGeom",  @() toolboxRunCmd("app.debug_collision", null, "coll", true), toolboxButtonStyle, TOOLTIP_COLLGEOM, 1*ROW_H)
                                  : toolboxButton("CollGeom",  @() toolboxRunCmd("app.debug_collision", null, "coll", false), toolboxButtonStyleOn, TOOLTIP_COLLGEOM, 1*ROW_H)
          !toolboxModes.value.nav  ? toolboxButton("NavMesh", @() toolboxRunCmd("app.debug_navmesh 1", null, "nav", true),  toolboxButtonStyle,   TOOLTIP_NAVMESH, 1*ROW_H)
                                  : toolboxButton("NavMesh", @() toolboxRunCmd("app.debug_navmesh 0", null, "nav", false), toolboxButtonStyleOn, TOOLTIP_NAVMESH, 1*ROW_H)
        ]
      }
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          toolboxButton("Terraform",  @() beginTerraforming(terraformParams.lastName, terraformParams.lastMode, true), isTerraforming.value ? toolboxButtonStyleOn : toolboxButtonStyle, TOOLTIP_TERRAFORM, 2*ROW_H)
          toolboxButton("RendInsts",  @() beginRIToolMode(true), isRIToolMode() ? toolboxButtonStyleOn : toolboxButtonStyle, TOOLTIP_RENDINSTS, 2*ROW_H)
        ]
      }
      isTerraforming.value ? @() {
        pos = [hdpx(5), 0]
        flow = FLOW_VERTICAL
        watch = [terraformParams.radius, terraformParams.depth]
        children = [
          { size = [0, hdpx(5)] }
          { vplace = ALIGN_CENTER, children = txt($"Mode: {terraformParams.lastInfo}") }
          { size = [0, hdpx(5)] }
          {
            pos = [hdpx(-7), 0]
            flow = FLOW_HORIZONTAL
            children = [
              textButton("EV",  @() beginTerraforming("EV", POINTACTION_MODE_TERRAFORMING),         isTerraformingMode(POINTACTION_MODE_TERRAFORMING)         ? toolboxButtonStyleOn : toolboxButtonStyle)
              textButton("CE",  @() beginTerraforming("CE", POINTACTION_MODE_CLEAR_ELEVATIONS),     isTerraformingMode(POINTACTION_MODE_CLEAR_ELEVATIONS)     ? toolboxButtonStyleOn : toolboxButtonStyle)
              textButton("GE",  @() beginTerraforming("GE", POINTACTION_MODE_ERASE_GRASS),          isTerraformingMode(POINTACTION_MODE_ERASE_GRASS)          ? toolboxButtonStyleOn : toolboxButtonStyle)
              textButton("XG",  @() beginTerraforming("XG", POINTACTION_MODE_DELETE_GRASS_ERASERS), isTerraformingMode(POINTACTION_MODE_DELETE_GRASS_ERASERS) ? toolboxButtonStyleOn : toolboxButtonStyle)
            ]
          }
          { size = [0, hdpx(5)] }
          { vplace = ALIGN_CENTER, children = txt($"Brush radius: {round_by_value(terraformParams.radius.value, terraformParams.radiusStep)}") }
          { size = [hdpx(200), hdpx(32)], children = slider(O_HORIZONTAL, terraformParams.radius, { min = terraformParams.radiusMin, max = terraformParams.radiusMax, step = terraformParams.radiusStep }) }

          terraformParams.lastName != "EV" ? null : { size = [0, hdpx(5)] }
          terraformParams.lastName != "EV" ? null : { vplace = ALIGN_CENTER, children = txt($"{terraformParams.depth.value <= -terraformParams.depthStep*0.9 ? "Lowering depth" : "Elevation hght"}: {round_by_value(terraformParams.depth.value, terraformParams.depthStep)}") }
          terraformParams.lastName != "EV" ? null : { size = [hdpx(200), hdpx(32)], children = slider(O_HORIZONTAL, terraformParams.depth, { min = terraformParams.depthMin, max = terraformParams.depthMax, step = terraformParams.depthStep }) }
          terraformParams.lastName != "EV" ? null : { vplace = ALIGN_CENTER, children = txt("Hold Alt to invert") }
          terraformParams.lastName != "EV" ? null : { vplace = ALIGN_CENTER, children = txt("Hold Shift for 5x finer") }
          terraformParams.lastName != "EV" ? null : { vplace = ALIGN_CENTER, children = txt("Hold Ctrl for 5x coarser") }
          { vplace = ALIGN_CENTER, children = txt("Ctrl+Z for undo") }
          { vplace = ALIGN_CENTER, children = txt("Ctrl+Y for redo") }
          { size = [0, hdpx(5)] }
        ]
      } : null
      isRIToolMode() ? @() {
        pos = [hdpx(5), 0]
        flow = FLOW_VERTICAL
        children = [
          { size = [0, hdpx(5)] }
          { pos = [hdpx(16), 0], vplace = ALIGN_CENTER, children = txt($"Click to select baked RI") }
          { pos = [hdpx(16), 0], vplace = ALIGN_CENTER, children = txt($"Hold Ctrl to multiselect") }
          { size = [0, hdpx(5)] }
          { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
            { vplace = ALIGN_CENTER, children = txt($"{riLen} selected") }
            textButton("Deselect", @() clearRIToolSelected(), riHas ? toolboxButtonStyle : toolboxButtonStyleOff)
          ]}
          { size = [0, hdpx(5)] }
          riHas ? function() {
            local childs = []
            foreach (item in riToolSelected.value) {
              if (childs.len() >= 15) {
                childs.append({ vplace = ALIGN_CENTER, children = txt($"... ({riLen-15} more)") })
                break
              }
              childs.append({ vplace = ALIGN_CENTER, children = txt($"{item.name}", item.kind == 1 ? {color=Color(255,64,255)} :
                                                                                    item.kind == 2 ? {color=Color(230,230,64)} :
                                                                                    item.kind == 3 ? {color=Color(64,230,230)} :
                                                                                    {}) })
            }
            return { flow = FLOW_VERTICAL, children = childs }
          } : null
          riHas ? { size = [0, hdpx(10)] } : { size = [0, hdpx(5)] }
          riHas ? { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
            toolboxButton("Unbake", @() unbakeRIToolSelected(), toolboxButtonStyle, TOOLTIP_RI_UNBAKE, row0)
            toolboxButton("Remove", @() removeRIToolSelected(), toolboxButtonStyle, TOOLTIP_RI_REMOVE, row0)
          ]} : null
          riHas ? { size = [0, hdpx(5)] } : null
          riHas ? { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
            toolboxButton("Enbake",   @() enbakeRIToolSelected(),   toolboxButtonStyle, TOOLTIP_RI_ENBAKE, row0 + 1*ROW_H)
            toolboxButton("Instance", @() instanceRIToolSelected(), toolboxButtonStyle, TOOLTIP_RI_INSTANCE, row0 + 1*ROW_H)
          ]} : null
          riHas ? { size = [0, hdpx(5)] } : null
          riHas ? { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
            toolboxButton("Rebake",   @() rebakeRIToolSelected(), toolboxButtonStyle, TOOLTIP_RI_REBAKE, row0 + 2*ROW_H)
            toolboxButton("Within..", @() selectRIToolInside(),   toolboxButtonStyle, TOOLTIP_RI_WITHIN, row0 + 2*ROW_H)
          ]} : null
          !riHas ? { pos = [hdpx(7), 0], flow = FLOW_VERTICAL, children = [
            textButton($"Create new RendInst", @() spawnNewRIEntity("game_rendinst"),       toolboxButtonStyle.__merge({ onHover = @(on) cursors.setTooltip(on ? TOOLTIP_CREATE_RI_ENTITY    : null) }))
            textButton($"Create new RI decor", @() spawnNewRIEntity("game_rendinst_decor"), toolboxButtonStyle.__merge({ onHover = @(on) cursors.setTooltip(on ? TOOLTIP_CREATE_RI_DECOR     : null) }))
            textButton($"Add scenery remover", @() spawnNewRIEntity("scenery_remover"),     toolboxButtonStyle.__merge({ onHover = @(on) cursors.setTooltip(on ? TOOLTIP_ADD_SCENERY_REMOVER : null) }))
          ]} : null
          !riHas ? { size = [0, hdpx(5)] } : null
          !riHas ? { pos = [hdpx(4), 0], flow = FLOW_HORIZONTAL, children = [
            textButton($"Restore removed ({getRIToolRemovedCount()})", @() restoreRemovedByRITool(),
                      ((getRIToolRemovedCount() > 0) ? toolboxButtonStyle : toolboxButtonStyleOff).__merge({ onHover = @(on) cursors.setTooltip(on ? TOOLTIP_RESTORE_REMOVED : null) }))
          ]} : null
          { size = [0, hdpx(5)] }
        ]
      } : null
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          !toolboxModes.value.polyAreas ? toolboxButton("PolyBattleAreas", @() toolboxRunCmd("battleAreas.draw_active_poly_areas 1", null, "polyAreas", true),  toolboxButtonStyle,   TOOLTIP_POLYBA, row1)
                                        : toolboxButton("PolyBattleAreas", @() toolboxRunCmd("battleAreas.draw_active_poly_areas 0", null, "polyAreas", false), toolboxButtonStyleOn, TOOLTIP_POLYBA, row1)
          toolboxButton(fa["refresh"], @() toolboxRunCmd("battleAreas.reinit_active_poly_areas"), {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}}}, TOOLTIP_REFRESHBA, row1)
        ]
      }
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          !toolboxModes.value.capZonesPoly ? toolboxButton("CapZonesPoly", @() toolboxRunCmd("capzone.draw_active_poly_areas 1", null, "capZonesPoly", true),  toolboxButtonStyle,   TOOLTIP_POLYCZ, row2)
                                          : toolboxButton("CapZonesPoly", @() toolboxRunCmd("capzone.draw_active_poly_areas 0", null, "capZonesPoly", false), toolboxButtonStyleOn, TOOLTIP_POLYCZ, row2)
          toolboxButton(fa["refresh"], @() toolboxRunCmd("capzone.reinit_active_poly_areas"), {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}}}, TOOLTIP_REFRESHCZ, row2)
        ]
      }
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          !toolboxModes.value.capZones ? toolboxButton("CapZones", @() toolboxRunCmd("capzone.debug", null, "capZones", true),  toolboxButtonStyle,   TOOLTIP_CAPZONES, row3)
                                      : toolboxButton("CapZones", @() toolboxRunCmd("capzone.debug", null, "capZones", false), toolboxButtonStyleOn, TOOLTIP_CAPZONES, row3)
          //textButton("CapZones SHOW radius",  @() toolboxRunCmd("capzone.show_min_radius"), toolboxButtonStyle)

          toolboxModes.value.respawns == 1 ? toolboxButton("Respawns +", @() toolboxRunCmd("respbase.respbase_debug 1", "respbase.respbase_only_active_debug 0", "respawns", 2), toolboxButtonStyleOn,  TOOLTIP_RESPAWNS, row3) :
          toolboxModes.value.respawns == 2 ? toolboxButton("Respawns...", @() toolboxRunCmd("respbase.respbase_debug 0", "respbase.respbase_only_active_debug 0", "respawns", 0), toolboxButtonStyleOn, TOOLTIP_RESPAWNS, row3) :
                                            toolboxButton("Respawns", @() toolboxRunCmd("respbase.respbase_debug 0", "respbase.respbase_only_active_debug 1", "respawns", 1), toolboxButtonStyle, TOOLTIP_RESPAWNS, row3)
        ]
      }
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          toolboxButton("Groups Override", @() toggleGroups(), toolboxModes.value.showGroups ? toolboxButtonStyleOn : toolboxButtonStyle, TOOLTIP_GROUPS, row4)
          toolboxButton(fa["refresh"], @() updateGroupsList(), {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}}}, TOOLTIP_REFRESHGR, row4)
        ]
      }
      !toolboxModes.value.showGroups ? null : { size = [0, hdpx(5)] }
      !toolboxModes.value.showGroups ? null : function() {
        local childs = []
        foreach (item in groupsList.value) {
          let itemParam = clone item
          childs.append({
            children = textButton(
              mkGroupListItemName(itemParam),
              function() {
                toggleGroupListItem(itemParam)

                if (toolboxModes.value.polyAreas) {
                  toolboxRunCmd("battleAreas.draw_active_poly_areas 0")
                  gui_scene.resetTimeout(0.01, @() toolboxRunCmd("battleAreas.draw_active_poly_areas 1"))
                }
              },
              ((itemParam.active > 0) ? toolboxButtonStyleOn : toolboxButtonStyle).__merge({
                onHover = @(on) cursors.setTooltip(on ? mkGroupListItemTooltip(itemParam) : null)
              })
            )
          })
        }
        return {
          flow = FLOW_VERTICAL
          pos = [hdpx(16), 0]
          gap = hdpx(5)
          watch = [groupsList]
          children = childs
        }
      }
      { size = [0, hdpx(5)] }
      {
        flow = FLOW_HORIZONTAL
        children = [
          textButton("Build commands", @() toggleCommands(), toolboxModes.value.showCommands ? toolboxButtonStyleOn : toolboxButtonStyle)
        ]
      }
      !toolboxModes.value.showCommands ? null : { size = [0, hdpx(5)] }
      !toolboxModes.value.showCommands ? null : @() {
        flow = FLOW_VERTICAL
        children = [
          { pos = [hdpx(27), 0], flow = FLOW_HORIZONTAL, children = [
            textButton(toolboxModes.value.rebuildingNavMesh ? $"Rebuilding... {toolboxModes.value.rebuildNavMeshState}" : $"Rebuild NavMesh {toolboxModes.value.rebuildNavMeshState}",
              @() toolboxCmd_RebuildNavMesh(), toolboxButtonStyle.__merge({ onHover = @(on) cursors.setTooltip(on ? TOOLTIP_REBUILD_NAVMESH : null) }))
          ]}
          { size = [0, hdpx(5)] }
          { pos = [hdpx(27), 0], flow = FLOW_HORIZONTAL, children = [
            textButton("Build Mod VROM", @() toolboxCmd_BuildModVROM(), toolboxButtonStyle.__merge({
              onHover = @(on) cursors.setTooltip(on ? TOOLTIP_BUILD_MOD_VROM : null)
            }))
          ]}
        ]
      }
    ]
  }
}

let toolboxPopup = @() {
  pos = [hdpx(-150), hdpx(42)]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  size = [hdpx(230), SIZE_TO_CONTENT]

  cursor = cursors.normal
  watch = [toolboxTooltipShow]

  children = [
    toolboxPopupBox
    toolboxTooltipShow.value ? toolboxTooltip : null
  ]
}

propPanelVisible.subscribe(function(v) {
  if (v && getEditMode() != DE4_MODE_POINT_ACTION)
    toolboxShown(false)
})

riToolSelected.subscribe(function(v) {
  if (v.len() > 0 && !toolboxShown.value) {
    toolboxShown(true)
    propPanelVisible(false)
  }
})

return {
  setToolboxShowMsgbox
  toolboxShown
  toolboxPopup
}
