from "%enlSqGlob/ui_library.nut" import *
from "%darg/laconic.nut" import *

let cursors = require("%daeditor/components/cursors.nut")
let textButton = require("%daeditor/components/textButton.nut")
let {makeVertScroll} = require("%ui/components/scrollbar.nut")

let checkbox = require("%ui/components/checkbox.nut")
let {hintWelcomeKeepShowing} = require("sandbox_hints.nut")
let showHintAtStartup = Watched(hintWelcomeKeepShowing.value)

let {
  save_settings = null, get_setting_by_blk_path = null, set_setting_by_blk_path = null
} = require_optional("settings")

let backupSaveEnabled = Watched(true)
const SETTING_EDITOR_BACKUPSAVE_ENABLED = "daEditor4/sandboxBackupSaveEnabled"
backupSaveEnabled(get_setting_by_blk_path?(SETTING_EDITOR_BACKUPSAVE_ENABLED) ?? true)
backupSaveEnabled.subscribe(function(v) {
  set_setting_by_blk_path?(SETTING_EDITOR_BACKUPSAVE_ENABLED, v)
  save_settings?()
})
let backupSaveEnabledOption = Watched(backupSaveEnabled.value)

let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let function getAllSquads() {
  local squads = [""]
  foreach (group in squadsPresentation)
    foreach (name,_val in group)
      if (!name.contains("_prem"))
        squads.append(name)
  return squads.sort()
}

const SETTING_EDITOR_PLAYCONFIG = "daEditor4/sandboxPlayConfig_"

let playOptions = {
  difficulty = ["", "standard", "hardcore"]
  mode       = ["", "SQUADS", "LONE_FIGHTERS"]
  spawnMode  = ["", "UNLIMITED_SPAWNS", "ONE_SPAWN_PER_UNIT"]
  botpop     = [-1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
  team       = [-1, 1, 2]
  squad      = getAllSquads()
}

let playConfig = {}
foreach (opt,_ in playOptions) {
  playConfig[opt] <- playOptions[opt][0]
  let val = get_setting_by_blk_path?($"{SETTING_EDITOR_PLAYCONFIG}{opt}")
  if (val!=null && val!="")
    playConfig[opt] = val
}


let editConfig = Watched({})
local editConfigModalWindows = null

let function setupOption(opt) {
  let options = playOptions?[opt]
  if ((options?.len()??0)<=0)
    return
  local use_next = false
  local value = options[0]
  foreach (v in options) {
    if (use_next) {
      value = v
      break
    }
    if (editConfig.value[opt] == v)
      use_next = true
  }
  editConfig.mutate(@(v) v[opt] <- value)
}

let mkSelectLine = kwarg(function(selected, textCtor = null, onSelect=null, onDClick=null){
  textCtor = textCtor ?? @(opt) opt
  return function(opt, i){
    let isSelected = Computed(@() selected.value == opt)
    let onClick = onSelect != null ? @() onSelect?(opt)
      : @() (!isSelected.value ? selected(opt) : selected(null))
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

let function openSelectSquadList(squad, onSelect) {
  let key = {}
  let close = @() editConfigModalWindows.removeModalWindow(key)
  let selectedSquad = Watched(squad)
  let mkSelectedSquad = mkSelectLine({
    selected = selectedSquad,
    textCtor = @(opt) opt != "" ? opt : "<default>"
    onSelect = function(v) {onSelect(v); close()}
  })
  editConfigModalWindows.addModalWindow({key,
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
        txt("SELECT SQUAD", {hplace = ALIGN_CENTER})
        makeVertScroll(vflow(Size(flex(), SIZE_TO_CONTENT), playOptions.squad.map(mkSelectedSquad)))
        comp(Bottom, textButton("Close", close, {hotkeys = [["Esc"]], vplace = ALIGN_BOTTOM}))
      )
    }
  })
}

let gap = @(size) { size = [size, size] }

let function openPlayConfigDialogInternal(modalWindows) {
  let key = "play_config_dialog"
  let close = @() modalWindows.removeModalWindow(key)
  let apply = function() {
    foreach (opt,val in editConfig.value) {
      if (playConfig[opt]!=val) {
        playConfig[opt] = val
        set_setting_by_blk_path?($"{SETTING_EDITOR_PLAYCONFIG}{opt}", val ?? playOptions[opt][0])
        save_settings?()
      }
    }
    hintWelcomeKeepShowing(showHintAtStartup.value)
    backupSaveEnabled(backupSaveEnabledOption.value)
    modalWindows.removeModalWindow(key)
  }

  let txtStyle1 = {size=[hdpx(120),SIZE_TO_CONTENT] pos=[0,hdpx(5)]}
  let valStyle  = {size=[hdpx(260),SIZE_TO_CONTENT]}

  let optionButton = @(opt) @(){
      watch = editConfig
      children = textButton(
        (editConfig.value[opt] ?? "") == "" || editConfig.value[opt]==-1
          ? "<default>"
          : editConfig.value[opt],
        @() opt == "squad"
          ? openSelectSquadList(editConfig.value[opt], @(val) editConfig.mutate(@(v) v[opt] <- val))
          : setupOption(opt)
        , valStyle)
  }

  modalWindows.addModalWindow({key,
    children = {
      cursor = cursors.normal
      behavior = Behaviors.Button
      size = [hdpx(390), hdpx(410)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = Color(30,30,30, 190)
      padding = hdpx(20)
      children = vflow(
        Flex()
        Gap(hdpx(10))
        txt("SANDBOX CONFIG", {hplace = ALIGN_CENTER})
        txt("Scene should be restarted for modifications to take place",
          {hplace = ALIGN_CENTER, fontSize = hdpx(13)})
        gap(hdpx(2))
        hflow(Flex() txt("Difficulty",  txtStyle1) optionButton("difficulty"))
        hflow(Flex() txt("Game mode",   txtStyle1) optionButton("mode"))
        hflow(Flex() txt("Spawn mode",  txtStyle1) optionButton("spawnMode"))
        hflow(Flex() txt("Bot count",   txtStyle1) optionButton("botpop"))
        hflow(Flex() txt("Team",        txtStyle1) optionButton("team"))
        // FIXME, not working for now (REQUIRED VALID sandbox_profile.nut) ==> hflow(Flex() txt("Squad",       txtStyle1) optionButton("squad"))
        gap(hdpx(2))
        hflow(
          Size(flex(), hdpx(20)) {
            pos = [0, hdpx(6)], children = checkbox(showHintAtStartup, {
            text = "Show hint window at startup"
            textStyle = {fontSize = hdpx(13)}})
          }
        )
        hflow(
          Size(flex(), hdpx(20)) {
            pos = [0, hdpx(6)], children = checkbox(backupSaveEnabledOption, {
            text = "Backup scene every 5 minutes"
            textStyle = {fontSize = hdpx(13)}})
          }
        )
        gap(hdpx(20))
        hflow(
          Size(flex(), SIZE_TO_CONTENT)
          comp(Flex())
          textButton("Cancel", close, {hotkeys = [["Esc"]], vplace = ALIGN_BOTTOM})
          textButton("Apply", apply, {vplace = ALIGN_BOTTOM})
        )
      )
    }
  })
}

let function openPlayConfigDialog(modalWindows) {
  editConfigModalWindows = modalWindows

  editConfig(clone playConfig)

  showHintAtStartup(hintWelcomeKeepShowing.value)

  backupSaveEnabledOption(backupSaveEnabled.value)

  openPlayConfigDialogInternal(modalWindows)
}

return { playConfig, openPlayConfigDialog, backupSaveEnabled }
