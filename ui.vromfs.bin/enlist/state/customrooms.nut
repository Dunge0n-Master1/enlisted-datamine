from "%enlSqGlob/ui_library.nut" import *

let { roomIsLobby, setMemberAttributes} = require("%enlist/state/roomState.nut")

let attribs = {}

let function addAttrib(name, watched) {
  attribs[name] <- watched
  watched.subscribe(@(val) setMemberAttributes({ public = { [name] = val } }))
}

roomIsLobby.subscribe(function(val) {
  if (val && attribs.len() > 0)
    setMemberAttributes({ public = attribs.map(@(v) v.value) })
})

return {
  addAttrib
}

