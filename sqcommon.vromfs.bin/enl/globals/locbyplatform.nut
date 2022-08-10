let {loc} = require("%dngscripts/localizations.nut")
let { platformId } = require("%dngscripts/platform.nut")
let { doesLocTextExist } = require("dagor.localize")

let function locByPlatform(locId, ...) {
  local params = null
  local defLocId = locId
  foreach (v in vargv)
    if (type(v) == "string")
      defLocId = v
    else if (type(v) == "table")
      params = v

  let locPlatformId = $"{locId}/{platformId}"
  if (doesLocTextExist(locPlatformId))
    return loc(locPlatformId, params)
  return loc(locId, params, defLocId)
}

return locByPlatform