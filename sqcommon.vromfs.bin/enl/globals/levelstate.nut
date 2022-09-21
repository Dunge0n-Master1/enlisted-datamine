let {globalWatched} = require("%dngscripts/globalState.nut")
let {levelLoaded, levelLoadedUpdate} = globalWatched("levelLoaded", @() false)
let {levelIsLoading, levelIsLoadingUpdate} = globalWatched("levelIsLoading", @() false)

return {
  levelIsLoading, levelIsLoadingUpdate,
  levelLoaded, levelLoadedUpdate
}