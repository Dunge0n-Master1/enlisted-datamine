from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let {showPointAction, namePointAction, setPointActionMode, resetPointActionMode} = require("%daeditor/state.nut")
let {CmdRIToolAddSelected, CmdRIToolClearSelected, CmdRIToolRemoveRendInst, CmdRIToolUnbakeRendInst,
     CmdRIToolRebakeRendInst, CmdRIToolCreateRendInst, CmdRIToolRestoreRendInst} = require("dasevents")
let entity_editor = require_optional("entity_editor")

const POINTACTION_MODE_RI_TOOL = "RendInsts mode"

let function isRIToolMode() {
  return showPointAction.value && namePointAction.value == POINTACTION_MODE_RI_TOOL
}

let riToolSelected = Watched([])

let function saveRIToolData() {
  let save_eid = entity_editor?.get_instance().makeSingletonEntity("rendinsts_removes")
  if (save_eid && save_eid != INVALID_ENTITY_ID) {
    entity_editor?.save_component(save_eid, "rirmv")
    entity_editor?.save_component(save_eid, "riunb")
  }
}

let function isSameVector(a,b) {
  return a.x == b.x && a.y == b.y && a.z == b.z
}
let function isSameMatrix(a,b) {
  return isSameVector(a[0],b[0]) && isSameVector(a[1],b[1]) && isSameVector(a[2],b[2]) && isSameVector(a[3],b[3])
}


let function clearRIToolSelected() {
  riToolSelected.value.clear();
  riToolSelected.trigger()
  ecs.g_entity_mgr.broadcastEvent(CmdRIToolClearSelected())
}

let function removeRIToolSelected() {
  foreach(ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolRemoveRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  gui_scene.resetTimeout(0.1, @() riToolSelected.trigger())
  clearRIToolSelected()
}

let function unbakeRIToolSelected() {
  foreach(ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolUnbakeRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
}

let function rebakeRIToolSelected() {
  foreach(ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolRebakeRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
}

let function instanceRIToolSelected() {
  foreach(ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolCreateRendInst({tpl = "game_rendinst", tm = ri.mat, name = ri.name}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
}

let function restoreRemovedByRITool() {
  ecs.g_entity_mgr.broadcastEvent(CmdRIToolRestoreRendInst())
  gui_scene.resetTimeout(0.5, saveRIToolData)
  gui_scene.resetTimeout(0.1, @() riToolSelected.trigger())
  clearRIToolSelected()
}


let function onRIToolAction(action) {
  if (action.op == "action" && action.pos != null) {
    if (isRIToolMode()) {
      let multiselect = (action.mod == 2)
      if (action.ext_id == "" && !multiselect) {
        riToolSelected.value.clear()
        riToolSelected.trigger()
        ecs.g_entity_mgr.broadcastEvent(CmdRIToolClearSelected())
      }
      else if (action.ext_id != "") {
        local found_idx = -1
        if (multiselect) {
          foreach(idx, ri in riToolSelected.value) {
            if (ri.name == action.ext_name && isSameMatrix(ri.mat, action.ext_mtx)) {
              found_idx = idx
              break
            }
          }
        }
        if (found_idx < 0 || multiselect) {
          local addable = true
          local unbaked = false
          if (action.ext_eid != INVALID_ENTITY_ID) {
            let tag1 = ecs.obsolete_dbg_get_comp_val(action.ext_eid, "unbakedRendInstTag")
            let tag2 = ecs.obsolete_dbg_get_comp_val(action.ext_eid, "rebakedRendInstTag")
            if (tag1 == null && tag2 == null)
              addable = false
            if (tag1 != null)
              unbaked = true
          }
          if (addable) {
            if (found_idx < 0) {
              let kind = !multiselect ? "select" : "multiselect"
              if (kind == "select")
                riToolSelected.value.clear()
              riToolSelected.value.append({
                name    = action.ext_name
                mat     = action.ext_mtx
                eid     = action.ext_eid
                unbaked = unbaked
              })
              riToolSelected.trigger()
              ecs.g_entity_mgr.broadcastEvent(CmdRIToolAddSelected({tm = action.ext_mtx, name = action.ext_name, bsph = action.ext_sph, kind = kind, unbaked = unbaked}))
            }
            else {
              riToolSelected.value.remove(found_idx)
              riToolSelected.trigger()
              ecs.g_entity_mgr.broadcastEvent(CmdRIToolAddSelected({tm = action.ext_mtx, name = action.ext_name, bsph = action.ext_sph, kind = "deselect", unbaked = false}))
            }
          }
        }
      }
    }
  }
  if (action.op == "context") {
    resetPointActionMode()
  }
  if (action.op == "undo") {
    restoreRemovedByRITool()
  }
  if (action.op == "redo") {
  }
  if (action.op == "delete") {
    removeRIToolSelected()
  }
  if (action.op == "finish") {
    clearRIToolSelected()
  }
}

let function beginRIToolMode(toggle=false) {
  if (!showPointAction.value || (!toggle && namePointAction.value != POINTACTION_MODE_RI_TOOL)) {
    saveRIToolData()
    setPointActionMode("pick_action", POINTACTION_MODE_RI_TOOL, onRIToolAction)
  }
  else
    resetPointActionMode()
}

let countRIRemoved = ecs.SqQuery("countRIRemoved", {comps_ro = [["rirmv", ecs.TYPE_ARRAY]]})

let function getRIToolRemovedCount() {
  local count = 0
  countRIRemoved(function(_eid, comp) {
    count = comp.rirmv?.len() ?? 0
  })
  return count
}

return {
  isRIToolMode
  beginRIToolMode
  clearRIToolSelected
  riToolSelected
  getRIToolRemovedCount
  removeRIToolSelected
  unbakeRIToolSelected
  rebakeRIToolSelected
  instanceRIToolSelected
  restoreRemovedByRITool
}
