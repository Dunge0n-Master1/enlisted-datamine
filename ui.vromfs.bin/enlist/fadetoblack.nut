from "%enlSqGlob/ui_library.nut" import *

/*
todo:
this is very dirty implementation. It doesnt work well with several fadeouts started
what we really need is on addFade combine all actions in one and perfrom them on first black time
like:
'first': toBlack = 0.5, out = 0.5, action = "actionName"
'second': toBlack = 0.7, out = 0.7, action = "actionName2", actionParams = <anyTypeHere>
result:
  toBlack = 0.5 inBlack=0.2 out =0.7, onBlack = do1();do2()
add onFullBlack, onBlackExit and onTime callbacks types (to do exactly onTime, onFullBlack and on startBlackOut)
probably the best way to do it is to do everything on poll (which we can start only if not empty fades)
*/

let { logerr } = require("dagor.debug")

let fadeState = mkWatched(persist, "fadeState", [])
let allActions = {}
let black = Color(0,0,0)
local counter = 0

let doFadeBlack = kwarg(function(fadein, fadeout=null, color = black, action = null, params = null, id = null) {
  counter++
  fadeState.mutate(@(value) value.append(
    { fadein, fadeout = fadeout ?? fadein, color, action, params, id = id ?? counter }))
})

let function registerFadeBlackActions(actions) {
  foreach (name, act in actions)
    if (name in allActions)
      logerr($"fadeToBlack: Try to register already exist action '{name}'")
    else
      allActions[name] <- act
}

let function removeFade(id) {
  let idx = fadeState.value.findindex(@(v) v.id==id)
  if (idx!=null)
    fadeState.mutate(@(fs) fs.remove(idx))
}

let function doAction(fs) {
  let { action = null, params = null } = fs
  let handler = allActions?[action]
  if (handler == null) {
    if (action != null)
      logerr($"fadeToBlack: Unknown action '{action}'")
    return
  }

  let {parameters, defparams} = handler.getfuncinfos()
  let paramCount = parameters.len()
  let defargsCount = defparams.len()
  if (paramCount == 1)
    handler()
  else if (paramCount == 2)
    handler(params)
  else if (paramCount > 2 && (paramCount-defargsCount) <= 2)
    handler(params)
  else {
    log($"fadeToBlack: paramCount: {paramCount}, defargsCount: {defargsCount}")
    logerr($"fadeToBlack: Try to do action {action} but it has wrong arguments count {paramCount}")
  }
}

let function doActionAndRemove(fs) {
  doAction(fs)
  removeFade(fs.id)
}

let mkFs = @(fs) {
  size = flex()
  key = fs.id
  color = fs?.color ?? black
  rendObj = ROBJ_SOLID
  onDetach = @() doActionAndRemove(fs)
  onAttach = @() gui_scene.setTimeout(fs?.fadein ?? 0.5, @() doActionAndRemove(fs))
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = fs?.fadein ?? 0.5, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = fs?.fadeout ?? 0.5, playFadeOut = true }
  ]
}

let fadeBlackUi = @() {
  watch = fadeState
  children = fadeState.value.map(mkFs)
  size = flex()
}

return {
  registerFadeBlackActions
  doFadeBlack
  fadeBlackUi
}