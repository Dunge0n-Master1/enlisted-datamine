from "%enlSqGlob/ui_library.nut" import *


let {isOpenSteamLinkUrlInProgress, isSteamLinked, openSteamLinkUrl} = require("%enlist/state/steamState.nut")
let textButton = require("%ui/components/textButton.nut")
let faComp = require("%ui/components/faComp.nut")
let {TextDefault} = require("%ui/style/colors.nut")

let spinner = faComp("spinner", {
  key = "openSteamLinkInProgress"
  color = TextDefault
  size = [fontH(100),fontH(100)]
  transform = {}
  animations = [{ prop=AnimProp.rotate, from = 0, to = 360, duration = 1, play = true, loop = true, easing=Discrete8 }]
})
let function steamLinkBtn() {
  let res = { watch = [isSteamLinked, isOpenSteamLinkUrlInProgress] }
  if (isSteamLinked.value)
    return res

  return res.__update({
    vplace = ALIGN_CENTER
    children = isOpenSteamLinkUrlInProgress.value
      ? spinner
      : textButton(loc("gamemenu/btnLinkAccount"), openSteamLinkUrl, { skipDirPadNav = true })
  })
}

return steamLinkBtn
