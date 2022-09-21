let {globalWatched} = require("%dngscripts/globalState.nut")

let {planeControlModeState, planeControlModeStateUpdate} = globalWatched("planeControlModeState", @() null)

return {planeControlModeState, planeControlModeStateUpdate}