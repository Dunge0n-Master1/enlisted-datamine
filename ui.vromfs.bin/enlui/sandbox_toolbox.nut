from "%enlSqGlob/ui_library.nut" import *
from "%darg/laconic.nut" import *

let fa = require("%darg/components/fontawesome.map.nut")
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
     removeRIToolSelected, unbakeRIToolSelected, rebakeRIToolSelected, instanceRIToolSelected,
     restoreRemovedByRITool} = require("%ui/editorToolRendInsts.nut")

let {groupsList, updateGroupsList, mkGroupListItemName, mkGroupListItemTooltip,
     toggleGroupListItem} = require("%ui/editorGroupsControl.nut")


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

let toolboxButtonStyle    = {boxStyle  = {normal = {fillColor = Color(0,0,0,120)}}}
let toolboxButtonStyleOn  = {textStyle = {normal = {color = Color(0,0,0,255)}},
                             boxStyle  = {normal = {fillColor = Color(255,255,255)}, hover = {fillColor = Color(245,250,255)}}}
let toolboxButtonStyleOff = {textStyle = {normal = {color = Color(120,120,120,255)}, hover = {color = Color(120,120,120,255)}}, off = true,
                             boxStyle  = {normal = {fillColor = Color(0,0,0,120)}, hover = {fillColor = Color(0,0,0,120)}}}

let toolboxPopup = @() {
  behavior = Behaviors.Button

  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  borderRadius = hdpx(7)
  borderColor = Color(120,120,120, 160)
  fillColor = Color(40,40,40, 160)

  pos = [hdpx(-150), hdpx(42)]
  size = [hdpx(230), SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  padding = hdpx(10)

  cursor = cursors.normal
  hotkeys = [["Esc", @() toolboxShown(false)]]

  watch = [showPointAction, namePointAction, toolboxModes]

  flow = FLOW_VERTICAL
  children = [
    {
      flow = FLOW_HORIZONTAL
      children = [
        textButton("Playtest", @() toolboxRunCmd("editor.test_mode", "close"), toolboxButtonStyle)
        !toolboxModes.value.dev ? textButton("DevMode", @() toolboxRunCmd("sandbox.enable_devmode", null, "dev", true), toolboxButtonStyle)
                                : textButton("DevMode", @() toolboxRunCmd("dev_mode_restart", null), toolboxButtonStyleOn)
      ]
    }
    { size = [0, hdpx(5)] }
    {
      flow = FLOW_HORIZONTAL
      children = [
        !toolboxModes.value.coll ? textButton("CollGeom",  @() toolboxRunCmd("app.debug_collision", null, "coll", true), toolboxButtonStyle)
                                 : textButton("CollGeom",  @() toolboxRunCmd("app.debug_collision_disable", null, "coll", false), toolboxButtonStyleOn)
        !toolboxModes.value.nav  ? textButton("NavMesh", @() toolboxRunCmd("app.debug_navmesh 1", null, "nav", true),  toolboxButtonStyle)
                                 : textButton("NavMesh", @() toolboxRunCmd("app.debug_navmesh 0", null, "nav", false), toolboxButtonStyleOn)
      ]
    }
    { size = [0, hdpx(5)] }
    {
      flow = FLOW_HORIZONTAL
      children = [
        textButton("Terraform",  @() beginTerraforming(terraformParams.lastName, terraformParams.lastMode, true), isTerraforming.value ? toolboxButtonStyleOn : toolboxButtonStyle)
        textButton("RendInsts",    @() beginRIToolMode(true), isRIToolMode() ? toolboxButtonStyleOn : toolboxButtonStyle)
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
      watch = [riToolSelected]
      children = [
        { size = [0, hdpx(5)] }
        { pos = [hdpx(16), 0], vplace = ALIGN_CENTER, children = txt($"Click to select baked RI") }
        { pos = [hdpx(16), 0], vplace = ALIGN_CENTER, children = txt($"Hold Ctrl to multiselect") }
        { size = [0, hdpx(5)] }
        { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
          { vplace = ALIGN_CENTER, children = txt($"{riToolSelected.value.len()} selected") }
          textButton("Deselect", @() clearRIToolSelected(), riToolSelected.value.len() > 0 ? toolboxButtonStyle : toolboxButtonStyleOff)
        ]}
        { size = [0, hdpx(5)] }
        riToolSelected.value.len() > 0 ? function() {
          local childs = []
          foreach(item in riToolSelected.value)
            childs.append({ vplace = ALIGN_CENTER, children = txt($"{item.name}", item.unbaked ? {color=Color(255,64,255)} : {}) })
          return { flow = FLOW_VERTICAL, children = childs }
        } : null
        riToolSelected.value.len() > 0 ? { size = [0, hdpx(10)] } : { size = [0, hdpx(5)] }
        riToolSelected.value.len() > 0 ? { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
          textButton("Unbake", @() unbakeRIToolSelected(), toolboxButtonStyle)
          textButton("Remove", @() removeRIToolSelected(), toolboxButtonStyle)
        ]} : null
        riToolSelected.value.len() > 0 ? { size = [0, hdpx(5)] } : null
        riToolSelected.value.len() > 0 ? { pos = [hdpx(16), 0], flow = FLOW_HORIZONTAL, children = [
          textButton("Rebake",    @() rebakeRIToolSelected(), toolboxButtonStyle)
          textButton("Instance",  @() instanceRIToolSelected(), toolboxButtonStyle)
        ]} : { pos = [hdpx(4), 0], flow = FLOW_HORIZONTAL, children = [
          textButton($"Restore removed ({getRIToolRemovedCount()})", @() restoreRemovedByRITool(), (getRIToolRemovedCount() > 0) ? toolboxButtonStyle : toolboxButtonStyleOff)
        ]}
        { size = [0, hdpx(5)] }
      ]
    } : null
    { size = [0, hdpx(5)] }
    {
      flow = FLOW_HORIZONTAL
      children = [
        !toolboxModes.value.polyAreas ? textButton("PolyBattleAreas", @() toolboxRunCmd("battleAreas.draw_active_poly_areas 1", null, "polyAreas", true),  toolboxButtonStyle)
                                      : textButton("PolyBattleAreas", @() toolboxRunCmd("battleAreas.draw_active_poly_areas 0", null, "polyAreas", false), toolboxButtonStyleOn)
        textButton(fa["refresh"], @() toolboxRunCmd("battleAreas.reinit_active_poly_areas"), {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}}})
      ]
    }
    { size = [0, hdpx(5)] }
    {
      flow = FLOW_HORIZONTAL
      children = [
        !toolboxModes.value.capZonesPoly ? textButton("CapZonesPoly", @() toolboxRunCmd("capzone.draw_active_poly_areas 1", null, "capZonesPoly", true),  toolboxButtonStyle)
                                         : textButton("CapZonesPoly", @() toolboxRunCmd("capzone.draw_active_poly_areas 0", null, "capZonesPoly", false), toolboxButtonStyleOn)
        textButton(fa["refresh"], @() toolboxRunCmd("capzone.reinit_active_poly_areas"), {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}}})
      ]
    }
    { size = [0, hdpx(5)] }
    {
      flow = FLOW_HORIZONTAL
      children = [
        !toolboxModes.value.capZones ? textButton("CapZones", @() toolboxRunCmd("capzone.debug", null, "capZones", true),  toolboxButtonStyle)
                                     : textButton("CapZones", @() toolboxRunCmd("capzone.debug", null, "capZones", false), toolboxButtonStyleOn)
        //textButton("CapZones SHOW radius",  @() toolboxRunCmd("capzone.show_min_radius"), toolboxButtonStyle)

        toolboxModes.value.respawns == 1 ? textButton("Respawns +", @() toolboxRunCmd("respbase.respbase_debug 1", "respbase.respbase_only_active_debug 0", "respawns", 2), toolboxButtonStyleOn) :
        toolboxModes.value.respawns == 2 ? textButton("Respawns...", @() toolboxRunCmd("respbase.respbase_debug 0", "respbase.respbase_only_active_debug 0", "respawns", 0), toolboxButtonStyleOn) :
                                           textButton("Respawns", @() toolboxRunCmd("respbase.respbase_debug 0", "respbase.respbase_only_active_debug 1", "respawns", 1), toolboxButtonStyle)
      ]
    }
    { size = [0, hdpx(5)] }
    {
      flow = FLOW_HORIZONTAL
      children = [
        textButton("Groups Override", @() toggleGroups(), toolboxModes.value.showGroups ? toolboxButtonStyleOn : toolboxButtonStyle)
        textButton(fa["refresh"], @() updateGroupsList(), {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}}})
      ]
    }
    !toolboxModes.value.showGroups ? null : { size = [0, hdpx(5)] }
    !toolboxModes.value.showGroups ? null : function() {
      local childs = []
      foreach(item in groupsList.value) {
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
  ]
}

propPanelVisible.subscribe(function(v) {
  if (v)
    toolboxShown(false)
})

return {
  setToolboxShowMsgbox
  toolboxShown
  toolboxPopup
}
