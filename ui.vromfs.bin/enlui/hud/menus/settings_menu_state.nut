from "%enlSqGlob/ui_library.nut" import *

let menuOptionsGen = Watched(0)
let menuOptionsContainer = {value = []}
let getMenuOptions = @() menuOptionsContainer.value
let function setMenuOptions(options){
  menuOptionsContainer.value = options
  menuOptionsGen(menuOptionsGen.value+1)
}
let menuTabsOrder = Watched([])

return {
  setMenuOptions
  getMenuOptions
  menuOptionsGen
  menuTabsOrder
}