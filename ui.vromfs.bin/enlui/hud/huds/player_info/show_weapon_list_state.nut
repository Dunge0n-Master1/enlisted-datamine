from "%enlSqGlob/ui_library.nut" import *

let {localPlayersBattlesPlayed} = require("%ui/hud/state/player_state_es.nut")
let {weaponsList} = require("%ui/hud/state/hero_state.nut")

const playerBattlesForLongerTimeShow = 5
const showLongerTime = 6
const showShorterTime = 3

let showWeaponsBlockAlways = Watched(true)
let showWeapons = Watched(false)
let showWeaponsBlockMinTime = Watched(showLongerTime)

let showWeaponsTimeout = Computed(@() localPlayersBattlesPlayed.value > playerBattlesForLongerTimeShow ? showShorterTime : showLongerTime)
let offShowWeapons = @() showWeapons(false)

let function activateShowWeapons(){
  showWeapons(true)
  if (showWeaponsBlockAlways.value)
    return
  gui_scene.clearTimer(offShowWeapons)
  gui_scene.setTimeout(max(showWeaponsTimeout.value, showWeaponsBlockMinTime.value), offShowWeapons)
}


let showWeaponList = Watched(false)

let weaponlistTimer = @() showWeaponList.update(false)

let function weaponlistActivate() {
  let weaponTimeout = showWeaponsTimeout.value
  showWeaponList.update(true)
  activateShowWeapons()
  gui_scene.clearTimer(weaponlistTimer)
  gui_scene.setTimeout(weaponTimeout, weaponlistTimer)
}

let function weaponlistHide() {
  gui_scene.clearTimer(weaponlistTimer)
  weaponlistTimer()
}

let weaponsListShort = Computed(function(){
  let res = []
  foreach (weapon in weaponsList.value){
    if (weapon?.isCurrent)
      res.append({isCurrent=true, name = weapon?.name, isHolstering = weapon?.isHolstering})
    else
      res.append({isCurrent=false, curAmmo = weapon?.curAmmo, name = weapon?.name, totalAmmo = weapon?.totalAmmo, isHolstering = weapon?.isHolstering})
  }
  return res
})
keepref(weaponsListShort)

let function handleWListChanges(watched) {
  local weapons_prev = watched.value
  let function onWeaponListChange(new_val) {
    if (!isEqual(weapons_prev, new_val)) {
      if (new_val.findindex(@(v) v.isCurrent) != null) {
        weaponlistActivate()
      } else {
        weaponlistHide()
      }
    }
    weapons_prev = new_val
  }
  watched.subscribe(onWeaponListChange)
}
handleWListChanges(weaponsListShort)

return{
  showWeaponList
  weaponlistActivate
  showWeapons
  activateShowWeapons
  showWeaponsBlockAlways
  showWeaponsBlockMinTime
}