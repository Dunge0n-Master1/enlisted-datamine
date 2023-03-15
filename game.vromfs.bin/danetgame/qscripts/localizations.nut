let { logerr } = require("dagor.debug")
let { DBGLEVEL } = require("dagor.system")
let dagorLocalize = require("dagor.localize")
let nativeLoc = dagorLocalize.loc
let {doesLocTextExist} = dagorLocalize
let {memoize} = require("%sqstd/functools.nut")
let console = require("console")

let unlocalizedStrings = persist("unlocalizedStrings", @() {})
let defLocalizedStrings = persist("defLocalizedStrings", @() {})

let function locWithCheck(locId, defaultLoc=null, params = null){
  if (locId==null)
    return null
  foreach(v in [defaultLoc, params]) {
    if (type(v) == "string")
      defaultLoc = v
    else if (type(v) == "table")
      params = v
   }
  if (!doesLocTextExist(locId)){
    let {src=null, line=null} = getstackinfos(4)
    if (defaultLoc!=null && locId not in defLocalizedStrings)
      defLocalizedStrings[locId] <- {stack = src ? $"{src}:{line}" : "no stack", defaultLoc}
    else if (locId not in unlocalizedStrings)
      unlocalizedStrings[locId] <- $"{src}:{line}"
  }
  return nativeLoc(locId, defaultLoc, params)
}
let function hashLocFunc(locId, defLoc, params){
  if (type(defLoc)=="table")
    defLoc = defLoc.reduce(@(a,val, key) "_".concat(a, key, val), "")
  if (type(params)=="table")
    params = params.reduce(@(a,val, key) "_".concat(a, key, val), "")
  defLoc = defLoc ?? ""
  params = params ?? ""
  return $"{locId}{defLoc}{params}"
}
let persistLocCache = persist("persistLocCache", @(){})
let memoizedLoc = memoize(locWithCheck, hashLocFunc, persistLocCache)
let checkedLoc = @(locId, defLoc=null, params=null) memoizedLoc(locId, defLoc, params)
let debugLocalizations = DBGLEVEL > 0 && __name__ != "__main__" && "__argv" not in getroottable()

let function dumpLocalizationErrors(){
  let unlocalizedStringsN = unlocalizedStrings.len() + defLocalizedStrings.len()
  if (unlocalizedStringsN > 0) {
    logerr($"[LANG] {unlocalizedStringsN} strings has no localizations")
    print("[LANG] not localized strings\n")
    foreach(locId, stackinfo in unlocalizedStrings)
      if (stackinfo==null)
        print(locId)
      else
        print($"{locId}: {stackinfo}")
    print("[LANG] localized with default localizations\n")
    foreach(locId, info in defLocalizedStrings)
      print($"{locId}: defLoc = {info.defLoc}, stack = {info.stack}")
  }
}

console.register_command(dumpLocalizationErrors, "localization.checkErrors", "dump all unlocalized strings")

return {
  nativeLoc,
  locCheckWrapper = checkedLoc,
  loc = debugLocalizations ? checkedLoc : nativeLoc
}