let {dgs_get_settings} = require("dagor.system")

let function extractDomainName(url) {
  let protocolIndex = url.indexof("://")
  if (protocolIndex != null)
    url = url.slice(protocolIndex + 3/*://*/)

  let pathIndex = url.indexof("/")
  if (pathIndex != null)
    url = url.slice(0, pathIndex)

  return url
}

let MOD_BASE_URL = dgs_get_settings()?.mods_server_addr ?? "https://enlisted-sandbox.gaijin.net/"
let MOD_DOMAIN_NAME = extractDomainName(MOD_BASE_URL)
let MOD_FILE_URL = "".concat(MOD_BASE_URL, "file/{0}")
let MOD_BY_VERSION_URL = "".concat(MOD_BASE_URL, "post/{0}/manifest/{1}/")
let MOD_LATEST_URL = "".concat(MOD_BASE_URL, "post/{0}")
const USER_MODS_FOLDER = "userGameMods"
const USER_MOD_MANIFEST_EXT = ".json"

return {
  MOD_DOMAIN_NAME
  MOD_BASE_URL
  MOD_FILE_URL
  MOD_BY_VERSION_URL
  MOD_LATEST_URL
  USER_MODS_FOLDER
  USER_MOD_MANIFEST_EXT
}
