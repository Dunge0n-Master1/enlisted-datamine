from "%enlSqGlob/ui_library.nut" import *

let { uiInEditorUpdate, editorActivnessUpdate } = require("%enlSqGlob/editorState.nut")
local editor = null
local editorState = null
local showUIinEditor = Watched(false)
local editorIsActive = Watched(false)
local editorFreeCam  = Watched(false)
local initRISelect   = @(_a,_b) null
local proceedWithSavingUnsavedChanges = @() false
let daEditor4 = require_optional("daEditor4")
if (daEditor4 != null) {
  editor = require_optional("%daeditor/editor.nut")
  editorState = require_optional("%daeditor/state.nut")
  showUIinEditor = editorState?.showUIinEditor ?? showUIinEditor
  editorIsActive = editorState?.editorIsActive ?? editorIsActive
  editorActivnessUpdate(editorIsActive.value)//dirty hack to fix enlist
  uiInEditorUpdate(showUIinEditor.value)
  showUIinEditor.subscribe(@(v) uiInEditorUpdate(v))
  editorIsActive.subscribe(@(v) editorActivnessUpdate(v))//dirty hack to fix enlist
  editorFreeCam  = editorState?.editorFreeCam  ?? editorFreeCam
  initRISelect   = require_optional("%daeditor/riSelect.nut")?.initRISelect ?? @(_a,_b) null
  proceedWithSavingUnsavedChanges = editorState?.proceedWithSavingUnsavedChanges ?? proceedWithSavingUnsavedChanges
  let { DBGLEVEL } = require("dagor.system")
  let defaultWorkMode = DBGLEVEL > 0 ? "Developer" : "Designer"
  editorState?.initWorkModes?(["Developer", "Designer"], defaultWorkMode)
}

let entity_editor = require_optional("entity_editor")
if (entity_editor != null) {
  let {clear_entity_save_order, add_entity_save_order_comp} = entity_editor
  clear_entity_save_order()
  add_entity_save_order_comp("battle_area_polygon_point__")
  add_entity_save_order_comp("battleAreaId")
  add_entity_save_order_comp("battle_area__")
}

let function hideDebugButtons() {
  let {showDebugButtons=null} = require_optional("%daeditor/state.nut")
  if (showDebugButtons!=null)
    showDebugButtons(false)
}

let {initTemplatesGroups=null} = require_optional("editorTemplatesGroups.nut")
initTemplatesGroups?(true)

return {
  editor, showUIinEditor, editorIsActive, editorFreeCam, initTemplatesGroups, initRISelect, proceedWithSavingUnsavedChanges, hideDebugButtons
}