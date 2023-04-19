import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let { logerr } = require("dagor.debug")
let { loadJson } = require("%sqstd/json.nut")
let { convertGunMods, applyGunUpgrades } = require("%scripts/game/utils/profile_init.nut")

ecs.register_es("parse_paratroopers_schemes",
  { onInit = function(_, comp) {
    comp.paratroopers__supplySchemes = loadJson(comp.paratroopers__supplySchemesJson)
    if (comp.paratroopers__supplySchemes == null) {
      logerr($"Failed to load paratoopers profile {comp.paratroopers__supplySchemesJson}")
      return
    }
    let db = ecs.g_entity_mgr.getTemplateDB()
    foreach (squad in comp.paratroopers__supplySchemes) {
      foreach(preset in squad) {
        foreach(soldier in preset.soldiers) {
          convertGunMods(db, soldier)
          applyGunUpgrades(soldier)
        }
      }
    }
  }},
  { comps_ro = [["paratroopers__supplySchemesJson", ecs.TYPE_STRING]]
    comps_rw = [["paratroopers__supplySchemes", ecs.TYPE_OBJECT]] },
  { tags = "server" })
