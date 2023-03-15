from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let {apply_video_settings} = require("videomode")
let {apply_audio_settings=@(_fields) null} = require_optional("sndcontrol")
let {isOption} = require("options/options_lib.nut")
let logMenu = require("%enlSqGlob/library_logs.nut").with_prefix("[SettingsMenu] ")
let textButton = require("%ui/components/textButton.nut")
let JB = require("%ui/control/gui_buttons.nut")
let settingsMenuCtor = require("%ui/components/settingsMenu.nut")
let msgbox = require("%ui/components/msgbox.nut")
let {getMenuOptions, menuOptionsGen, menuTabsOrder, showSettingsMenu} = require("settings_menu_state.nut")
let { save_changed_settings, get_setting_by_blk_path, set_setting_by_blk_path,
  remove_setting_by_blk_path } = require("settings")
let onlineSettingUpdated = require_optional("onlineStorage")
  ? require("%enlist/options/onlineSettings.nut").onlineSettingUpdated : null

let closeMenu = @() showSettingsMenu(false)

//====internal state
let foundTabsByOptionsGen = Watched(0)
let foundTabsByOptionsContainer = {value = []}
let getFoundTabsByOptions = @(...) foundTabsByOptionsContainer.value
let function setFoundTabsByOptions(v){
  foundTabsByOptionsContainer.value = v
  foundTabsByOptionsGen(foundTabsByOptionsGen.value+1)
}

let resultOptionsGen = Watched(0)
let resultOptionsContainer = {value = []}
let getResultOptions = @(...) resultOptionsContainer.value
let function resultOptions(v){
  resultOptionsContainer.value = v
  resultOptionsGen(resultOptionsGen.value+1)
}

let function setResultOptions(...){
  local optionsValue = getMenuOptions()
  let tabsInOptions = {}
  let isAvailableTriggers = optionsValue.filter(@(opt) opt?.isAvailableWatched!=null).map(@(opt) opt.isAvailableWatched)
  optionsValue = optionsValue.filter(@(opt) isOption(opt) && ((opt?.isAvailable==null && opt?.isAvailableWatched==null) || opt?.isAvailable() || opt?.isAvailableWatched.value))

  let res = []
  local lastSeparator = null
  let optionsStack = []

  foreach (opt in optionsValue) {
    if (opt?.tab != null ) {
      if (tabsInOptions?[opt.tab] == null)
        tabsInOptions[opt.tab] <- true
    }
    else {
      tabsInOptions["__unknown__"] <- true
    }

    if (opt?.isSeparator) {
      if (lastSeparator != null) {
        optionsStack.insert(0, lastSeparator)
        lastSeparator = null
      }
      res.extend(optionsStack)

      optionsStack.clear()
      lastSeparator = opt
    }
    else {
      optionsStack.append(opt)

      if (opt == optionsValue.top()) { //last option
        if (lastSeparator != null)
          res.append(lastSeparator)
        res.extend(optionsStack)
      }
    }
  }
  resultOptions(res)
  setFoundTabsByOptions(tabsInOptions.keys())
  foreach (i in isAvailableTriggers)
    i.subscribe(setResultOptions)
}
menuOptionsGen.subscribe(setResultOptions)
setResultOptions()

let function getResultTabs(foundTabsByOptionsValue, tabsOrder){
  let selectedTabs = []
  let ret = []
  foreach (tab in tabsOrder) {
    if (foundTabsByOptionsValue.indexof(tab?.id)!=null && selectedTabs.indexof(tab?.id)==null) {
      ret.append(tab)
      selectedTabs.append(tab.id)
    }
  }
  foreach (id in foundTabsByOptionsValue)
    if (tabsOrder.findindex(@(tab) tab?.id == id) == null)
      ret.append({id=id, text=loc(id)})
  return ret
}

let curTab = mkWatched(persist, "curTab")
let currentTab = mkWatched(persist, "currentTab", menuTabsOrder.value?[0].id)
menuTabsOrder.subscribe(function(v) {
  if (currentTab.value == null && v.len()>0)
    currentTab(menuTabsOrder.value?[0].id)
})

local function checkAndApply(available, val, defVal, blkPath) {
  if (available == null)
    return val

  if (available instanceof Watched)
    available = available.value
  if (typeof available != "array")
    available = [available]
  if (available.contains(val))
    return val

  logMenu($"{blkPath} absent value:", val, "default:", defVal, "available:", available)
  if (defVal != null)
    return defVal
  if (available.len() > 0)
    return available[0]

  logMenu($"{blkPath} absent value:", val, "no default values")
  return val
}

let convertForBlkByType = {
  float = @(v) v.tofloat()
  integer = @(v) v.tointeger()
  string = @(v) v.tostring()
  bool = @(v) !!v
}
let function applyGameSettingsChanges(optionsValue) { //FIX ME: should to divide ui and state logic in this file
  local needRestart = false
  let changedFields = []
  foreach (opt in optionsValue) {
    let { blkPath = null } = opt
    if (blkPath) {
      let { defVal = null } = opt
      let isEq = opt.isEqual
      local hasChanges = false
      local val = opt.var.value
      if ("convertForBlk" in opt)
        val = opt.convertForBlk(val)
      else if ("typ" in opt && opt.typ in convertForBlkByType) {
        try {
          let cval = convertForBlkByType[opt.typ](val)
          let { available = null } = opt
          let res = checkAndApply(available, cval, defVal, blkPath)
          if (!isEq(res, cval)) {
            val = res
            changedFields.append(blkPath)
          } else
            val = cval
        }
        catch(e) {
          logMenu("error in loading ", opt, e)
          val = defVal
          changedFields.append(blkPath)
        }
      }
      let blksettings = [{ blkPath, val, defVal }]
      if ("getMoreBlkSettings" in opt)
        blksettings.extend(opt.getMoreBlkSettings(opt.var.value))
      foreach (setting in blksettings) {
        logMenu(setting.blkPath, get_setting_by_blk_path(setting.blkPath), setting?.defVal, setting.val)
        if (!isEq(get_setting_by_blk_path(setting.blkPath) ?? setting?.defVal, setting.val) && setting.val != null) {
          //this is ugly hack in case value is incorrect type. Probably we can make better API in c++ or even squirrel, to remove all fields of different type
          if (type(get_setting_by_blk_path(setting.blkPath)) != type(setting.val))
            remove_setting_by_blk_path(setting.blkPath)
          set_setting_by_blk_path(setting.blkPath, setting.val)
          changedFields.append(setting.blkPath)
          hasChanges = true
        }
      }
      if (hasChanges && opt?.restart)
        needRestart = true
    }
  }
  if (changedFields.len() != 0) {
    logMenu("apply changes", changedFields)
    save_changed_settings(changedFields)
    apply_video_settings(changedFields)
    apply_audio_settings(changedFields)
  }
  return needRestart
}

let saveAndApply = @(onMenuClose, options) function() {
  let needRestart = applyGameSettingsChanges(options)
  onMenuClose()
  eventbus.send("onlineSettings.sendToServer", null)

  if (needRestart) {
    msgbox.show({text=loc("settings/restart_needed")})
  }
}

if (onlineSettingUpdated)
  onlineSettingUpdated.subscribe(
    @(val) val ? defer(@() applyGameSettingsChanges(getResultOptions())) : null
  )

resultOptionsGen.subscribe(@(_v) applyGameSettingsChanges(getResultOptions()))
applyGameSettingsChanges(getResultOptions())

let function mkSettingsMenuUi(menu_params) {
  let function close(){
    menu_params?.onClose()
    closeMenu()
  }
  return function(){
    let optionsValue = getResultOptions()
    let tabs = getResultTabs(getFoundTabsByOptions(), menuTabsOrder.value)
    return {
      size = flex()
      key = "settings_menu_root"
      onDetach = @() curTab(tabs?[0].id ?? "")
      function onAttach(){
        if ((curTab.value ?? "") == "")
          curTab(tabs?[0].id ?? "")
      }
      watch = [resultOptionsGen, currentTab, menuTabsOrder, foundTabsByOptionsGen]
      children = settingsMenuCtor({
        key = "settings_menu"
        size = [sw(70), sh(80)]
        options = optionsValue
        sourceTabs = tabs
        currentTab = currentTab
        onClose = close
        buttons = [
          { size=flex(), flow = FLOW_HORIZONTAL, children = menu_params?.leftButtons }
          textButton(loc("Ok"), saveAndApply(close, optionsValue), {
            hotkeys = [
              [$"^{JB.B} | J:Start | Esc", {action=saveAndApply(closeMenu, optionsValue), description={skip=true}}],
            ],
            skipDirPadNav = true
          })
        ]
        cancelHandler = @() null
      })
    }
  }
}
return {
  mkSettingsMenuUi
  showSettingsMenu
}
