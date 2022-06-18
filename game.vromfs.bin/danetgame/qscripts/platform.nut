let platform = require("%sqstd/platform.nut")
let ps4 = require_optional("ps4")
let {dgs_get_settings, DBGLEVEL} = require("dagor.system")

local {aliases, SCE_REGION, platformId, consoleRevision} = platform

let isPlatformRelevant = @(platforms)
  platforms.len() == 0 || platforms.findvalue(@(p) aliases?[p] ?? (p == platformId)) != null


local ps4RegionName = "no region on this platform"

if (platform.is_sony && ps4 != null) {
   let PS4_REGION_NAMES = {
     [ps4.SCE_REGION_SCEE]  = SCE_REGION.SCEE,
     [ps4.SCE_REGION_SCEA]  = SCE_REGION.SCEA,
     [ps4.SCE_REGION_SCEJ]  = SCE_REGION.SCEJ
   }
   ps4RegionName = PS4_REGION_NAMES[ps4.get_region()]
   aliases = aliases.__merge({
     [$"{platformId}_{ps4RegionName}"] = true,
     [$"sony_{ps4RegionName}"] = true
   })
}


return platform.__merge({
  aliases,
  isPlatformRelevant,
  ps4RegionName,
  hasTouchSupport = platform.is_mobile || (platform.is_pc && DBGLEVEL > 0 && dgs_get_settings()?.debug["touchScreen"]),
  consoleRevision
})
