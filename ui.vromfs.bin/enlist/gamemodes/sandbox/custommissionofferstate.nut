from "%enlSqGlob/ui_library.nut" import *

let { body_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let http = require("dagor.http")
let json = require("json")
let { showWithCloseButton } = require("%enlist/components/msgbox.nut")
let { noteTextArea, txt } = require("%enlSqGlob/ui/defcomps.nut")
let { requestModManifest } = require("customMissionState.nut")
let openCustomMissionWnd = require("customMissionWnd.nut")
let { isEditEventRoomOpened } = require("%enlist/gameModes/createEventRoomState.nut")
let { isEventModesOpened, curTab } = require("%enlist/gameModes/eventModesState.nut")
let { logerr } = require("dagor.debug")
let { titleTxtColor, accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { is_pc } = require("%dngscripts/platform.nut")


let featuredMods = Watched([])
let featuredModsRoomsList = Watched([])
let needOpenModsList = Watched(false)
let urlData = "cdn_uris=true&clean_description=true&no_file=true&only_preview=true&charset=UTF-8&content-type=application/x-www-form-urlencoded"
let isFeaturedAvailable = is_pc
let isFeaturedRequestNeeded = keepref(Computed(@() isFeaturedAvailable && isEventModesOpened.value
  && featuredMods.value.len() == 0))

const FEATURED_MODS_TAB_ID = "featured_mod"
const URL = "https://sandbox.enlisted.net/api/feed/get_featured/"
const MOD_DOWNLOAD_URL = "https://sandbox.enlisted.net/post/{0}/manifest/{1}/"
const MOD_URL = "https://sandbox.enlisted.net/post/{0}"


let function getfeaturedModInfo(mod) {
  let isInvalidData = mod.findvalue(@(v) v == null)
  if (isInvalidData)
    return null
  let { description, preview, title, author, id, version } = mod
  let imageToShow = preview.split("?")[0]
  let modUrl = MOD_URL.subst(id)
  return {
    description
    imageToShow
    title
    authorsNick = author.nick
    id
    version
    modUrl
  }
}


let function requestCb(response) {
  try {
    let mods = (json.parse(response.body?.as_string())?.data.list ?? [])
      .map(@(v) getfeaturedModInfo(v))
    featuredMods(mods)
  }
  catch (e) {
    logerr("unable to parse featured mods request")
  }
}

let function requestMods(data = urlData) {
  http.request({
    method = "POST"
    url = URL
    callback = @(response) requestCb(response)
    data
  })
}


if (isFeaturedRequestNeeded.value)
  requestMods()
isFeaturedRequestNeeded.subscribe(@(v) v ? requestMods() : null)


let function offersModMsgbox(mod) {
  let { description, title, authorsNick, id, version, modUrl } = mod
  let  buttons = Computed(function(){
    let res = [
      {
        text = loc("mods/modOnSite")
        action = @() openUrl(modUrl)
      }
      {
        text = loc("downloadMission")
        action = function() {
          isEditEventRoomOpened(true)
          requestModManifest(MOD_DOWNLOAD_URL.subst(id, version))
          openCustomMissionWnd()
        }
      }
      { text = loc("Cancel") }
    ]
    if (curTab.value != FEATURED_MODS_TAB_ID && featuredModsRoomsList.value.len() > 0)
      res.insert(0, {
        text = loc("mods/featuredModsList")
        action = @() curTab(FEATURED_MODS_TAB_ID)
      })
    return res
  })

  showWithCloseButton({
    uid = title
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      maxWidth = min(sw(80), hdpx(1000))
      gap = fsh(2)
      valign = ALIGN_CENTER
      children = [
        txt({ text = loc("featured_mod")}).__update(h2_txt, { color = accentTitleTxtColor})
        noteTextArea({ text = title }).__update(h2_txt, { color = titleTxtColor })
        noteTextArea({ text = loc("mods/featuring") }).__update(body_txt)
        noteTextArea({ text = loc("mods/authorModDescription", { description = colorize(titleTxtColor, description) }) })
          .__update(body_txt, { color = accentTitleTxtColor })
        noteTextArea({ text = loc("mods/author", { author = colorize(titleTxtColor, authorsNick) }) })
          .__update(body_txt, { color = accentTitleTxtColor })
      ]
    }
    buttons
  })
}

let function updateUrlData(params = null) {
  if (params == null)
    requestMods(urlData)
  let updatedUrlData = $"{urlData}&{params}"
  requestMods(updatedUrlData)
}

console_register_command(@() updateUrlData(), "featuredMods.current")
console_register_command(@() updateUrlData("with_done=true"), "featuredMods.past")
console_register_command(@() updateUrlData("with_pending=true"), "featuredMods.future")


return {
  featuredMods
  offersModMsgbox
  needOpenModsList
  FEATURED_MODS_TAB_ID
  featuredModsRoomsList
  isFeaturedAvailable
}