from "%enlSqGlob/ui_library.nut" import *

let gameHuds = {value = null}
let gameHudGen = Watched(0)
return {
  function setGameHud(val) {
    gameHuds.value = val
    gameHudGen(gameHudGen.value+1)
  }
  getGameHud = @() gameHuds.value
  gameHudGen
}