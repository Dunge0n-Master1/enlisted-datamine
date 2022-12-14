from "%enlSqGlob/ui_library.nut" import *

let { globalWatched } = require("%dngscripts/globalState.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { reload_ui_scripts, reload_enlist_scripts } = require("app")

let { newDesign, newDesignUpdate } = globalWatched("newDesign", @() false)
let { enlistDirty, enlistDirtyUpdate } = globalWatched("enlistDirty", @() false)
let { battleDirty, battleDirtyUpdate } = globalWatched("battleDirty", @() false)
let { toggleDesign, toggleDesignUpdate } = globalWatched("toggleDesign", @() false)

isInBattleState.subscribe(function(inBattle) {
  if (inBattle && battleDirty.value) {
    battleDirtyUpdate(false)
    reload_ui_scripts()
  }
  if (!inBattle && enlistDirty.value) {
    enlistDirtyUpdate(false)
    reload_enlist_scripts()
  }
})

let function setDesign(isNew) {
  if (newDesign.value == isNew)
    return

  newDesignUpdate(isNew)
  if (isInBattleState.value) {
    enlistDirtyUpdate(true)
    reload_ui_scripts()
  } else {
    battleDirtyUpdate(true)
    reload_enlist_scripts()
  }
}

console_register_command(function() {
  let newToggle = !toggleDesign.value
  toggleDesignUpdate(newToggle)
  console_print($"New design option is {newToggle ? "on" : "off"}")
}, "ui.toggleDesign")

return {
  setToggleDesign = toggleDesignUpdate
  hasToggleDesign = toggleDesign
  isNewDesign = newDesign
  setDesign
}
