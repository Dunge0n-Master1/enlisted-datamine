from "%enlSqGlob/ui_library.nut" import *

let {secondsToHoursLoc} = require("%ui/helpers/time.nut")

//better to generate description by params, but yet it will by just simple lang

let locKeyByName = {
  //  as example
  //  daily_kills = "kills"
}

let requiredTime = @(progress) progress.__merge({
  current = secondsToHoursLoc(progress.current)
  required = secondsToHoursLoc(progress.required)
})

let customLocParams = {
  battle_time = requiredTime
}


local function getProgressLoc(unlockDesc, progress) {
  let {name} = unlockDesc
  let locKey = locKeyByName?[name] ?? name

  if (unlockDesc?.meta?.descProgressDiv && progress?.required != null && progress?.current != null) {
    progress = clone progress
    progress.current = (progress.current / unlockDesc.meta.descProgressDiv.tointeger())
    progress.required = (progress.required / unlockDesc.meta.descProgressDiv.tointeger())
  }
  if (locKey in customLocParams)
    return customLocParams[locKey](progress)
  return progress
}

let getDescription = kwarg(function(unlockDesc, progress, locId = null, locParams = null) {
  let progressLoc = getProgressLoc(unlockDesc, progress)
  if (locId != null) {
    let localization = loc(locId, progressLoc)
    if (localization != locId)
      return localization
  }

  local descLocId = $"unlock/{unlockDesc.name}/desc"
  if (progress.required == 1)
    descLocId = $"{descLocId}/single"

  let localization = loc(descLocId, progressLoc)
  if (localization != descLocId)
    return localization

  if (unlockDesc?.localization.nameLocId != null)
    return loc(unlockDesc.localization.nameLocId, locParams ?? unlockDesc?.locParams ?? {})

  return (unlockDesc?.localization?.name ?? "").len() > 0
    ? unlockDesc?.localization?.name
    : unlockDesc.name
})

return {
  getDescription
  getProgressLoc
}
