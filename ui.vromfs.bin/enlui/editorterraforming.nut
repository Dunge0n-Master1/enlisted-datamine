from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let {showPointAction, namePointAction, setPointActionMode, updatePointActionPreview, resetPointActionMode, editorUnpause} = require("%daeditor/state.nut")
let {CmdTerraBrush, CmdTerraBrushUndo, CmdTerraBrushRedo} = require("dasevents")
let entity_editor = require_optional("entity_editor")

const POINTACTION_MODE_TERRAFORMING         = "Terraforming mode"
const POINTACTION_MODE_CLEAR_ELEVATIONS     = "UnTerraforming mode"
const POINTACTION_MODE_ERASE_GRASS          = "Erase Grass mode"
const POINTACTION_MODE_DELETE_GRASS_ERASERS = "UnErase Grass mode"

let function isTerraformingMode(mode) {
  return showPointAction.value && namePointAction.value == mode
}

let isTerraforming = Computed(@() showPointAction.value && (namePointAction.value == POINTACTION_MODE_TERRAFORMING
                                                         || namePointAction.value == POINTACTION_MODE_CLEAR_ELEVATIONS
                                                         || namePointAction.value == POINTACTION_MODE_ERASE_GRASS
                                                         || namePointAction.value == POINTACTION_MODE_DELETE_GRASS_ERASERS))

let function getTerraformingModeInfo(mode) {
  if (mode == "EV") return "Elevate/lower"
  if (mode == "CE") return "Clear elevations"
  if (mode == "GE") return "Add grass erasers"
  if (mode == "XG") return "Delete grass erasers"
  return "Unknown"
}

let terraformParams = {
  radius     =  Watched(5.0)
  radiusMin  =  0.0
  radiusMax  =  100.0
  radiusStep =  1.0

  depth      =  Watched(1.0)
  depthMin   = -10.0
  depthMax   =  10.0
  depthStep  =  0.01

  eraseGrass =  Watched(false)
  clearMode  =  Watched(false)

  lastName   = "EV"
  lastMode   = POINTACTION_MODE_TERRAFORMING
  lastInfo   = getTerraformingModeInfo("EV")
  preview    = ""
}

let function saveTerraforming() {
  let terraforming_eid = entity_editor?.get_instance().makeSingletonEntity("terraforming")
  if (terraforming_eid && terraforming_eid != ecs.INVALID_ENTITY_ID) {
    entity_editor?.save_component(terraforming_eid, "elevs")
    entity_editor?.save_component(terraforming_eid, "egras")
  }
}

let function onTerraformingAction(action) {
  if (action.op == "action" && action.pos != null) {
    if (isTerraformingMode(POINTACTION_MODE_TERRAFORMING)) {
      local rad = terraformParams.radius.value
      local alt = terraformParams.depth.value
      if (action.mod & 1) // Shift
        alt *= 0.2
      if (action.mod & 2) // Ctrl
        alt *= 5.0
      if (action.mod & 4) // Alt
        alt = -alt
      ecs.g_entity_mgr.broadcastEvent(CmdTerraBrush({pos=action.pos, radius=rad, alt=alt, clearMode=false, eraseGrass=false }))
      gui_scene.resetTimeout(0.5, saveTerraforming)
    }
    if (isTerraformingMode(POINTACTION_MODE_CLEAR_ELEVATIONS)) {
      local rad = terraformParams.radius.value
      ecs.g_entity_mgr.broadcastEvent(CmdTerraBrush({pos=action.pos, radius=rad, alt=0.0, clearMode=true, eraseGrass=false }))
      gui_scene.resetTimeout(0.5, saveTerraforming)
    }
    if (isTerraformingMode(POINTACTION_MODE_ERASE_GRASS)) {
      local rad = terraformParams.radius.value
      ecs.g_entity_mgr.broadcastEvent(CmdTerraBrush({pos=action.pos, radius=rad, alt=0.0, clearMode=false, eraseGrass=true }))
      gui_scene.resetTimeout(0.5, saveTerraforming)
      editorUnpause(1.5)
    }
    if (isTerraformingMode(POINTACTION_MODE_DELETE_GRASS_ERASERS)) {
      local rad = terraformParams.radius.value
      ecs.g_entity_mgr.broadcastEvent(CmdTerraBrush({pos=action.pos, radius=rad, alt=0.0, clearMode=true, eraseGrass=true }))
      gui_scene.resetTimeout(0.5, saveTerraforming)
    }
  }
  if (action.op == "context") {
    resetPointActionMode()
  }
  if (action.op == "undo") {
    ecs.g_entity_mgr.broadcastEvent(CmdTerraBrushUndo())
  }
  if (action.op == "redo") {
    ecs.g_entity_mgr.broadcastEvent(CmdTerraBrushRedo())
  }
  if (action.op == "delete") {
    if (isTerraformingMode(POINTACTION_MODE_TERRAFORMING)) {
      local rad = terraformParams.radius.value
      ecs.g_entity_mgr.broadcastEvent(CmdTerraBrush({pos=action.pos, radius=rad, alt=0.0, clearMode=true, eraseGrass=false }))
      gui_scene.resetTimeout(0.5, saveTerraforming)
    }
    if (isTerraformingMode(POINTACTION_MODE_ERASE_GRASS)) {
      local rad = terraformParams.radius.value
      ecs.g_entity_mgr.broadcastEvent(CmdTerraBrush({pos=action.pos, radius=rad, alt=0.0, clearMode=true, eraseGrass=true }))
      gui_scene.resetTimeout(0.5, saveTerraforming)
    }
  }
}

let function beginTerraforming(modeName, pointActionMode, toggle=false) {
  if (!showPointAction.value || (!toggle && namePointAction.value != pointActionMode)) {
    saveTerraforming()
    setPointActionMode("point_action", pointActionMode, onTerraformingAction)
    terraformParams.lastName = modeName
    terraformParams.lastMode = pointActionMode
    terraformParams.lastInfo = getTerraformingModeInfo(modeName)

    local preview = "HMAP_CIRCLE_WHITE"
    if (pointActionMode == POINTACTION_MODE_TERRAFORMING && terraformParams.depth.value < -terraformParams.depthStep * 0.9)
      preview = "HMAP_DOUBLE_CIRCLE_WHITE"
    if (pointActionMode == POINTACTION_MODE_CLEAR_ELEVATIONS)
      preview = "HMAP_DASHED_CIRCLE_WHITE"
    if (pointActionMode == POINTACTION_MODE_ERASE_GRASS)
      preview = "HMAP_CIRCLE_GREEN"
    if (pointActionMode == POINTACTION_MODE_DELETE_GRASS_ERASERS)
      preview = "HMAP_DASHED_CIRCLE_GREEN"

    updatePointActionPreview(preview, terraformParams.radius.value)
    terraformParams.preview  = preview
  }
  else
    resetPointActionMode()
}

terraformParams.radius.subscribe(function(v) {
  if (isTerraforming.value)
    updatePointActionPreview(terraformParams.preview, v)
})

terraformParams.depth.subscribe(function(v) {
  if (isTerraforming.value && terraformParams.lastMode == POINTACTION_MODE_TERRAFORMING) {
    if (v < -terraformParams.depthStep * 0.9)
      terraformParams.preview = "HMAP_DOUBLE_CIRCLE_WHITE"
    else
      terraformParams.preview = "HMAP_CIRCLE_WHITE"
    updatePointActionPreview(terraformParams.preview, terraformParams.radius.value)
  }
})

return {
  POINTACTION_MODE_TERRAFORMING
  POINTACTION_MODE_CLEAR_ELEVATIONS
  POINTACTION_MODE_ERASE_GRASS
  POINTACTION_MODE_DELETE_GRASS_ERASERS
  isTerraformingMode
  isTerraforming
  terraformParams
  beginTerraforming
}
