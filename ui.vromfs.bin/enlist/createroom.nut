from "%enlSqGlob/ui_library.nut" import *

from "%darg/laconic.nut" import *
from "modFiles.nut" import USER_MODS_FOLDER, MODS_EXT, BASE_URL, statusText, isStrHash

let { debounce } = require("%sqstd/timers.nut")
let eventbus = require("eventbus")
let json = require("json")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let {h2_txt, body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {checkMultiplayerPermissions} = require("permissions/permissions.nut")
let {createRoom} = require("state/roomState.nut")
let textButton = require("%ui/components/textButton.nut")
let textInput = require("%ui/components/textInput.nut")
let checkbox = require("%ui/components/checkbox.nut")
let msgbox = require("components/msgbox.nut")
let { strip } = require("string")
let {showCreateRoom} = require("mpRoom/showCreateRoom.nut")
let comboBox = require("%ui/components/combobox.nut")
let {oneOfSelectedClusters} = require("clusterState.nut")
let matching_errors = require("matching.errors")
let {groupSize, botsPopulation, botAutoSquad, game, scenes, scene, roomName, minPlayers, maxPlayers, startOffline, writeReplay} = require("roomSettings.nut")
let {startGame} = require("gameLauncher.nut")
let {get_app_id, set_matching_invite_data} = require("app")
let JB = require("%ui/control/gui_buttons.nut")
let {mkSelectWindow, mkOpenSelectWindowBtn} = require("%enlist/components/selectWindow.nut")
let {scan_folder, file_exists} = require("dagor.fs")
let {request_ugm_manifest} = require("game_load")
let { logerr } = require("dagor.debug")
let http = require("dagor.http")
let spinner = require("%ui/components/spinner.nut")({height=hdpx(80)})
let {getBaseFromManifestUrl, getHashesFromManifest, requestModFiles} = require("%enlSqGlob/game_mods.nut")
let { send_counter } = require("statsd")

const EVENT_MOD_VROM_INFO = "mod_info_vrom_loaded"
let playersAmountList = [1, 2, 4, 8, 12, 16, 20, 24, 32, 40, 50, 64, 70, 80, 100, 128]
let groupSizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


let usePassword = mkWatched(persist, "usePassword", false)
let password = mkWatched(persist, "password", "")
let focusedField = Watched(null)

let function createRoomCb(response) {
  if (response.error != 0) {
    roomName.update("")
    password.update("")

    msgbox.show({
      text = loc("customRoom/failCreate", {responce_error=matching_errors.error_string(response?.error_id ?? response.error)})
    })
  }
}

let function availableFields() {
  return [
    roomName,
    usePassword,
    startOffline,
    (usePassword.value ? password : null),
  ].filter(@(val) val)
}

let function checkAvailableFields(){
  local isValid = true

  foreach (f in availableFields()) {
    if (typeof(f.value)=="string" && !strip(f.value).len()) {
      anim_start(f)
      isValid = false
      break
    }
  }
  return isValid
}

let modPath = mkWatched(persist, "modPath", "")
let urlToManifest = mkWatched(persist, "urlToManifest", "")

let manifest = Watched(null)
let MANIFEST_EVENT = "MANIFEST_EVENT"
let function requestManifest(url) {
  manifest(null)
  http.request({
    method = "GET"
    url
    respEventId = MANIFEST_EVENT
    context = url
  })
}
eventbus.subscribe(MANIFEST_EVENT, tryCatch(function(response){
  let { status, http_code } = response
  if (status != http.SUCCESS || http_code == null
      || http_code < 200 || 300 >= http_code) {
    send_counter("manifest_request_receive_errors", 1, { http_code })
    log("status = ", statusText?[status], "http_code = ", http_code)
    throw("haven't received manifest")
  }
  let man = json.parse(response.body.as_string())
  manifest(man)
},function(e) {
  log(e)
  log_for_user("Error loading manifest for url")
  manifest(null)
})
)

let requestModByUrl = debounce(function(...){
  let v = urlToManifest.value
  if (v!="")
    requestManifest(v)
  else
    manifest(null)
}, 0.3)

urlToManifest.subscribe(requestModByUrl)
requestModByUrl()

let baseModsFilesUrl = Computed(@() getBaseFromManifestUrl(urlToManifest.value))
let modFilesHashes = Computed(function(){
  if (urlToManifest.value == "" || manifest.value==null)
    return []
  return getHashesFromManifest(manifest.value)
})
const FILE_EXISTS_ON_SERVER_EVENT = "FILE_EXISTS_ON_SERVER_EVENT"
const FAILED = "FAILED"
const WAITING = "WAITING"
const SUCCESS = "SUCCESS"

let function reqFileHeaders(hash){
  let url = $"{BASE_URL}{hash}"
  http.request({
    method = "HEAD"
    url
    respEventId = FILE_EXISTS_ON_SERVER_EVENT
    context = hash
  })
}

let hashesStatus = Watched({})

let function setCurHashesStatus(...){
  let hashes = modFilesHashes.value
  let res = clone hashesStatus.value
  foreach (hash in hashes){
    if (res?[hash] == WAITING || res?[hash] == SUCCESS)
      continue
    if (!isStrHash(hash)) {
      res[hash] <- FAILED
      continue
    }
    if (hash not in res)
      res[hash] <- WAITING
    reqFileHeaders(hash)
  }
  let toDelete = []
  foreach (hash, value in res){
    if (!hashes.contains(hash)) {
      if (!(value==SUCCESS || value==WAITING))
        toDelete.append(hash)
    }
  }
  toDelete.each(@(v) delete res[v])
  hashesStatus(res)
}
modFilesHashes.subscribe(setCurHashesStatus)
setCurHashesStatus()

eventbus.subscribe(FILE_EXISTS_ON_SERVER_EVENT, function(response){
  let hash = response?.context
  if (hash==null || hash == "")
    return
  try{
    let { status, http_code } = response
    if (status != http.SUCCESS || http_code == null
      || http_code < 200 || 300 >= http_code) {
      send_counter("file_request_receive_errors", 1, { http_code })
      log($"couldn't get file '{hash}' data from live,  request status = ", statusText?[status], "http_code =", http_code)
      if (modFilesHashes.value.contains(hash))
        hashesStatus.mutate(@(v) v[hash]<-FAILED)
      else if (hash in hashesStatus.value)
        hashesStatus.mutate(@(v) delete v[hash])
      return
    }
    hashesStatus.mutate(@(v) v[hash] <- SUCCESS)
  }
  catch(e){
    log("error on hash", hash)
    log(e)
    logerr("unable to check status of file on server")
  }
})

let curModHashesStatus = Computed(@() hashesStatus.value.filter(@(v) v == FAILED).len()>0
  ? FAILED
  : hashesStatus.value.filter(@(v) v == WAITING || v == null).len()>0
    ? WAITING
    : SUCCESS
)
let curModHashesOk = Computed(@() curModHashesStatus.value == SUCCESS)
let curModHashesWaiting = Computed(@() curModHashesStatus.value == WAITING)


let receivedModInfos = Watched({})

let function jsonSafeParse(v){
  if (v=="")
    return null
  try{
   return json.parse(v)
  }
  catch(e) {
    logerr(e)
    return null
  }

}

let noModeInfo = freeze({NoModeInfo=null})
eventbus.subscribe(EVENT_MOD_VROM_INFO, function(info) {
  if (info?.result!=1)
    return
  let {manifestStr, contentId, modFiles, sceneBlkFound, vromfs} = info
  receivedModInfos(receivedModInfos.value.__merge({[vromfs] = {manifestFromFile = jsonSafeParse(manifestStr), contentId, modFiles, sceneBlkFound, vromfs}}))
})

let function getFname(mpath){
  local filename = mpath
  let pathSplit = mpath.split("/")
  if (pathSplit.len()!=1) {
    filename = pathSplit[pathSplit.len()-1]
  }
  return filename
}

let NOUSE = @(...) null

let function getModInfo(mpath) {
  if (mpath == "")
    return noModeInfo
  if (!file_exists(mpath))
    return noModeInfo
  let mod = receivedModInfos.value?[mpath]
  let {contentId=null, vromfs=null, manifestFromFile=null, sceneBlkFound=false} = mod
  local titles = manifest?.title_localizations ?? {}
  titles = titles.__merge({title = manifestFromFile?.title ?? contentId})
  let title = titles?[gameLanguage] ?? titles?.title ?? contentId
  let fname = getFname(mpath).slice(0, -MODS_EXT.len())

  let sceneInMode = sceneBlkFound ? "scene.blk" : null
  if (contentId==null || sceneInMode==null || vromfs==null) {
    return noModeInfo
  }
  let pathToStart = $"?{vromfs}?*?{sceneInMode}"
  return {contentId, sceneInMode, pathToStart, title, titles, fname}
}

let allModInfos = Computed(@() receivedModInfos.value.map(@(_, v) getModInfo(v)))

let modInfo = Computed(function(){
  if (urlToManifest.value != "")
  NOUSE(receivedModInfos.value?[modPath.value])
  return getModInfo(modPath.value)
})

let requestUgmForCurMod = debounce(function() {
    let mpath = modPath.value
    request_ugm_manifest(mpath, EVENT_MOD_VROM_INFO)
  }, 0.1)

modPath.subscribe(@(_) requestUgmForCurMod())
requestUgmForCurMod()

let function modName(v) {
  if ((v??"")=="")
    return loc("NO MODE")
  else{
    return (getModInfo(v)?.title ?? $"!incorect file! {getFname(v)}")
  }
}

let modPathToStart = Computed(function() {
  if (modInfo.value == noModeInfo)
    return ""
  return modInfo.value?.pathToStart ?? ""
})

let isSelectedModCorrect = Computed(function(){
  return (modInfo.value?.pathToStart!=null) || modInfo.value == noModeInfo
})

let function doCreateRoom() {
  if (!checkMultiplayerPermissions()) {
    log("no permissions to create lobby")
    return
  }
  let isValid = checkAvailableFields()

  if (isValid) {
    let offline = startOffline.value
    local scenePath = scene.value?.id
    local mod = ""
    local modTitles = {}

    if (manifest.value != null && urlToManifest.value!="" && curModHashesOk.value){
      try{
        log("title_localizations", manifest.value?.title_localizations)
        modTitles = {title = manifest.value?.title ?? "untitled"}//.__merge(manifest.value?.title_localizations ?? {})
        mod = manifest?.title ?? urlToManifest.value
      }
      catch(e)
        log_for_user(e)
    }
    else if (isSelectedModCorrect.value && modInfo.value != noModeInfo){
      scenePath = modPathToStart.value
      mod = modInfo.value?.contentId ?? ""
      modTitles = modInfo.value?.titles ?? {}
    }
    let params = {
      public = {
        maxPlayers = maxPlayers.value
        roomName = strip(roomName.value)
        gameName = game.value
        scene = urlToManifest.value == "" ? scenePath : ""
        cluster = oneOfSelectedClusters.value
        appId = get_app_id()
        groupSize = groupSize.value
        //modManifestUrl = urlToManifest.value
        baseModsFilesUrl = baseModsFilesUrl.value
        modTitles
        modHash = ";".join(modFilesHashes.value ?? [])
        mod
      },
      lobby_template = "dev-lobby"
    }
    if (usePassword.value && password.value)
      params.password <- strip(password.value)
    if (botsPopulation.value > 0)
      params.public.botpop <- botsPopulation.value

    if (botAutoSquad.value)
      params.public.botAutoSquad <- botAutoSquad.value

    if (writeReplay.value)
      params.public.writeReplay <- true

    if (!offline){
      createRoom(params, createRoomCb)
    }
    else {
      set_matching_invite_data({ mode_info = params.public })
      if (manifest.value != null) {
        if (curModHashesOk.value){
          let modFileName = modFilesHashes.value?[0]
          requestModFiles([modFileName], baseModsFilesUrl.value, function(vroms){
            let blob = vroms?[0]
            if (blob==null) {
              msgbox.show({text = "Mod files haven't been downloaded or incorrect"})
              return
            }
            startGame({scene = "scene.blk", modFile = blob})
          })
        }
        else
          msgbox.show({ text = "Mod files haven't been downloaded"})
      }
      else if (isSelectedModCorrect.value && modPath.value!=""){
        startGame({scene = "scene.blk", modFile = modPath.value})
      }
      else {
        startGame({scene = scenePath})
      }
    }
  }
}

let function makeFormItemHandlers(field) {
  return {
    onFocus = @() focusedField.update(field)
    onBlur = @() focusedField.update(null)
    onAttach = function(elem) {
      let focusOn = focusedField.value
      if (focusOn && field == focusOn)
        set_kb_focus(elem)
    }

    onReturn = doCreateRoom
  }
}

let function formText(params) {
  let options = {
    placeholder = params?.placeholder ?? ""
  }.__update(params, makeFormItemHandlers(params.state))
  return textInput(params.state, options)
}


let function formCheckbox(params={}) {
  return checkbox(params.state, params?.name, makeFormItemHandlers(params.state))
}

let titletxt = @(title){
  rendObj = ROBJ_TEXT
  text = title
  color = Color(180,180,180)
  vplace = ALIGN_CENTER
  size=[flex(), fontH(180)]
}.__update(sub_txt)

let formComboWithTitle = @(watch, values, title) {
  size=[flex(), fontH(180)]
  flow = FLOW_HORIZONTAL
  margin = hdpx(2)
  children = [
    titletxt(title)
    {
      size = [fontH(650), fontH(180)]
      hplace = ALIGN_RIGHT
      halign = ALIGN_RIGHT
      children = comboBox(watch, values)
    }
  ]
}.__update(body_txt)

let humanTitle = @(scn) (scn?.title ?? "_untitled_").replace(".blk", "")


let filterSceneStr = Watched("")
let filteredScenes = Computed( function() {
  let fltr = (filterSceneStr.value ?? "").tolower()
  if (fltr=="")
    return scenes.value
  else
    return scenes.value.filter(@(v) (v?.title ?? "").tolower().contains(fltr) || (v?.id ?? "").tolower().contains(fltr))
})

let openScenesMenu = mkSelectWindow({
  uid = "scenes_selector",
  optionsState = filteredScenes,
  state = scene,
  title = loc("SELECT SCENE"),
  filterPlaceHolder=loc("filter scene")
  filterState = filterSceneStr
  mkTxt = humanTitle
  titleStyle = h2_txt
})

let selectSceneBtn = mkOpenSelectWindowBtn(scene, loc("Current scene"), openScenesMenu, humanTitle)

let gameMods = Watched([])

let resultGameMods = Computed(function(){
  let res = [""]
  let infos = allModInfos.value

  foreach (m in gameMods.value){
    if (m in infos){
      res.append(m)
    }
  }
  return res
})
let filterMods = Watched("")

let openModsWindow = mkSelectWindow({
  uid = "MODS_WND"
  optionsState = resultGameMods,
  state = modPath,
  title = loc("select game mod from 'userMods' folder"),
  filterPlaceHolder=loc("filter mods")
  filterState = filterMods
  onAttach = function() {
    let mods = scan_folder({root=USER_MODS_FOLDER, vromfs = false, realfs = true, recursive = false, files_suffix=MODS_EXT})
    gameMods(mods)
    foreach (m in mods) {
      request_ugm_manifest(m, EVENT_MOD_VROM_INFO)
    }
  }
  titleStyle = h2_txt
  mkTxt = modName
})

let selectModBtn = mkOpenSelectWindowBtn(modPath, loc("local game mod"), openModsWindow, modName)
let gameBtnHgt = calc_comp_size(selectModBtn)[1]

let urlToManifestComp = textInput(urlToManifest, {placeholder = loc("URL of manifest")})

let closeRoomBtn = textButton(loc("Close"), function() {showCreateRoom.update(false)}, {hotkeys=[[$"^{JB.B} | Esc"]]})
let createRoomBtn = textButton(loc("Create"), doCreateRoom, {hotkeys=[["^J:X"]]})

let function createRoomWnd() {
  local selectScene = {size=[0, gameBtnHgt]}
  if (urlToManifest.value != "" && manifest.value != null)
    selectScene = titletxt(manifest.value?.title)
  else if (modPathToStart.value == "" && modPath.value == "")
    selectScene = selectSceneBtn
  return {
    size = [fsh(40), sh(60)]
    pos = [0, sh(20)]
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    key = "create-room"
    watch = [usePassword, game, urlToManifest, modPathToStart, modPath, manifest]
    children = [
      {
        flow = FLOW_VERTICAL
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          urlToManifest.value == "" ? selectModBtn : {size=[0, gameBtnHgt]},
          modPath.value == "" ? urlToManifestComp : null,
          selectScene,
          formComboWithTitle(minPlayers, playersAmountList, loc("players to start")),
          formComboWithTitle(maxPlayers, playersAmountList, loc("Max players")),
          formComboWithTitle(botsPopulation, [0].extend(playersAmountList), loc("Bots population")),
          formCheckbox({state=botAutoSquad, name=loc("customRoom/botAutoSquad", "Fill the group with bots.")}),
          formComboWithTitle(groupSize, groupSizes, loc("Group size")),
          formText({state=roomName, placeholder = loc("customRoom/roomName_placeholder")}),
          modPath.value == "" ? formCheckbox({state=startOffline, name=loc("customRoom/startOffline")}) : titletxt(loc("customRoom/startOffline")),
          formCheckbox({state=usePassword, name=loc("customRoom/usePassword")}),
          (usePassword.value
            ? formText({state=password placeholder=loc("password_placeholder","password") password="\u25CF"})
            : null),
          formCheckbox({state=writeReplay, name=loc("customRoom/writeReplay")})
        ]
      }
      function() {
        let children = [closeRoomBtn]
        if (modInfo.value==noModeInfo)
          children.append(createRoomBtn)
        else if (!isSelectedModCorrect.value)
          children.append(txt(loc("incorrectMod")))
        else if (startOffline.value || curModHashesOk.value)
          children.append(createRoomBtn)

        if (curModHashesWaiting.value)
          children.append(spinner)
        else if (!curModHashesOk.value)
          children.append(txt(loc("modFilesAreNotAvailableOnline")))

        return {
          size = SIZE_TO_CONTENT
          watch = [isSelectedModCorrect, modInfo, curModHashesOk, curModHashesWaiting, startOffline]
          vplace = ALIGN_BOTTOM
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          children
        }
      }
    ]
  }
}

return createRoomWnd
