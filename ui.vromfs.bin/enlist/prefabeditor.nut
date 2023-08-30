from "%darg/ui_imports.nut" import *
import "%dngscripts/ecs.nut" as ecs

let {
  PrefabSaveEvent, PrefabCreateFromSelectedEvent, AddSelectedToPrefabEvent,
  PrefabSpawnEvent, PrefabSelectParentEvent, PrefabShatterSelectedEvent
} = require("dasevents")
let {isPrefabTool, selectedPrefabs, selectedPrefab, selectedPrefabObjects, selectedNoPrefabs, prefabsLibrary, getPrefabsInLibrary} = require("prefabEditorState.nut")
let modalWindows = require("%daeditor/components/modalWindowsMngr.nut")({halign = ALIGN_CENTER valign = ALIGN_CENTER rendObj=ROBJ_WORLD_BLUR})
let {addModalWindow, removeModalWindow, modalWindowsComponent, hasModalWindows} = modalWindows
let textInput = require("%daeditor/components/textInput.nut")
let {is_prefab_name_valid, make_prefab_path} = require("das.prefab")
let {colors} = require("%daeditor/components/style.nut")
let txt = require("%daeditor/components/text.nut").dtext
let {showTemplateSelect} = require("%daeditor/state.nut")
let textButton = require("%daeditor/components/textButton.nut")
let closeButton = require("%daeditor/components/closeButton.nut")
let nameFilter = require("%daeditor/components/nameFilter.nut")
let scrollbar = require("%daeditor/components/scrollbar.nut")
let daEditor4 = require("daEditor4")
let fa = require("%ui/components/fontawesome.map.nut")
let {fontawesome} = require("%enlSqGlob/ui/fontsStyle.nut")
let cursors = require("%daeditor/components/cursors.nut")
let { remove } = require("system")
let { file_exists, mkdir } = require("dagor.fs")
let {DE4_MODE_SELECT} = daEditor4
let entity_editor = require_optional("entity_editor")

showTemplateSelect.subscribe(@(v) isPrefabTool(isPrefabTool.value && !v))
isPrefabTool.subscribe(function(v) {
  if (showTemplateSelect.value && v)
    daEditor4.setEditMode(DE4_MODE_SELECT)
  showTemplateSelect(showTemplateSelect.value && !v)
})


let selectedItem = Watched(null)
let filterText = Watched("")
let newPrefabName = Watched("")
let isNewPrefabNameValid = Computed(@() is_prefab_name_valid(newPrefabName.value ?? ""))

let scrollHandler = ScrollHandler()

let function scrollByName(text) {
  scrollHandler.scrollToChildren(function(desc) {
    return ("prefab_name" in desc) && desc.prefab_name.indexof(text)!=null
  }, 2, false, true)
}

let function scrollBySelection() {
  scrollHandler.scrollToChildren(function(desc) {
    return ("prefab_name" in desc) && desc.prefab_name==selectedItem.value
  }, 2, false, true)
}

let filter = nameFilter(filterText, {
  placeholder = "Filter by name"

  function onChange(text) {
    filterText(text)

    if (selectedItem.value && text.len()>0 && selectedItem.value.tolower().contains(text.tolower()))
      scrollBySelection()
    else if (text.len())
      scrollByName(text)
    else
      scrollBySelection()
  }

  function onEscape() {
    set_kb_focus(null)
  }

  function onReturn() {
    set_kb_focus(null)
  }

  function onClear() {
    filterText.update("")
    set_kb_focus(null)
  }
})

let function doSelectPrefab(prefab_name) {
  selectedItem(prefab_name)
  ecs.g_entity_mgr.broadcastEvent(PrefabSpawnEvent({name=prefab_name}))
}

let function listRow(prefab_name, idx) {
  let stateFlags = Watched(0)

  return function() {
    let isSelected = selectedItem.value == prefab_name

    local color
    if (isSelected) {
      color = colors.Active
    } else {
      color = (stateFlags.value & S_TOP_HOVER) ? colors.GridRowHover : colors.GridBg[idx % colors.GridBg.len()]
    }

    return {
      rendObj = ROBJ_SOLID
      size = [flex(), SIZE_TO_CONTENT]
      color = color
      behavior = Behaviors.Button
      prefab_name

      watch = stateFlags
      onClick = @() selectedItem(prefab_name)
      onDoubleClick = @() doSelectPrefab(prefab_name)
      onElemState = @(sf) stateFlags.update(sf & S_TOP_HOVER)

      children = {
        rendObj = ROBJ_TEXT
        text = prefab_name
        margin = fsh(0.5)
      }
    }
  }
}


let function prefabInfoBlock() {
  let prefab = selectedPrefab.value
  let prefabText = selectedPrefabs.value.len() == 0 ? "Prefab not selected"
                                                    : prefab
                                                      ? $"Prefab: {prefab.name} (#{prefab.eid})"
                                                      : $"Prefabs: {selectedPrefabs.value.len()} selected"
  return {
    flow = FLOW_VERTICAL
    watch = [selectedPrefabs, selectedPrefab, selectedPrefabObjects, selectedNoPrefabs]
    size = [flex(), SIZE_TO_CONTENT]
    margin = [0, 0, 0, hdpx(25)]
    children = [
      txt(prefabText, {
        fontSize = hdpx(16)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size = [flex(), SIZE_TO_CONTENT]
      })
      txt($"Prefab objects: {selectedPrefabObjects.value.len()}", {
        fontSize = hdpx(16)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size = [flex(), SIZE_TO_CONTENT]
      })
      txt($"Other entities: {selectedNoPrefabs.value.len()}", {
        fontSize = hdpx(16)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size = [flex(), SIZE_TO_CONTENT]
      })
    ]
  }
}

let function mkPrefabFolder() {
  if (!mkdir("userPrefabs")) {
    logerr("Failed to create userPrefabs folder. Prefabs can't be saved")
    return false
  }
  return true
}

let function prefabSaveAndShatterBlock() {
  let res = { watch = [selectedPrefabObjects, selectedPrefabs] }
  if (selectedPrefabObjects.value.len() == 0 && selectedPrefabs.value.len() == 0)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      textButton("Save", function() {
        if (!mkPrefabFolder())
          return

        foreach (eid in selectedPrefabObjects.value.keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSaveEvent({}))
        foreach (eid in selectedPrefabs.value.keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSaveEvent({}))
        gui_scene.resetTimeout(0.2, @() prefabsLibrary(getPrefabsInLibrary()))
      }, {onHover = @(on) cursors.setTooltip(on ? "Save selected prefab to file, replacing its previous content" : null)})
      textButton("Shatter", @() ecs.g_entity_mgr.broadcastEvent(PrefabShatterSelectedEvent({})), {onHover = @(on) cursors.setTooltip(on ? "Decompose prefab to separate entities" : null)})
      textButton("Delete", function() {
        foreach (eid in selectedPrefabObjects.value.keys())
          ecs.g_entity_mgr.destroyEntity(eid)
        foreach (eid in selectedPrefabs.value.keys())
          ecs.g_entity_mgr.destroyEntity(eid)
        gui_scene.resetTimeout(0.2, @() prefabsLibrary(getPrefabsInLibrary()))
      }, {onHover = @(on) cursors.setTooltip(on ? "Delete whole prefab or prefab entities from scene" : null)})
      selectedPrefabObjects.value.len() != 0 ? textButton("Parent", function() {
        entity_editor?.get_instance()?.selectEntities([])
        foreach (eid in selectedPrefabObjects.value.keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSelectParentEvent({}))
      }, {onHover = @(on) cursors.setTooltip(on ? "Select parent prefab entities of prefab objects" : null)}) : null
    ]
  })
}

const PREFAB_CREATE_MODAL_ID = "PREFAB_CREATE_MODAL_ID"
let function prefabCreateFromSelectedBlock() {
  let res = { watch = selectedNoPrefabs }
  if (selectedNoPrefabs.value.len() == 0)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      textButton("Create prefab from selected", @() addModalWindow({
        key = PREFAB_CREATE_MODAL_ID
        children = [
          {
            flow = FLOW_VERTICAL
            behavior = Behaviors.Button
            rendObj = ROBJ_SOLID
            padding = hdpx(10)
            margin = hdpx(20)
            color = Color(30, 30, 30)
            size = [flex(), SIZE_TO_CONTENT]
            children = [
              txt("CREATE PREFAB", {
                hplace = ALIGN_CENTER
              })
              {
                flow = FLOW_VERTICAL
                size = [flex(), SIZE_TO_CONTENT]
                children = [
                  txt("New prefab name:")
                  textInput(newPrefabName, {onAttach = @(elem) set_kb_focus(elem)})
                ]
              }
              {
                flow = FLOW_HORIZONTAL
                hplace = ALIGN_CENTER
                children = [
                  textButton("Cancel", @() removeModalWindow(PREFAB_CREATE_MODAL_ID), {hotkeys=[["Esc"]]})
                  @() {
                    watch = isNewPrefabNameValid
                    children = isNewPrefabNameValid.value
                      ? textButton("Create", function() {
                        if (!mkPrefabFolder())
                          return
                        ecs.g_entity_mgr.broadcastEvent(PrefabCreateFromSelectedEvent({name=newPrefabName.value, save=true}))
                        removeModalWindow(PREFAB_CREATE_MODAL_ID)
                        newPrefabName("")
                        gui_scene.resetTimeout(0.2, @() prefabsLibrary(getPrefabsInLibrary()))
                      })
                      : null
                  }
                ]
              }
            ]
          }
        ]
      }))
    ]
  })
}

let function addSelectedObjectsToPrefab() {
  let res = { watch = [selectedNoPrefabs, selectedPrefab] }
  if (selectedNoPrefabs.value.len() == 0 || selectedPrefab.value == null)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      textButton("Add selected objects to selected prefab", @() ecs.g_entity_mgr.sendEvent(selectedPrefab.value.eid, AddSelectedToPrefabEvent({})))
    ]
  })
}

let function dialogRoot() {
  let function listContent() {
    let rows = []
    local idx = 0
    foreach (prefab in prefabsLibrary.value)
      if (filterText.value.len() == 0 || prefab.tolower().contains(filterText.value.tolower()))
        rows.append(listRow(prefab, idx++))


    return {
      watch = [prefabsLibrary, selectedItem, filterText]
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = rows
      behavior = Behaviors.Button
    }
  }

  let scrollList = scrollbar.makeVertScroll(listContent, {
    scrollHandler
    rootBase = class {
      size = flex()
      function onAttach() {
        scrollBySelection()
      }
    }
  })


  let function doClose() {
    isPrefabTool(false)
    filterText("")
  }

  let function doDeleteSelected() {
    let filename = make_prefab_path(selectedItem.value)
    if (file_exists(filename))
      remove(filename)
    selectedItem(null)
    prefabsLibrary(getPrefabsInLibrary())
  }

  return {
    size = [flex(), flex()]
    flow = FLOW_HORIZONTAL
    children = [
      @() {
        size = [sw(17), sh(75)]
        hplace = ALIGN_LEFT
        vplace = ALIGN_CENTER
        rendObj = ROBJ_SOLID
        color = colors.ControlBg
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        behavior = Behaviors.Button
        key = "prefab_editor"
        padding = fsh(0.5)
        gap = fsh(0.5)
        watch = hasModalWindows
        children = !hasModalWindows.value ? [
          {
            flow = FLOW_HORIZONTAL
            size = [flex(), SIZE_TO_CONTENT]
            children = [
              txt("PREFABS", {
                fontSize = hdpx(15)
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                size = [flex(), SIZE_TO_CONTENT]
                margin = [0, 0, 0, hdpx(5)]
              })
              closeButton(doClose)
            ]
          }
          prefabInfoBlock
          prefabSaveAndShatterBlock
          prefabCreateFromSelectedBlock
          addSelectedObjectsToPrefab
          {
            flow = FLOW_HORIZONTAL
            size = [flex(), SIZE_TO_CONTENT]
            children = [
              txt("Prefabs (*.blk in 'userPrefabs' folder)", {
                fontSize = hdpx(15)
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                size = [flex(), SIZE_TO_CONTENT]
                margin = [0, 0, 0, hdpx(5)]
              })
              textButton(fa["refresh"], @() prefabsLibrary(getPrefabsInLibrary()), {textStyle = {normal = fontawesome}})
            ]
          }
          filter
          {
            size = flex()
            children = scrollList
          }
          txt("Click to select prefab, double click to spawn")
          @() {
            flow = FLOW_HORIZONTAL
            watch = selectedItem
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = [
              textButton("Close", doClose)
              selectedItem.value != null ? textButton("Remove from list", doDeleteSelected, {onHover = @(on) cursors.setTooltip(on ? "Delete prefab from userPrefabs folder" : null)}) : null
            ]
          }
        ] : modalWindowsComponent
      }
      {
        size = [sw(17), sh(60)]
        hplace = ALIGN_LEFT
        vplace = ALIGN_CENTER
      }
    ]
  }
}


return dialogRoot
