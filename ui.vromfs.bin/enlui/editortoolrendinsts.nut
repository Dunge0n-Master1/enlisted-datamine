from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let {showPointAction, namePointAction, setPointActionMode, resetPointActionMode,
     addEntityCreatedCallback, addEntityRemovedCallback, addEntityMovedCallback,
     editorUnpause, selectedEntities, wantOpenRISelect} = require("%daeditor/state.nut")

let {CmdRIToolAddSelected, CmdRIToolClearSelected, CmdRIToolRemoveRendInst,
     CmdRIToolUnbakeRendInst, CmdRIToolEnbakeRendInst, CmdRIToolRebakeRendInst,
     CmdRIToolCreateRendInst, CmdRIToolRestoreRendInst,
     EventEditorEntityMoved} = require("dasevents")

let {Point3, TMatrix} = require("dagor.math")

let entity_editor = require_optional("entity_editor")
let {setEditMode=null, DE4_MODE_SELECT=null} = require_optional("daEditor4")

const POINTACTION_MODE_RI_TOOL = "RendInsts mode"

let function isRIToolMode() {
  return showPointAction.value && namePointAction.value == POINTACTION_MODE_RI_TOOL
}

let riToolSelected = Watched([])

let function saveRIToolData() {
  let save_eid = entity_editor?.get_instance().makeSingletonEntity("rendinsts_removes")
  if (save_eid && save_eid != ecs.INVALID_ENTITY_ID) {
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
  foreach (ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolRemoveRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  gui_scene.resetTimeout(0.1, @() riToolSelected.trigger())
  clearRIToolSelected()
}

let function unbakeRIToolSelected() {
  entity_editor?.get_instance()?.selectEntities([])
  foreach (ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolUnbakeRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
  if (setEditMode)
    setEditMode(DE4_MODE_SELECT)
}

let function enbakeRIToolSelected() {
  foreach (ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolEnbakeRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
}

let function rebakeRIToolSelected() {
  foreach (ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolRebakeRendInst({tm = ri.mat, name = ri.name, eid = ri.eid}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
}

let function instanceRIToolSelected() {
  entity_editor?.get_instance()?.selectEntities([])
  foreach (ri in riToolSelected.value)
    ecs.g_entity_mgr.broadcastEvent(CmdRIToolCreateRendInst({tpl = "game_rendinst", tm = ri.mat, name = ri.name, eid = ri.eid, undo = true}))
  gui_scene.resetTimeout(0.5, saveRIToolData)
  clearRIToolSelected()
  if (setEditMode)
    setEditMode(DE4_MODE_SELECT)
}

let function spawnNewRIEntity(tplName) {
  local tm = entity_editor?.make_cam_spawn_tm()
  if (tm == null)
    return
  if (tm[0].x == 0.0 && tm[0].y == 0.0 && tm[0].z == 0.0)
    return
  if (tplName == "scenery_remover") {
    tm[0] *= 5.0
    tm[1] *= 5.0
    tm[2] *= 5.0
    local pos = tm[3]
    pos["y"] += 0.5
    tm[3] = pos
  }
  wantOpenRISelect(true)
  ecs.g_entity_mgr.broadcastEvent(CmdRIToolCreateRendInst({tpl = tplName, tm = tm, name = "sandbags_wall_medium_rounded_a", eid = ecs.INVALID_ENTITY_ID, undo = true}))
  clearRIToolSelected()
  if (setEditMode)
    setEditMode(DE4_MODE_SELECT)
}

let function restoreRemovedByRITool() {
  ecs.g_entity_mgr.broadcastEvent(CmdRIToolRestoreRendInst())
  gui_scene.resetTimeout(0.5, saveRIToolData)
  gui_scene.resetTimeout(0.1, @() riToolSelected.trigger())
  clearRIToolSelected()
}

let function isRISelectable(eid) {
  if (eid == ecs.INVALID_ENTITY_ID)
    return true
  if (ecs.obsolete_dbg_get_comp_val(eid, "gameRendInstTag") != null)
    return true
  if (ecs.obsolete_dbg_get_comp_val(eid, "unbakedRendInstTag") != null)
    return true
  if (ecs.obsolete_dbg_get_comp_val(eid, "rebakedRendInstTag") != null)
    return true
  if (ecs.obsolete_dbg_get_comp_val(eid, "isDoor") != null)
    return true
  return false
}

let function getRIKind(eid) {
  if (eid == ecs.INVALID_ENTITY_ID)
    return 0
  if (ecs.obsolete_dbg_get_comp_val(eid, "rebakedRendInstTag") != null)
    return 0
  if (ecs.obsolete_dbg_get_comp_val(eid, "unbakedRendInstTag") != null)
    return 1
  if (ecs.obsolete_dbg_get_comp_val(eid, "isDoor") != null)
    return 3
  return 2
}

let function addRIToSelected(ri_add) {
  foreach (riLst in riToolSelected.value)
    if (ri_add.name == riLst.name && isSameMatrix(ri_add.mtx, riLst.mat))
      return
  if (!isRISelectable(ri_add.eid))
    return
  let kind = getRIKind(ri_add.eid)
  riToolSelected.value.append({
    name = ri_add.name
    mat  = ri_add.mtx
    eid  = ri_add.eid
    sph  = ri_add.sph
    kind = kind
  })
  riToolSelected.trigger()
  ecs.g_entity_mgr.broadcastEvent(CmdRIToolAddSelected({tm = ri_add.mtx, name = ri_add.name, bsph = ri_add.sph, action = "multiselect", kind = kind}))
}

let function selectRIToolInside() {
  let riTestList = clone riToolSelected.value
  foreach (riTest in riTestList) {
    let riAddList = entity_editor?.gather_ri_by_sphere(riTest.sph.x, riTest.sph.y, riTest.sph.z, riTest.sph.w)
    if (riAddList == null)
      continue
    foreach (riAdd in riAddList)
      addRIToSelected(riAdd)
  }
}

let function selectRIFromEntity(eid) {
  let riAdd = entity_editor?.get_ri_from_entity(eid)
  if (riAdd == null)
    return
  addRIToSelected(riAdd)
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
          foreach (idx, ri in riToolSelected.value) {
            if (ri.name == action.ext_name && isSameMatrix(ri.mat, action.ext_mtx)) {
              found_idx = idx
              break
            }
          }
        }
        if (found_idx < 0 || multiselect) {
          let addable = isRISelectable(action.ext_eid)
          let kind = getRIKind(action.ext_eid)
          if (addable) {
            if (found_idx < 0) {
              let act = !multiselect ? "select" : "multiselect"
              if (act == "select")
                riToolSelected.value.clear()
              riToolSelected.value.append({
                name = action.ext_name
                mat  = action.ext_mtx
                eid  = action.ext_eid
                sph  = action.ext_sph
                kind = kind
              })
              riToolSelected.trigger()
              ecs.g_entity_mgr.broadcastEvent(CmdRIToolAddSelected({tm = action.ext_mtx, name = action.ext_name, bsph = action.ext_sph, action = act, kind = kind}))
            }
            else {
              riToolSelected.value.remove(found_idx)
              riToolSelected.trigger()
              ecs.g_entity_mgr.broadcastEvent(CmdRIToolAddSelected({tm = action.ext_mtx, name = action.ext_name, bsph = action.ext_sph, action = "deselect", kind = 0}))
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

    foreach (eid,_v in selectedEntities.value)
      selectRIFromEntity(eid.tointeger())
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

let function onRemoveRIEntity(eid) {
  let ri_extra = ecs.obsolete_dbg_get_comp_val(eid, "ri_extra", null)
  let isDestr = ecs.obsolete_dbg_get_comp_val(eid, "isRendinstDestr", false)
  if (ri_extra != null && isDestr) {
    editorUnpause(2.5)
  }
}
addEntityRemovedCallback(onRemoveRIEntity)

let function onCreatedRIRemoverEntity(eid) {
  let check = ecs.obsolete_dbg_get_comp_val(eid, "scenery_remove__apply", null)
  let tm = ecs.obsolete_dbg_get_comp_val(eid, "transform", null)
  if (check != null && tm != null) {
    let resTm = TMatrix(tm)
    resTm.setcol(0, Point3(10,0,0))
    resTm.setcol(1, Point3(0,10,0))
    resTm.setcol(2, Point3(0,0,10))
    resTm.setcol(3, resTm.getcol(3) + Point3(0,1,0))
    ecs.obsolete_dbg_set_comp_val(eid, "transform", resTm)

    gui_scene.resetTimeout(0.1, function() {
      setEditMode?(DE4_MODE_SELECT)
      entity_editor?.get_instance()?.selectEntities([eid])
    })
  }
}
addEntityCreatedCallback(onCreatedRIRemoverEntity)

let movedEntities = {}
let function onRIEntityMovesEnd() {
  foreach (eid, _val in movedEntities) {
    let ri_extra = ecs.obsolete_dbg_get_comp_val(eid, "ri_extra", null)
    if (ri_extra != null) {
      ecs.g_entity_mgr.sendEvent(eid, EventEditorEntityMoved())
    }
  }
  movedEntities.clear()
}
let function onRIEntityMoved(eid) {
  movedEntities[eid] <- true
  gui_scene.resetTimeout(0.25, onRIEntityMovesEnd)
}
addEntityMovedCallback(onRIEntityMoved)

return {
  isRIToolMode
  beginRIToolMode
  clearRIToolSelected
  riToolSelected
  getRIToolRemovedCount
  removeRIToolSelected
  unbakeRIToolSelected
  enbakeRIToolSelected
  rebakeRIToolSelected
  instanceRIToolSelected
  restoreRemovedByRITool
  spawnNewRIEntity
  selectRIToolInside
}
