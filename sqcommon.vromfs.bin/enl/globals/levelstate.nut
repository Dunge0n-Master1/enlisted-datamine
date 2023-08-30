let {globalWatched} = require("%dngscripts/globalState.nut")
let {levelLoaded, levelLoadedUpdate} = globalWatched("levelLoaded", @() false)
let {levelIsLoading, levelIsLoadingUpdate} = globalWatched("levelIsLoading", @() false)
let {currentLevelBlk, currentLevelBlkUpdate} = globalWatched("currentLevelBlk", @() null)

return {
  levelIsLoading, levelIsLoadingUpdate,
  levelLoaded, levelLoadedUpdate,
  currentLevelBlk, currentLevelBlkUpdate
}