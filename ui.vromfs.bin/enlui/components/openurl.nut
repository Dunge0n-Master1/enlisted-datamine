from "%enlSqGlob/ui_library.nut" import *

let {shell_execute} = require("dagor.shell")
let {startswith, strip} = require("string")
let {get_authenticated_url_sso=null, get_kongzhong_authenticated_url, YU2_OK} = require("auth")
let steam = require("steam")
let platform = require("%dngscripts/platform.nut")
let regexp2 = require("regexp2")
let eventbus = require("eventbus")
let { get_setting_by_blk_path } = require("settings")
let { showBrowser } = require("browserWidget.nut")
let logOU = require("%enlSqGlob/library_logs.nut").with_prefix("[OPEN_URL] ")
let wegame = require("wegame")
let { getStoreUrl, getEventUrl, getPremiumUrl, getBattlePassUrl, getSquadCashUrl } = require("%ui/networkedUrls.nut")

let openLinksInEmbeddedBrowser = get_setting_by_blk_path("openLinksInEmbeddedBrowser") ?? false
let useKongZhongOpenUrl = get_setting_by_blk_path("useKongZhongOpenUrl") ?? false

let requestQueue = {}
local requestAuth = null

let function open_url(url) {
  if (type(url)!="string" || (!startswith(url, "http://") && !startswith(url, "https://")))
    return false
  if (platform.is_sony)
    require("sony.www").open(url, "" , {})
  else if (platform.is_xbox)
    require("xbox.app").launch_browser(url)
  else if (platform.is_pc) {
    if (openLinksInEmbeddedBrowser)
      showBrowser(url)
    else
      shell_execute({file=url})
  }
  else if (platform.is_android)
    shell_execute({file=url, cmd="action"})
  else
    log_for_user("Open url not implemented on this platform")
  return true
}

const URL_ANY_ENDING = @"(\/.*$|\/$|$)"
const AUTH_TOKEN_HOST = "https://login.gaijin.net/sso/getShortToken"

let addEnding = @(url) $"{url}{URL_ANY_ENDING}"

let urlTypes = [
  {
    typeName = "marketplace"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/trade\.gaijin\.net")),
      regexp2(addEnding(@"^https?:\/\/store\.gaijin\.net")),
      regexp2(addEnding(@"^https?:\/\/inventory-test-01\.gaijin\.lan")),
    ]
  },
  {
    typeName = "steam_market"
    autologin = false
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/store\.steampowered\.com"))
    ]
  },
  {
    typeName = "gaijin_support"
    autologin = true
    ssoService = "zendesk"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/support\.gaijin\.net"))
    ]
  },
  {
    typeName = "enlisted_forum"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/forum\.enlisted\.net"))
    ]
  },
  {
    typeName = "bugreport"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/community\.gaijin\.net\/issues"))
    ]
  },
  {
    typeName = "gss"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/gss\.gaijin\.net"))
    ]
  },
  {
    typeName = "replays"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(@"^https:\/\/enlisted\.net\/replays"))
    ]
  },
  {
    typeName = "kongzhong"
    autologin = true
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/.*kongzhong\.com")),
      regexp2(addEnding(@"^https?:\/\/.*zhanhuo\.com"))
    ]
  },
  {
    typeName = "match any url"
    autologin = false
    urlRegexpList = null
  },
]

let function getUrlTypeByUrl(url) {
  foreach (urlType in urlTypes) {
    if (!urlType.urlRegexpList)
      return urlType

    foreach (r in urlType.urlRegexpList)
      if (r.match(url))
        return urlType
  }

  return null
}


let function isWegameLoginRequiredUrl(url) {
  if (!wegame.is_running())
    return false

  return url == getStoreUrl() || url == getEventUrl() || url == getPremiumUrl() ||
    url == getBattlePassUrl() || url == getSquadCashUrl()
}


let function processQueue() {
  if (requestQueue.len() == 0) {
    logOU("Queue is empty")
    return
  }
  if (requestAuth != null) {
    logOU($"Processing {requestAuth}")
    return
  }

  let self = callee()
  requestAuth = requestQueue.findindex(@(_) true)
  let { baseUrl, goToUrl, ssoService = null } = requestQueue[requestAuth]
  eventbus.subscribe_onehit(requestAuth,
    function(result)  {
      delete requestQueue[requestAuth]
      requestAuth = null
      if (result.status == YU2_OK) {
        // use result.url string
        logOU($"Authenticated Url = {result.url}")
        goToUrl(result.url)
      }
      else {
        logOU($"Error: failed to get_authenticated_url, status = {result.status}")
        goToUrl(baseUrl) // anyway open url without authentication
      }
      self()
    }
  )

  if (!useKongZhongOpenUrl) {
    if (ssoService == null || get_authenticated_url_sso == null) {
      logOU($"Error: failed to get_authenticated_url_sso, service is undefined")
      goToUrl(baseUrl) // anyway open url without authentication
      delete requestQueue[requestAuth]
      requestAuth = null
      self()
    }
    else
      get_authenticated_url_sso(baseUrl, AUTH_TOKEN_HOST, ssoService, requestAuth)
  }
  else if (isWegameLoginRequiredUrl(baseUrl))
    wegame.get_authenticated_url(baseUrl, requestAuth)
  else
    get_kongzhong_authenticated_url(baseUrl, requestAuth)
}


let function openUrl(baseUrl, isAlreadyAuthenticated = false, shouldExternalBrowser = false, goToUrl = null) {
  let url = baseUrl ? strip(baseUrl) : ""
  if (url == "") {
    logOU("Error: tried to openUrl an empty url")
    return
  }

  let urlType = getUrlTypeByUrl(url)
  logOU($"Open type<{urlType.typeName}> url: {url}")
  logOU($"Base Url = {baseUrl}")

  if (goToUrl == null)
    goToUrl = (!shouldExternalBrowser && steam.is_overlay_enabled()) ? steam.open_url : open_url

  if (urlType.typeName == "steam_market" && !steam.is_overlay_enabled())
    logOU("Warning: trying to open steam url without steam overlay")

  if (isAlreadyAuthenticated || !urlType.autologin) {
    logOU($"Direct Url = {url}")
    goToUrl(url)
    return
  }

  let cbEvent = $"openUrl.{url}"
  if (cbEvent in requestQueue) {
    logOU("Already queued")
    return
  }

  let queuedData = urlType.__merge({ baseUrl, goToUrl })
  logOU("Queued data:", queuedData)
  requestQueue[cbEvent] <- queuedData
  processQueue()
}

console_register_command(open_url, "app.open_url")

return openUrl
