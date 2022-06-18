from "%enlSqGlob/ui_library.nut" import *

//this is hack to add any components to hotkeysPanel. format is {key1 = component1, key2 = component2}
//problem that order is not guaranteed
let hotkeysPanelComps = {value={}}
let hotkeysPanelCompsGen = Watched(0)
let getHotkeysComps = @() hotkeysPanelComps.value ?? {}
let function setHotkeysComps(comps){
  hotkeysPanelComps.value = comps
  hotkeysPanelCompsGen(hotkeysPanelCompsGen.value+1)
}
let function removeHotkeysComp(id){
  if (id not in hotkeysPanelComps.value)
    return
  delete hotkeysPanelComps.value[id]
  hotkeysPanelCompsGen(hotkeysPanelCompsGen.value+1)
}
let function addHotkeysComp(id, comp){
  hotkeysPanelComps.value[id] <- comp
  hotkeysPanelCompsGen(hotkeysPanelCompsGen.value+1)
}

return {
  setHotkeysComps, hotkeysPanelCompsGen, getHotkeysComps, removeHotkeysComp, addHotkeysComp
}