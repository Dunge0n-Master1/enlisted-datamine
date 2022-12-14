from "%enlSqGlob/ui_library.nut" import *
from "%darg/laconic.nut" import *
from "string" import regexp, startswith, endswith
import "%dngscripts/ecs.nut" as ecs

let {app_is_offline_mode, app_set_offline_mode, exit_game, switch_to_menu_scene, switch_scene} = require("app")

let isSandboxContext = @() app_is_offline_mode()
let sandboxEditorEnabled = Watched(isSandboxContext())
let entity_editor = require_optional("entity_editor")
if (!sandboxEditorEnabled.value || entity_editor==null)
  return {sandboxEditorEnabled, sandboxEditor=null, isSandboxEditor=@() false, quitSandboxEditor=@() null}

let {dgs_get_settings, DBGLEVEL} = require("dagor.system")
let devMode = (DBGLEVEL > 0)

let {EventSessionFinished} = require("dasevents")

let {get_scene_filepath} = entity_editor
let {levelLoaded, levelIsLoading, currentLevelBlk} = require("%ui/hud/state/appState.nut")
let levelIsNotPresent = Computed(@() (!levelLoaded.value && !levelIsLoading.value))

let fa = require("%ui/components/fontawesome.map.nut")
let {fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let cursors = require("%daeditor/components/cursors.nut")
let mkWindow = require("%daeditor/components/window.nut")
let textButton = require("%daeditor/components/textButton.nut")
let {makeVertScroll} = require("%ui/components/scrollbar.nut")
let {editorTimeStop, showPointAction, namePointAction} = require("%daeditor/state.nut")

let {editorIsActive, editorFreeCam, initTemplatesGroups, initRISelect, proceedWithSavingUnsavedChanges, hideDebugButtons} = require("%ui/editor.nut")
let {predefinedRIGroups} = require("sandbox_ri_groups.nut")
initRISelect("content/common/gamedata/ri_list.blk", predefinedRIGroups)
initTemplatesGroups(false)
hideDebugButtons()

let {scan_folder, mkdir, find_files, file_exists} = require("dagor.fs")
let DataBlock = require("DataBlock")
let textInput = require("%ui/components/textInput.nut")

let modalWindows = require("%ui/components/modalWindowsMngr.nut")({halign = ALIGN_CENTER valign = ALIGN_CENTER rendObj=ROBJ_WORLD_BLUR})
let {addModalWindow, removeModalWindow, modalWindowsComponent} = modalWindows
let {registerPerCompPropEdit} = require("%daeditor/propPanelControls.nut")
let {msgboxComponent, showMsgbox} = require("%ui/components/mkMsgbox.nut")("sandbox_")
let infoBox = @(text) showMsgbox({text})

let {openPlayConfigDialog, backupSaveEnabled} = require("sandbox_playconfig.nut")
let {showHints, hintShown, hintWindow} = require("sandbox_hints.nut")
let {setToolboxShowMsgbox, toolboxShown, toolboxPopup} = require("sandbox_toolbox.nut")
setToolboxShowMsgbox(showMsgbox)


let useSources = dgs_get_settings()?.debug.useAddonVromSrc ?? false
let getLevelsList = @() scan_folder({root="levels", vromfs = !useSources, realfs = useSources, recursive = true, files_suffix=".blk"}).sort()

const MODS_PREFABS_PATH = "content/ugm_scenes"
let getPrefabsList = @() scan_folder({root=MODS_PREFABS_PATH, vromfs = !useSources, realfs = useSources, recursive = true, files_suffix=".blk"}).sort()

console_register_command(
  @() sandboxEditorEnabled(!sandboxEditorEnabled.value) ?? console_print("editor.enableSceneLoad set to", sandboxEditorEnabled.value),
  "editor.enableSceneLoad"
)
let loadSceneLoc = loc("sandboxeditor/openScenes", "Scenes")
let scenesOpened = mkWatched(persist, "scenesOpened", false)

let mkSelectLine = kwarg(function(selected, textCtor = null, onSelect=null, onDClick=null){
  textCtor = textCtor ?? @(opt) opt
  return function(opt, i){
    let isSelected = Computed(@() selected.value == opt)
    let onClick = onSelect != null ? @() onSelect?(opt) : @() (!isSelected.value ? selected(opt) : selected(null))
    let onDoubleClick = onDClick != null ? @() onDClick?(opt) : null
    return watchElemState(@(sf) {
      size = [flex(), SIZE_TO_CONTENT]
      padding = [hdpx(3), hdpx(10)]
      behavior = Behaviors.Button
      watch = isSelected
      onClick
      onDoubleClick
      children = txt(textCtor(opt), {color = isSelected.value ? null : Color(190,190,190)})
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? Color(120,120,160) : (i%2) ? Color(0,0,0,120) : 0
      borderWidth = isSelected.value ? hdpx(2) : 0
    })
  }
})


let transformLevelName = @(name) name?.replace("levels/", "").replace(".blk", "") ?? "Select level (dev only)..."

let function openSelectLevel(selectedLevel, onSelect=null) {
  let key = {}
  let close = @() removeModalWindow(key)
  let mkSelectedLevel = mkSelectLine({
    selected = selectedLevel,
    onSelect = function(v) {selectedLevel(v); onSelect?(v); close()}
  })
  addModalWindow({key,
    children = {
      behavior = Behaviors.Button
      size = [sw(50), sh(70)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = Color(30,30,30, 190)
      padding = hdpx(10)
      children = vflow(
        Flex()
        Gap(hdpx(10))
        txt("SELECT LEVEL", {hplace = ALIGN_CENTER})
        makeVertScroll(vflow(Size(flex(), SIZE_TO_CONTENT), getLevelsList().map(mkSelectedLevel)))
        comp(Bottom, textButton("Close", close, {hotkeys = [["Esc"]], vplace = ALIGN_BOTTOM}))
      )
    }
  })
}

let transformPrefabName = @(name) name?.replace($"{MODS_PREFABS_PATH}/", "").replace(".blk", "") ?? "Select location..."

let function openSelectPrefab(selectedPrefab, onSelect=null) {
  let key = {}
  let close = @() removeModalWindow(key)
  let mkSelectedPrefab = mkSelectLine({
    selected = selectedPrefab,
    onSelect = function(v) {selectedPrefab($"{MODS_PREFABS_PATH}/{v}"); onSelect?(v); close()}
  })
  addModalWindow({key,
    children = {
      behavior = Behaviors.Button
      size = [sw(30), sh(60)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = Color(30,30,30, 190)
      padding = hdpx(10)
      children = vflow(
        Flex()
        Gap(hdpx(10))
        txt("SELECT LOCATION", {hplace = ALIGN_CENTER})
        makeVertScroll(vflow(Size(flex(), SIZE_TO_CONTENT), getPrefabsList().map(transformPrefabName).map(mkSelectedPrefab)))
        comp(Bottom, textButton("Close", close, {hotkeys = [["Esc"]], vplace = ALIGN_BOTTOM}))
      )
    }
  })
}


const MODS_TO_EDIT_FOLDER = "userGameMods"
const DEF_SCENE_FILENAME = "scene.blk"

const BACKUPSAVE_TIME = 300.0 // 5min
let function sandboxBackupSave() {
  gui_scene.resetTimeout(BACKUPSAVE_TIME, sandboxBackupSave)
  if (backupSaveEnabled.value && levelLoaded.value && !levelIsLoading.value && editorIsActive.value) {
    let path = get_scene_filepath()
    if (startswith(path, $"{MODS_TO_EDIT_FOLDER}/") && endswith(path, $"/{DEF_SCENE_FILENAME}")) {
      let modName = path.slice(MODS_TO_EDIT_FOLDER.len()+1, path.len()-DEF_SCENE_FILENAME.len()-1)
      let pathSave = $"{MODS_TO_EDIT_FOLDER}/backup.{modName}.scene.blk"
      print($"Backup saving scene to {pathSave}")
      entity_editor?.get_instance().saveObjectsCopy(pathSave, "backup")
    }
  }
}
editorIsActive.subscribe(function(v) {
  if (v) {
    // NOTE: Delay backup to give user time to reload unmodified scene after playtesting
    gui_scene.resetTimeout(BACKUPSAVE_TIME, sandboxBackupSave)
  }
})
gui_scene.resetTimeout(BACKUPSAVE_TIME, sandboxBackupSave)

let convertToPath = @(v) v.split("/").slice(1)
let function convertToModAndScene(v) {
  if (type(v)!="string")
    return v
  let path = convertToPath(v)
  return {mod = path[0], scene="/".join(path.slice(1))}
}

let function loadScene(modAndScene) {
  if (modAndScene==null)
    return
  let {mod, scene} = convertToModAndScene(modAndScene)
  console_command("daEd4.open 0")
  switch_scene($"?*?{mod}?{scene}", null, null, null, "sandboxEditor")
}
let function loadSceneWithSavingUnsavedChanges(modAndScene) {
  if (modAndScene==null)
    return
  proceedWithSavingUnsavedChanges(showMsgbox, @() loadScene(modAndScene))
}

let selectedScene = Watched()

let mkOpenSceneRow = mkSelectLine({
  selected = selectedScene, textCtor = @(ms) $"{ms.mod}/{ms.scene ?? ""}",
  onDClick = @(opt) opt?.scene != null ? loadSceneWithSavingUnsavedChanges(opt) : null
})

if (devMode) {
  registerPerCompPropEdit("level__blk", function(params){
    let selectedLevel = Watched(params?.obj)
    let eid = params.eid
    let function onSelect(v){
      if ((eid ?? ecs.INVALID_ENTITY_ID) != ecs.INVALID_ENTITY_ID)
        ecs.obsolete_dbg_set_comp_val(eid, "level__blk", v)
      infoBox("Save and than load scene to make changes visible and reload location")
    }
    return @() {
      watch = selectedLevel,
      children = textButton(transformLevelName(selectedLevel.value), @() openSelectLevel(selectedLevel, onSelect))
    }
  })
}

let availableModsAndScenes = mkWatched(persist, "availableModsAndScenes", [])

let function scanForModsAndScene(){
  let files = scan_folder({root=MODS_TO_EDIT_FOLDER, vromfs = false, realfs = true, recursive = true, files_suffix=DEF_SCENE_FILENAME})
    .map(convertToPath)
    .filter(@(v) v.len()==2 && v[1] == DEF_SCENE_FILENAME)
  let modsAndScenes = files.map(function(path) {
      return {mod = path[0], scene=path[1]}
    })
  return modsAndScenes.sort(@(a,b) a.mod<=>b.mod)
}

let updateScenes = @() availableModsAndScenes(scanForModsAndScene())
const newSceneUID = "new_scene"

let function mkSimpleBlk(data){
  let blk = DataBlock()
  assert (typeof data != "array", "currently not supported arrays, add if needed")
  foreach (k, v in data){
    if (typeof v == "table") {
      blk[k] <- mkSimpleBlk(v)
    }
    else {
      blk[k] <- v
    }
  }
  return blk
}

let validNewSceneNameRegExp = regexp(@"[a-z,A-Z,0-9,_]*")
let function isNewSceneNameValid(name) {
  return validNewSceneNameRegExp.match(name)
}

let function openNewSceneWnd(){
  let sceneName = Watched("")
  let sceneNameComp = textInput(sceneName, {onAttach = @(elem) set_kb_focus(elem)})
  let close = @() removeModalWindow(newSceneUID)
  let selectedLevel = Watched(null)
  let selectedPrefab = Watched(null)
  let selectLevel = @() openSelectLevel(selectedLevel, @(_) selectedPrefab(null))
  let selectPrefab = @() openSelectPrefab(selectedPrefab, @(_) selectedLevel(null))

  let isSceneCreateAllowed = Computed(@() sceneName.value!=null && isNewSceneNameValid(sceneName.value)
                                          && (selectedLevel.value!=null || selectedPrefab.value!=null))
  let function createScene(name){
    if (name==null || name.len()<=0) {
      infoBox($"No mod name entered")
      return
    }
    let path = $"{MODS_TO_EDIT_FOLDER}/{name}"
    let folderExists = find_files($"{MODS_TO_EDIT_FOLDER}/*").findvalue(@(v) v.name==name)!=null
    if (folderExists){
      infoBox($"Folder or file '{name}' already exists in {MODS_TO_EDIT_FOLDER}")
      return
    }
    if (file_exists($"{path}/{DEF_SCENE_FILENAME}")){
      infoBox($"File '{DEF_SCENE_FILENAME}' already exists in {path}")
      return
    }
    local blk = null
    if (selectedPrefab.value!=null){
      blk = DataBlock()
      try
        blk.load($"{selectedPrefab.value}")
      catch(e)
        blk = null
    }
    else{
      try
        blk = mkSimpleBlk({entity = {_template="level", ["level__blk"] = selectedLevel.value}})
      catch(e)
        blk = null
    }

    if (blk==null){
      infoBox($"Failed to obtain scene data")
      return
    }
    let res = mkdir(path)
    if (!res){
      infoBox($"Could not create '{name}'")
      return
    }
    let scenePath = $"{path}/{DEF_SCENE_FILENAME}"
    blk.saveToTextFile(scenePath)
    updateScenes()
    loadScene(scenePath)
    close()
  }
  addModalWindow({
    key = newSceneUID
    children = vflow(
      Button
      RendObj(ROBJ_SOLID)
      Padding(hdpx(10))
      Colr(30,30,30)
      Gap(hdpx(10))
      txt("CREATE NEW SCENE MOD", {hplace = ALIGN_CENTER})
      devMode ? (@() {watch = selectedLevel, children = textButton(transformLevelName(selectedLevel.value), selectLevel)}) : null
      @() {watch = selectedPrefab, children = textButton(transformPrefabName(selectedPrefab.value), selectPrefab)}
      vflow(Size(flex(), SIZE_TO_CONTENT), txt("Mod name:"), sceneNameComp)
      hflow(
        textButton("Cancel", close, {hotkeys=[["Esc"]]})
        @() {
          watch = isSceneCreateAllowed
          children = isSceneCreateAllowed.value ? textButton("Create", @() createScene(sceneName.value))
                                                : textButton("Create", @() null, {off=true})
        }
      )
    )
  })
}

let configBtnBlack = textButton(
  fa["wrench"],
  @() openPlayConfigDialog(modalWindows),
  {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,255)}}})

let getFullScenePath = @(ms) $"{MODS_TO_EDIT_FOLDER}/{ms.mod}/{ms.scene}"
let getCurScene = @() availableModsAndScenes.value.findvalue(@(v) getFullScenePath(v) == get_scene_filepath())

let selScenesWindow = mkWindow({
  id = "open_scene"
  onAttach = updateScenes
  windowStyle = {fillColor = Color(40,40,40,120)}
  content = @() {
    flow  = FLOW_VERTICAL
    size = flex()
    gap  = hdpx(2)
    watch = availableModsAndScenes
    onAttach = @() selectedScene(getCurScene())
    halign = ALIGN_CENTER
    children = [
      hflow( Gap(hdpx(5)), VACenter, Size(flex(), SIZE_TO_CONTENT), Padding(hdpx(5),hdpx(5)), RendObj(ROBJ_SOLID), Colr(60,60,90),
        txt(loadSceneLoc),
        txt($"(list of <modName>/{DEF_SCENE_FILENAME} in '{MODS_TO_EDIT_FOLDER}' folder)"),
        comp(Flex()),
        textButton(fa["refresh"], updateScenes, {textStyle = {normal = fontawesome}})
      )
      makeVertScroll(
        vflow(Padding(hdpx(4)), Size(flex() SIZE_TO_CONTENT), RendObj(ROBJ_SOLID), Colr(0,0,0,50),
          availableModsAndScenes.value.map(mkOpenSceneRow)
        )
      )
      hflow(
        Size(flex(), SIZE_TO_CONTENT)
        levelIsNotPresent.value ? null : textButton("Cancel", @() scenesOpened(false), {hotkeys = [["Esc"]]})
        textButton("New Scene", @() proceedWithSavingUnsavedChanges(showMsgbox, openNewSceneWnd))
        comp(Flex())
        @() {
          watch = selectedScene
          flow = FLOW_HORIZONTAL
          children = selectedScene.value?.scene != null ? [
            configBtnBlack
            textButton("Load", @() scenesOpened(false) ?? loadSceneWithSavingUnsavedChanges(selectedScene.value), {hotkeys = [["Enter"]]})
          ] : null
        }
      )
    ]
  }
})


let toolboxBtn = textButton(
    loc("sandboxeditor/toolbox", "Toolbox"),
    function() { toolboxShown(!toolboxShown.value); cursors.setTooltip(null) },
    {hotkeys = [["L.Ctrl F | R.Ctrl F"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) cursors.setTooltip(on && !toolboxShown.value ? "Set of game editing tools (Ctrl+F)" : null)})

let restartBtn = textButton(
    loc("sandboxeditor/restart", "Restart"),
    @() proceedWithSavingUnsavedChanges(showMsgbox, @() loadScene(get_scene_filepath()), "You have unsaved changes. How do you want to restart?",
                                                                                         "Do you want to restart?"),
    {hotkeys = [["L.Ctrl !L.Alt R | R.Ctrl !R.Alt R"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) cursors.setTooltip(on ? "Restart scene (Ctrl+R)" : null)})

let openScenesToEditBtn = textButton(
    loadSceneLoc,
    @() scenesOpened(!scenesOpened.value),
    {hotkeys = [["L.Ctrl O | R.Ctrl O"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) cursors.setTooltip(on ? "Load or create new scene (Ctrl+O)" : null)})

let configBtn = textButton(
    fa["wrench"],
    @() openPlayConfigDialog(modalWindows),
    {hotkeys = [["L.Ctrl G | R.Ctrl G"]], textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) cursors.setTooltip(on ? "Sandbox Config (Ctrl+G)" : null)})

let function quitSandboxEditor() {
  proceedWithSavingUnsavedChanges(showMsgbox,
    function() {
      console_command("daEd4.open 0")
      if (app_set_offline_mode(false))
        switch_to_menu_scene()
      else
        exit_game()
    },
    "You have unsaved changes in Sandbox. How do you want to exit?",
    "Do you want to exit Sandbox?")
}

let quitBtn = textButton(
    fa["close"],
    @() quitSandboxEditor(),
    {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) cursors.setTooltip(on ? "Quit" : null)})


let worldRender = Watched(false)
let worldRenderInited = Computed(@() worldRender.value || (currentLevelBlk.value!=null && levelLoaded.value))
ecs.register_es("worldRendererInited", {onInit = @(...) worldRender(true), onDestroy = @(...) worldRender(false)},
  {comps_rq=["world_renderer_tag"]}
)
let function openScenesIfNeeded(...){
  if (worldRenderInited.value && !levelIsLoading.value) {
    if (currentLevelBlk.value == null)
      scenesOpened(true)
    else
      showHints()
  }
}

worldRenderInited.subscribe(openScenesIfNeeded)
levelIsLoading.subscribe(openScenesIfNeeded)

editorIsActive.subscribe(@(v) editorTimeStop(v))

let transformCurSceneName = @(name) name?.replace($"{MODS_TO_EDIT_FOLDER}/", "").replace($"/{DEF_SCENE_FILENAME}", "") ?? "Untitled"

let function sandboxEditor(){
  let sceneName = transformCurSceneName(get_scene_filepath())
  let sceneNameBtn = {
    pos = [0, hdpx(7)]
    behavior = Behaviors.Button
    onClick = @() null
    children = txt(sceneName)
  }

  return {
    size = flex()
    watch = [scenesOpened, hintShown, editorIsActive, editorFreeCam, levelLoaded, levelIsLoading, levelIsNotPresent, toolboxShown, showPointAction, namePointAction]
    children = [
      !levelLoaded.value ? null : (
        !editorIsActive.value ? txt("F12 to open editor", {padding = hdpx(10), hplace = ALIGN_CENTER}) :
        editorFreeCam.value  ? { rendObj = ROBJ_BOX, fillColor = Color(20,20,20,100), borderRadius = hdpx(10), padding = hdpx(8), hplace = ALIGN_CENTER,
                                 children = txt(showPointAction.value ? $"Free camera [ {namePointAction.value} ]" : "Free camera mode") } :
        showPointAction.value ? { rendObj = ROBJ_BOX, fillColor = Color(20,20,20,100), borderRadius = hdpx(10), padding = hdpx(8), hplace = ALIGN_CENTER,
                                  children = txt(namePointAction.value) } :
                                null ),
      {
        cursor = cursors.normal
        size = SIZE_TO_CONTENT
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        children = [
          (levelLoaded.value && editorIsActive.value) ? sceneNameBtn : null,
          (levelLoaded.value && editorIsActive.value) ? toolboxBtn : null,
          (levelLoaded.value && editorIsActive.value) ? restartBtn : null,
          (levelLoaded.value && editorIsActive.value) || levelIsNotPresent.value ? openScenesToEditBtn : null,
          (levelLoaded.value && editorIsActive.value) ? { size = [0, SIZE_TO_CONTENT] } : null,
          (levelLoaded.value && editorIsActive.value) ? configBtn : null,
          (levelLoaded.value && editorIsActive.value) || levelIsNotPresent.value ? quitBtn : null
        ]
      },
      (levelLoaded.value && editorIsActive.value && toolboxShown.value) ? toolboxPopup : null,
      scenesOpened.value ? selScenesWindow : null,
      hintShown.value ? hintWindow : null,
      modalWindowsComponent,
      msgboxComponent
    ]
  }.__update(!editorIsActive.value && levelIsNotPresent.value ? {cursor = cursors.normal} : {})
}

ecs.register_es("sandbox_session_finish_es",
  {
    [EventSessionFinished] = function(_eid, _c){
      if (!isSandboxContext())
        return

      gui_scene.resetTimeout(3.3, function(){
        proceedWithSavingUnsavedChanges(showMsgbox, function(){
          local curScene = get_scene_filepath()
          if (curScene!=null)
            loadScene(curScene)
        }, "Game session has finished. You have unsaved changes. How do you want to reload the scene?",
          "Game session has finished. Do you want to reload the scene?")
      })
    }
  }
)

return {sandboxEditorEnabled, sandboxEditor, isSandboxEditor=@() true, quitSandboxEditor}
