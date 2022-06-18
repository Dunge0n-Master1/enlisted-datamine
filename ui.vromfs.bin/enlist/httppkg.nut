from "%enlSqGlob/ui_library.nut" import *

let { platformId } = require("%dngscripts/platform.nut")
let { language } = require("%enlSqGlob/clientState.nut")

let platformMap = {
  win32 = "pc"
  win64 = "pc"
}

let languageMap = {
  Russian = "ru"
  English = "en"
  French = "fr"
  Italian = "it"
  German = "de"
  Spanish = "es"
  Korean = "ko"
  Japanese = "jp"
  Chinese = "zh"
}

return {
  getPlatformId = @() platformMap?[platformId] ?? platformId
  getLanguageId = @() languageMap?[language.value] ?? languageMap.English
}