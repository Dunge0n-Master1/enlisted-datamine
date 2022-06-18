from "%enlSqGlob/ui_library.nut" import *

let { DBGLEVEL } = require("dagor.system")
let { configs } = require("%enlSqGlob/configs/configs.nut")
let { campaignsByArmy, wallposters } = require("%enlist/meta/profile.nut")
let { wpPresentation, baseWpPresentation } = require("wallpostersPresentation.nut")
let { add_wallposter } = require("%enlist/meta/clientApi.nut")


let wpIdSelected = Watched(null)

let wallpostersCfg = Computed(function() {
  let campaigns = campaignsByArmy.value
  let wpList = (wallposters.value ?? {}).values()
  let res = []
  foreach(armyId, wpData in configs.value?.wallpostersCfg ?? {})
    foreach(wallposterTpl, wallposter in wpData ?? {}) {
      let { isNotOwnedHidden = false } = wallposter
      let hasReceived = wpList.findindex(@(wp) wp.tpl == wallposterTpl) != null
      let isHidden = isNotOwnedHidden && !hasReceived
      res.append({
        armyId
        wallposterTpl
        isNotOwnedHidden
        hasReceived
        isHidden
        campaignId = campaigns?[armyId].id
        campaignTitle = campaigns?[armyId].title
      }.__update(wpPresentation?[wallposterTpl] ?? baseWpPresentation))
    }

  return res
})

let wpCfgFiltered = Computed(@()
  wallpostersCfg.value.filter(@(wp) !wp.isHidden || DBGLEVEL != 0))

let isWpHidden = Computed(@() wpCfgFiltered.value.len() == 0)

console_register_command(@(id) add_wallposter(id), "meta.addWallposter")

return {
  wallpostersCfg
  wpCfgFiltered
  wpIdSelected
  isWpHidden
}
