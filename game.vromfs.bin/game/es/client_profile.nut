import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let {TEAM_UNASSIGNED} = require("team")
let {ceil} = require("math")
let {logerr} = require("dagor.debug")
let { loadJson } = require("%sqstd/json.nut")
let {find_human_player_by_connid, find_local_player, get_team_eid} = require("%dngscripts/common_queries.nut")
let {weaponSlotsKeys} = require("%enlSqGlob/weapon_slots.nut")
let {INVALID_CONNECTION_ID, has_network, get_sync_time} = require("net")
let {CmdSpawnSquad, EventPlayerProfileChanged} = require("dasevents")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[CLIENT PROFILE] ")
let { kick_player = @(...) null } = require_optional("dedicated")
let {INVALID_USER_ID} = require("matching.errors")
let {profilePublicKey} = require("%enlSqGlob/data/profile_pubkey.nut")
let {get_circuit, app_is_offline_mode} = require("app")
let {get_setting_by_blk_path} = require("settings")
let {get_can_use_respawnbase_type} = require("%enlSqGlob/spawn_base.nut")
let decode_jwt = require("jwt").decode
let profiles = require("%enlSqGlob/data/all_tutorial_profiles.nut")
let {
  getVehSkins, stringToDecal, decalToCompObject
} = require("%enlSqGlob/vehDecorUtils.nut")


let function validateArmies(armies, playerArmy) {
  if (!armies) {
    debug("validateArmies: armies is absent")
    return false
  }

  if (armies.len() == 0) {
    debug("validateArmies: armies is empty")
    return false
  }

  if (playerArmy == null) {
    debug("validateArmies: not found army allowed for team")
    return false
  }

  let army = armies?[playerArmy] ?? {}
  if (army.len() == 0) {
    let availableArmies = ", ".join(armies.keys())
    debug($"validateArmies: army is absent in army {playerArmy}. Available armies: {availableArmies}")
    return false
  }

  let squads = army?.squads ?? []
  if (squads.len() == 0) {
    debug($"validateArmies: squads is absent in army {playerArmy}")
    return false
  }

  foreach (idx, squad in squads) {
    if (squad?.squad == null) {
      debug($"validateArmies: squad is absent in {idx}")
      return false
    }
  }

  return true
}

let mkCalcAdd = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) + value
let mkCalcAddInt = @(key)
  @(comp, value, template) comp[key] <- ((comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) + value).tointeger()
let mkCalcAddPercent = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) * (1.0 + value)
let mkCalcSubPercent = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) * (1.0 - value)
let mkCalcMult = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) * value
let mkCalcSubstract = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key) ?? 1.0)) - value
let mkCalcSet = @(key)
  @(comp, value, _template) comp[key] <- value
let mkCalcInsert = @(key)
  @(comp, value, template) comp[key] <- (comp?[key] ?? (template?.getCompValNullable(key)?.getAll() ?? [])).append(value)
let mkCalcSetTrue = @(key)
  @(comp, _value, _template) comp[key] <- true

let perksFactory = {
  run_speed                                   = { ctor = mkCalcAdd,       compName = "entity_mods__speedMult", compType = ecs.TYPE_FLOAT }
  sprint_speed                                = { ctor = mkCalcAdd,       compName = "entity_mods__sprintSpeedMult", compType = ecs.TYPE_FLOAT }
  jump_height                                 = { ctor = mkCalcAdd,       compName = "entity_mods__jumpMult", compType = ecs.TYPE_FLOAT }
  faster_reload                               = { ctor = mkCalcSubstract, compName = "entity_mods__reloadMult", compType = ecs.TYPE_FLOAT }
  faster_bolt_action                          = { ctor = mkCalcSubstract, compName = "entity_mods__boltActionMult", compType = ecs.TYPE_FLOAT }
  stamina_boost                               = { ctor = mkCalcAdd,       compName = "entity_mods__staminaBoostMult", compType = ecs.TYPE_FLOAT }
  stamina_regeneration                        = { ctor = mkCalcAdd,       compName = "entity_mods__restoreStaminaMult", compType = ecs.TYPE_FLOAT }
  heal_effectivity                            = { ctor = mkCalcAdd,       compName = "entity_mods__healAmountMult", compType = ecs.TYPE_FLOAT }
  heal_speed                                  = { ctor = mkCalcSubstract  compName = "entity_mods__medkitUseTimeMult", compType = ecs.TYPE_FLOAT }
  heal_effectivity_target                     = { ctor = mkCalcAdd,       compName = "entity_mods__healAmountTargetMult", compType = ecs.TYPE_FLOAT }
  heal_speed_target                           = { ctor = mkCalcSubstract, compName = "entity_mods__medkitUseTimeTargetMult", compType = ecs.TYPE_FLOAT }
  medic_more_medpacks                         = { ctor = mkCalcAddPercent,compName = "entity_mods__medicMedpacksMult", compType = ecs.TYPE_FLOAT }
  medic_more_medbox_packs                     = { ctor = mkCalcAddPercent,compName = "entity_mods__medicMedboxPacksMult", compType = ecs.TYPE_FLOAT }
  faster_change_weapon                        = { ctor = mkCalcAdd,       compName = "entity_mods__fasterChangeWeaponMult", compType = ecs.TYPE_FLOAT }
  less_fall_dmg                               = { ctor = mkCalcSubstract, compName = "entity_mods__lessFallDmgMult", compType = ecs.TYPE_FLOAT }
  less_aim_moving                             = { ctor = mkCalcSubstract, compName = "entity_mods__breathAimMult", compType = ecs.TYPE_FLOAT }
  less_maximum_shot_spread_after_turn         = { ctor = mkCalcSubstract, compName = "entity_mods__shotDeviationMult", compType = ecs.TYPE_FLOAT }
  weight_run                                  = { ctor = mkCalcSubstract, compName = "entity_mods__weightRunSpeedMult", compType = ecs.TYPE_FLOAT }
  climb_speed                                 = { ctor = mkCalcAdd,       compName = "entity_mods__climbingSpeedMult", compType = ecs.TYPE_FLOAT }
  less_recoil                                 = { ctor = mkCalcSubstract, compName = "entity_mods__verticalRecoilOffsMult", compType = ecs.TYPE_FLOAT }
  more_predictable_recoil                     = { ctor = mkCalcSubstract, compName = "entity_mods__horizontalRecoilOffsMult", compType = ecs.TYPE_FLOAT }
  longer_hold_breath_cd                       = { ctor = mkCalcAdd,       compName = "entity_mods__longerHoldBreathMult", compType = ecs.TYPE_FLOAT }
  less_hold_breath_cd                         = { ctor = mkCalcAdd,       compName = "entity_mods__oftenHoldBreathMult", compType = ecs.TYPE_FLOAT }
  faster_change_pose_speed                    = { ctor = mkCalcAdd,       compName = "entity_mods__fasterChangePoseMult", compType = ecs.TYPE_FLOAT }
  crawl_crouch_speed                          = { ctor = mkCalcAdd,       compName = "entity_mods__crawlCrouchSpeedMult", compType = ecs.TYPE_FLOAT }
  faster_decreasing_of_maximum_shot_spread    = { ctor = mkCalcSubstract, compName = "entity_mods__rotationShotSpreadDecrMult", compType = ecs.TYPE_FLOAT }
  hp_boost                                    = { ctor = mkCalcAdd,       compName = "entity_mods__maxHpMult", compType = ecs.TYPE_FLOAT }
  base_hp_mult                                = { ctor = mkCalcMult,      compName = "baseMaxHpMult", compType = ecs.TYPE_FLOAT }
  hp_regeneration                             = { ctor = mkCalcAdd,       compName = "entity_mods__hpToRegen", compType = ecs.TYPE_FLOAT }
  hp_regen_speed                              = { ctor = mkCalcAddPercent,compName = "hitpoints__hpRecoverySpd", compType = ecs.TYPE_FLOAT }
  more_stability_when_hit                     = { ctor = mkCalcAdd,       compName = "entity_mods__moreStabilityWhenHitMult", compType = ecs.TYPE_FLOAT }
  less_stopping_power                         = { ctor = mkCalcAdd,       compName = "entity_mods__lessStoppingPower", compType = ecs.TYPE_FLOAT }
  faster_aiming_point_return_after_fire       = { ctor = mkCalcSubstract, compName = "entity_mods__aimingAfterFireMult", compType = ecs.TYPE_FLOAT }
  fire_damage_mult                            = { ctor = mkCalcMult,      compName = "entity_mods__fireDamageMult", compType = ecs.TYPE_FLOAT }
  fire_damage_tick_resistance                 = { ctor = mkCalcSet,       compName = "dmgzone_fire_resistance__maxTicks", compType = ecs.TYPE_INT }
  weapon_turning_speed                        = { ctor = mkCalcAdd,       compName = "entity_mods__weaponTurningSpeedMult", compType = ecs.TYPE_FLOAT }
  seat_change_speed                           = { ctor = mkCalcSubstract, compName = "entity_mods__vehicleChangeSeatTimeMult", compType = ecs.TYPE_FLOAT }
  extinguish_time                             = { ctor = mkCalcSubstract, compName = "entity_mods__vehicleExtinguishTimeMult", compType = ecs.TYPE_FLOAT }
  repair_speed                                = { ctor = mkCalcSubstract, compName = "entity_mods__vehicleRepairTimeMult", compType = ecs.TYPE_FLOAT }
  repair_quality                              = { ctor = mkCalcAdd,       compName = "entity_mods__vehicleRepairRecoveryRatioAdd", compType = ecs.TYPE_FLOAT }
  repairkit_economy_usage                     = { ctor = mkCalcAddInt,    compName = "entity_mods__vehicleRepairUsagesPerKit", compType = ecs.TYPE_INT }
  faster_reload_tankgun                       = { ctor = mkCalcSubstract, compName = "entity_mods__vehicleReloadMult", compType = ecs.TYPE_FLOAT }
  reload_reaction                             = { ctor = mkCalcSetTrue,   compName = "entity_mods__canChangeShellDuringVehicleGunReload", compType = ecs.TYPE_BOOL }
  brakingTauMult                              = { ctor = mkCalcSubstract,       compName = "driver_skills__brakingTauMult", compType = ecs.TYPE_FLOAT }
  gearChangeTimeMult                          = { ctor = mkCalcSubstract,       compName = "driver_skills__gearChangeTimeMult", compType = ecs.TYPE_FLOAT }
  drivingSpeedThresholdMult                   = { ctor = mkCalcSubstract,       compName = "driver_skills__drivingSpeedThresholdMult", compType = ecs.TYPE_FLOAT }
  melee_damage                                = { ctor = mkCalcAdd,       compName = "entity_mods__meleeDamageMult", compType = ecs.TYPE_FLOAT }
  accurate_guidance                           = { ctor = mkCalcAdd,       compName = "entity_mods__turretPitchMultWhenAimingYaw", compType = ecs.TYPE_FLOAT }
  pilot_keen_vision                           = { ctor = mkCalcAdd,       compName = "entity_mods__aircraftDetectAndIdentifyRangeMult", compType = ecs.TYPE_FLOAT }
  pilot_awareness                             = { ctor = mkCalcAdd,       compName = "entity_mods__aircraftPeripheryAngleMult", compType = ecs.TYPE_FLOAT }
  pilot_positive_g_tolerance                  = { ctor = mkCalcAdd,       compName = "entity_mods__positiveGToleranceMult", compType = ecs.TYPE_FLOAT }
  pilot_negative_g_tolerance                  = { ctor = mkCalcAdd,       compName = "entity_mods__negativeGToleranceMult", compType = ecs.TYPE_FLOAT }
  pilot_stamina_boost                         = { ctor = mkCalcAdd,       compName = "entity_mods__aircraftCrewMaxStaminaMult", compType = ecs.TYPE_FLOAT }
  pilot_stamina_regeneration                  = { ctor = mkCalcAdd,       compName = "entity_mods__aircraftCrewRestoreStaminaMult", compType = ecs.TYPE_FLOAT }
  pilot_willpower                             = { ctor = mkCalcAdd,       compName = "entity_mods__pilotLostControlsSensetivityAddMult", compType = ecs.TYPE_FLOAT }
  pilot_head_stabilisation                    = { ctor = mkCalcSubstract, compName = "entity_mods__pilotHeadStabilisationMult", compType = ecs.TYPE_FLOAT }
  more_building_materials                     = { ctor = mkCalcAddPercent,compName = "stockOfBuilderCapabilities", compType = ecs.TYPE_FLOAT }
  less_camera_shake_on_explosions             = { ctor = mkCalcSubstract, compName = "entity_mods__shakePowerMult", compType = ecs.TYPE_FLOAT }
  faster_building_speed                       = { ctor = mkCalcAdd,       compName = "entity_mods__timeToBuildMul", compType = ecs.TYPE_FLOAT}
  faster_aim_speed                            = { ctor = mkCalcAdd        compName = "entity_mods__aimSpeedMult", compType = ecs.TYPE_FLOAT }
  less_base_kill_chance                       = { ctor = mkCalcSubPercent,compName = "hitpoints__downedKillChanceBase", compType = ecs.TYPE_FLOAT }
  more_hp_threshold                           = { ctor = mkCalcAdd,       compName = "hitpoints__deathHpThreshold", compType = ecs.TYPE_FLOAT }
  more_downed_time                            = { ctor = mkCalcAddPercent,compName = "hitpoints__downedTimer", compType = ecs.TYPE_FLOAT }
  longer_grenade_throw                        = { ctor = mkCalcAdd        compName = "entity_mods__grenadeThrowDistMult", compType = ecs.TYPE_FLOAT }
  more_ammo                                   = null,       // direct apply to squadData
  more_ammo_secondary                         = null,       // direct apply to squadData
  large_inventory                             = null,       // direct apply to squadData
  perk_point_stamina_boost                    = { ctor = mkCalcAdd,       compName = "entity_mods__staminaBoostMult", compType = ecs.TYPE_FLOAT }
  perk_point_less_recoil                      = { ctor = mkCalcSubstract, compName = "entity_mods__verticalRecoilOffsMult", compType = ecs.TYPE_FLOAT }
  perk_point_run_speed                        = { ctor = mkCalcAdd,       compName = "entity_mods__speedMult", compType = ecs.TYPE_FLOAT }
  less_concussion_time                        = { ctor = mkCalcSubstract, compName = "entity_mods__concussionDurationMult", compType = ecs.TYPE_FLOAT }
  less_concussion_shake                       = { ctor = mkCalcSubstract, compName = "entity_mods__concussionShakeMult", compType = ecs.TYPE_FLOAT }
  faster_self_fire_putout                     = { ctor = mkCalcAddPercent,compName = "burning__putOutForce", compType = ecs.TYPE_FLOAT }
  more_flamethrower_fuel                      = { ctor = mkCalcAdd       ,compName = "entity_mods__flamethrowerFuelMult", compType = ecs.TYPE_FLOAT }
  faster_melee                                = { ctor = mkCalcSubPercent,compName = "entity_mods__meleeSpeedMult", compType = ecs.TYPE_FLOAT }
}

let perksPointFactory = {
  vitality = [{ valueMul = 0.01,  perk = "perk_point_stamina_boost" }]
  weapon   = [{ valueMul = 0.005, perk = "perk_point_less_recoil" }]
  speed    = [{ valueMul = 0.005, perk = "perk_point_run_speed" }]
}

let perksClassFactory = {
  flametrooper                  = [{ statValue = 0.6, statKey = "fire_damage_mult"}, { statValue = 6, statKey = "fire_damage_tick_resistance"}]
  flametrooper_2                = [{ statValue = 0.6, statKey = "fire_damage_mult"}, { statValue = 6, statKey = "fire_damage_tick_resistance"}]
  flametrooper_2_premium_1      = [{ statValue = 0.6, statKey = "fire_damage_mult"}, { statValue = 6, statKey = "fire_damage_tick_resistance"}]
  tanker_premium_2_flametrooper = [{ statValue = 0.6, statKey = "fire_damage_mult"}, { statValue = 6, statKey = "fire_damage_tick_resistance"}]
}

let vehicleModFactory = {
  turret_hor_speed                            = mkCalcSet("vehicle_mods__maxHorDriveMult")
  turret_ver_speed                            = mkCalcSet("vehicle_mods__maxVerDriveMult")
  extra_mass                                  = mkCalcSet("vehicle_mods__extraMass")
  engine_power                                = mkCalcSet("vehicle_mods__maxMomentMult")
  braking_force                               = mkCalcSet("vehicle_mods__maxBrakeForceMult")
  suspension_dampening                        = mkCalcSet("vehicle_mods__suspensionDampeningMult")
  suspension_resting                          = mkCalcSet("vehicle_mods__suspensionRestingMult")
  suspension_min_limit                        = mkCalcSet("vehicle_mods__suspensionMinLimitMult")
  suspension_max_limit                        = mkCalcSet("vehicle_mods__suspensionMaxLimitMult")
  track_friction_frontal_static               = mkCalcSet("vehicle_mods__trackFrontalStaticFrictionMult")
  track_friction_frontal_sliding              = mkCalcSet("vehicle_mods__trackFrontalSlidingFrictionMult")
  track_friction_side_linear                  = mkCalcSet("vehicle_mods__trackFricSideLinMult")
  track_friction_side_rot_min_speed           = mkCalcSet("vehicle_mods__trackSideRotMinSpdMult")
  track_friction_side_rot_max_speed           = mkCalcSet("vehicle_mods__trackSideRotMaxSpdMult")
  track_friction_side_rot_min_friction        = mkCalcSet("vehicle_mods__trackSideRotMinFricMult")
  track_friction_side_rot_max_friction        = mkCalcSet("vehicle_mods__trackSideRotMaxFricMult")
  disable_dm_part                             = mkCalcInsert("disableDMParts")
}

let mkPerkCtor = @(perk) perksFactory?[perk].ctor(perksFactory?[perk].compName) ?? @(...) null

let entityModsQuery = ecs.SqQuery("entityModsQuery", {
  comps_rw = perksFactory.map(function(perk) {
    if (perk == null)
      throw null
    return [perk.compName, perk.compType, null]
  }).values()
})

let weaponTemplateQuery = ecs.SqQuery("weaponTemplateQuery", { comps_ro = [["item__weapTemplate", ecs.TYPE_STRING]] })

let function applyPerksBasedOnWeapons(eid, comp, allAvailablePerks) {
  local selectedGunTemplate = null
  weaponTemplateQuery(comp["human_weap__currentGunEid"], @(_, queryComp) selectedGunTemplate = queryComp["item__weapTemplate"])

  entityModsQuery(eid, function(_, queryComp) {
    foreach (statName, statValue in comp.defaultStats) {
      let perk = perksFactory?[statName] ?? {}
      let perkName = perk?.compName
      if (perkName != null) {
        queryComp[perkName] = statValue
      } else {
        logerr($"Error applying {statName}. Stat wasn't found.")
      }
    }

    if (selectedGunTemplate == null)
      return

    foreach (perkName in comp.availablePerks) {
      let perk = allAvailablePerks?[perkName] ?? {}
      let items = perk?.items ?? []
      foreach (item in items) {
        if (selectedGunTemplate == item) {
          let perkStats = perk?.stats ?? []
          foreach (stat in perkStats) {
            mkPerkCtor(stat.statName)(queryComp, stat.statValue, {})
            debug($"Applied stat {stat.statName} from perk {perkName} to {eid}")
          }
          break
        }
      }
    }
  })
}

let allAvailablePerksQuery = ecs.SqQuery("allAvailablePerksQuery", { comps_ro = [["allAvailablePerks", ecs.TYPE_OBJECT]] })
let ApplyDynamicPerks = @(eid, comp)
  allAvailablePerksQuery(comp["squad_member__playerEid"], @(_, perksComp) applyPerksBasedOnWeapons(eid, comp, perksComp.allAvailablePerks))

let humanPerksEsComps = {
  comps_track = [["human_weap__currentGunEid", ecs.TYPE_EID]],
  comps_ro = [["squad_member__playerEid", ecs.TYPE_EID],
              ["availablePerks", ecs.TYPE_STRING_LIST],
              ["defaultStats", ecs.TYPE_OBJECT]],
  comps_rq = ["human"]
}

let humanPerksQueryComps = {
  comps_ro = [["human_weap__currentGunEid", ecs.TYPE_EID],
              ["squad_member__playerEid", ecs.TYPE_EID],
              ["availablePerks", ecs.TYPE_STRING_LIST],
              ["defaultStats", ecs.TYPE_OBJECT]],
  comps_rq = ["human"]
}

ecs.register_es("human_apply_dynamic_perks_on_weapon_change_es", {
  [["onInit", "onChange"]] = @(_, eid, comp) ApplyDynamicPerks(eid, comp)
}, humanPerksEsComps, {tags="server"})


let humanPerksQuery = ecs.SqQuery("humanPerksQuery", humanPerksQueryComps)

ecs.register_es("human_apply_dynamic_perks_on_weapon_init_es", {
  [["onInit", "onChange"]] = @(_eid, comp) humanPerksQuery(comp["gun__owner"], ApplyDynamicPerks)
}, { comps_track = [["gun__owner", ecs.TYPE_EID]] }, {tags="server"})


let function foreachPerkStat(perkStats, callback) {
  foreach (stat in perkStats) {
    if (stat.statKey in perksFactory) {
      if (perksFactory[stat.statKey] != null)
        callback(stat.statKey, stat.statValue)
    }
    else
      logerr($"Tried to apply unknown stat {stat.statKey}")
  }
}

let function applyStaticPerks(perks, soldier, soldierTemplate) {
  perks.each(@(perk)
    foreachPerkStat(perk?.stats ?? [],
      @(key, value) mkPerkCtor(key)(soldier, value, soldierTemplate)))
}

let function getStatValue(soldier, stat, template) {
  let {compName} = perksFactory[stat]
  return soldier?[compName] ?? (template?.getCompValNullable(compName) ?? 1.0)
}

let function applyDynamicPerks(perks, soldier, soldierTemplate) {
  let availablePerks = {}
  let dynamicStats = {}
  foreach (perk in perks) {
    let dynamicPerkStats = []
    foreachPerkStat(perk?.stats ?? [], function (key, value) {
      dynamicPerkStats.append({statName = key, statValue = value})
      dynamicStats[key] <- true
    })

    if (availablePerks?[perk.name] == null) {
      soldier.availablePerks <- (soldier?.availablePerks ?? ecs.CompStringList()).append(perk.name)
      availablePerks[perk.name] <- {stats = dynamicPerkStats, items = perk.items}
    }
  }

  let defaultStats = soldier?.defaultStats ?? {}
  defaultStats.__update(dynamicStats.map(@(_, stat) getStatValue(soldier, stat, soldierTemplate)))

  soldier.defaultStats <- defaultStats
  return availablePerks
}

let function addPerkPointBonuses(perkPoints, soldier, soldierTemplate) {
  foreach (perkPoint, value in perkPoints) {
    let perksFromPoints = perksPointFactory?[perkPoint] ?? []
    foreach (perkConfig in perksFromPoints) {
      let {perk, valueMul = 1.0 } = perkConfig
      if (perk in perksFactory) {
        if (perksFactory[perk] != null)
          mkPerkCtor(perk)(soldier, value * valueMul, soldierTemplate)
      }
      else
        logerr($"Tried to apply unknown perk for points {perk}")
    }
  }
}

let function addClassBasedPerks(soldier, soldierTemplate) {
  let sClass = soldier?.sClass
  foreachPerkStat(perksClassFactory?[sClass] ?? [],
    @(key, value) mkPerkCtor(key)(soldier, value, soldierTemplate))

}

let function applyPerks(armies) {
  let allAvailablePerks = {}
  let db = ecs.g_entity_mgr.getTemplateDB()
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      foreach (soldier in squad?.squad ?? []) {
        let templ = db.getTemplateByName(soldier.gametemplate)
        let allPerks = soldier?.perks ?? []

        let isDynamicPerk = @(perk) (perk?.items ?? []).len() > 0
        let isStaticPerk  = @(perk) !isDynamicPerk(perk)

        addPerkPointBonuses(soldier?.perkPoints ?? {}, soldier, templ)
        addClassBasedPerks(soldier, templ)
        applyStaticPerks(allPerks.filter(isStaticPerk), soldier, templ)

        let availablePerks = applyDynamicPerks(allPerks.filter(isDynamicPerk), soldier, templ)
        allAvailablePerks.__update(availablePerks)

        if (soldier?.perks != null)
          delete soldier.perks
      }
    }
  }
  return allAvailablePerks
}

let function convertGunMods(armies) {
  let db = ecs.g_entity_mgr.getTemplateDB()
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      foreach (soldier in squad?.squad ?? []) {
        foreach (weapon in (soldier?["human_weap__weapInfo"] ?? {})){
          let gunSlots = weapon?.gunSlots
          if (gunSlots == null)
            continue

          weapon.gunMods <- {}
          foreach (slotid, slotTemplateId in gunSlots) {
            let slotTemplate = db.getTemplateByName(slotTemplateId)
            if (!slotTemplate)
              continue
            weapon.gunMods[slotid] <- slotTemplate.getCompVal("gunAttachable__slotTag")
          }

          delete weapon.gunSlots
        }
      }
    }
  }
}

let function applyUpgradesToComponents(gunTemplate, upgrades) {
  if (gunTemplate == null || gunTemplate == "")
    return {}
  let db = ecs.g_entity_mgr.getTemplateDB()
  let templ = db.getTemplateByName(gunTemplate)
  if (templ == null) {
    logerr($"Cannot apply upgrades to a gun. Gun's template '{gunTemplate}' not found.")
    return {}
  }
  let result = {}
  foreach (compName, compMod in upgrades) {
    let compVal = templ.getCompValNullable(compName)
    if (compVal == null) {
      logerr($"Gun {gunTemplate} has no component {compName} to apply a mod.")
      continue
    }
    result[compName] <- compVal.tofloat() * (1.0 + compMod * 0.01)
  }
  return result
}

let function applyGunUpgrades(armies) {
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      foreach (soldier in squad?.squad ?? []) {
        let weapTemplates = soldier["human_weap__weapTemplates"]
        foreach (slotNo, upgrades in (soldier?["human_weap__weapInitialComponents"] ?? [])) {
          let gunComps = applyUpgradesToComponents(weapTemplates?[weaponSlotsKeys?[slotNo]], upgrades)
          soldier["human_weap__weapInitialComponents"][slotNo].__update(gunComps)
        }
      }
    }
  }
}

let blkAppend = @(key, param)
  @(comp, value, template) comp[key] <- $"{comp?[key] ?? (template?.getCompValNullable(key)?.getAll() ?? "")}{param}:r={value};"

let function applyModsToVehicleComponents(comps, vehicleTemplate, vehicleMods) {
  foreach (mod in vehicleMods) {
    let {statKey, statValue} = mod
    let modCtor = vehicleModFactory?[statKey] ?? blkAppend("physModificationsBlk", statKey)
    modCtor(comps, statValue, vehicleTemplate)
  }
}

let function applyTurregUpgradesToComponents(gunTemplate, upgrades) {
  if (gunTemplate == null || gunTemplate == "")
    return {}
  let db = ecs.g_entity_mgr.getTemplateDB()
  let templ = db.getTemplateByName(gunTemplate)
  if (templ == null) {
    logerr($"Cannot apply upgrades to a gun. Gun's template '{gunTemplate}' not found.")
    return {}
  }
  let result = {}
  foreach (compName, compMod in upgrades) {
    let baseValue = templ.getCompValNullable(compName)
    if (baseValue != null)
      result[compName] <- baseValue.tofloat() * compMod
  }
  return result
}

let function applyTurretModsToVehicleComponents(comps, _vehicleTemplateName, vehicleTemplate, turretMods) {
  let turretInfo = vehicleTemplate?.getCompValNullable("turret_control__turretInfo") ?? []
  let defaultInitComps = vehicleTemplate?.getCompValNullable("turretsInitialComponents")?.getAll() ?? []
  let turretsInitialComponents = array(turretInfo.len()).map(@(_,i) comps?.turretsInitialComponents?[i] ?? defaultInitComps?[i] ?? {})

  foreach (i, info in turretInfo) {
    let [turretTemplate = null, templateSuffix = null] = info?.gun.split("+")
    if (templateSuffix != "main_turret")
      continue
    let turretComps = applyTurregUpgradesToComponents(turretTemplate, turretMods.map(@(v) [v.statKey, v.statValue]).totable())
    turretsInitialComponents[i].__update(turretComps)
  }
  comps["turretsInitialComponents"] <- turretsInitialComponents
}

let function applyVehicleMods(armies) {
  let db = ecs.g_entity_mgr.getTemplateDB()
  foreach (army in armies) {
    foreach (squad in army?.squads ?? []) {
      let vehicle = squad?.curVehicle
      if (vehicle == null)
        continue

      if (vehicle?.comps == null)
        vehicle.comps <- {}

      let { gametemplate } = vehicle
      let vehicleTemplate = db.getTemplateByName(gametemplate)
      if (vehicle?.mods != null) {
        applyModsToVehicleComponents(vehicle.comps, vehicleTemplate, vehicle.mods)
        applyTurretModsToVehicleComponents(vehicle.comps, gametemplate, vehicleTemplate, vehicle.mods)
        delete vehicle.mods
      }

      if ("skin" in vehicle) {
        let skinId = vehicle?.skin.id
        if (skinId != null) {
          let {
            objTexReplace = null, animchar__objTexSet = null
          } = getVehSkins(gametemplate).findvalue(@(s) s.id == skinId)
          if (objTexReplace != null)
            vehicle.comps["animchar__objTexReplace"] <- objTexReplace
          if (animchar__objTexSet != null)
            vehicle.comps["animchar__objTexSet"] <- animchar__objTexSet
        }
        delete vehicle.skin
      }

      if ("decals" in vehicle) {
        let decalCompArray = ecs.CompArray()
        foreach (decal in vehicle?.decals ?? []) {
          let decalData = stringToDecal(decal.details, "vehDecal", decal.id, decal.slotIdx)
          if (decalData != null)
            decalCompArray.append(decalToCompObject(decalData))
        }
        vehicle.comps["animcharDecalsData"] <- decalCompArray
        delete vehicle.decals
      }

      if ("decors" in vehicle) {
        let decorCompArray = ecs.CompArray()
        foreach (decor in vehicle?.decors ?? []) {
          let decorData = stringToDecal(decor.details, "vehDecorator", decor.id, decor.slotIdx)
          if (decorData != null)
            decorCompArray.append(decalToCompObject(decorData.__merge({
              template = decor.id
              swapYZ = false
            })))
        }
        vehicle.comps["attach_decorators__templates"] <- decorCompArray
        delete vehicle.decors
      }
    }
  }
}

let getRespawnsToFullRestore = @(respawnsToFullRestoreByCount, count)
  respawnsToFullRestoreByCount?[count.tostring()] ?? respawnsToFullRestoreByCount?["default"] ?? 1

let getRevivePointsAfterDeath = @(respawnsToFullRestore) respawnsToFullRestore == 0 ? 100 : 0

let function getRevivePointsHeal(respawnsToFullRestore) {
  let respawnsF = respawnsToFullRestore.tofloat()
  return respawnsF > 0 ? ceil(100.0 / respawnsF).tointeger() : 100
}

let function initSoldierReviveData(army, comp) {
  let squadsCount = army?.squads.len() ?? 0
  let respawnsToFullRestoreByCount = comp["soldier_revive_points__respawnsToRestoreByCount"]

  let revivePoints = array(squadsCount)
  let healPerSquadmate = array(squadsCount)
  let afterDeath = array(squadsCount)

  for (local i = 0; i < squadsCount; ++i) {
    let squad = army?.squads?[i]
    let vehicleSquad = squad?.curVehicle != null
    let soldiersInSquad = squad?.squad?.len() ?? 0
    revivePoints[i] = array(soldiersInSquad, 100)
    let respawnsToRestoreSoldier = getRespawnsToFullRestore(respawnsToFullRestoreByCount, soldiersInSquad)
    healPerSquadmate[i] = getRevivePointsHeal(respawnsToRestoreSoldier)
    afterDeath[i] = vehicleSquad ? 100 : getRevivePointsAfterDeath(respawnsToRestoreSoldier)
  }

  comp["soldier_revive_points__points"] = revivePoints
  comp["soldier_revive_points__healPerSquadmate"] = healPerSquadmate
  comp["soldier_revive_points__afterDeath"] = afterDeath
}

let function onRevivePointsInit(eid, comp) {
  let army = comp.armies?[comp.army] ?? {}
  initSoldierReviveData(army, comp)
  ecs.g_entity_mgr.sendEvent(eid, EventPlayerProfileChanged())
}

let soldierReviveComps = {
  comps_rw = [
    ["soldier_revive_points__points", ecs.TYPE_ARRAY],
    ["soldier_revive_points__healPerSquadmate", ecs.TYPE_ARRAY],
    ["soldier_revive_points__afterDeath", ecs.TYPE_ARRAY],
  ]
  comps_ro =[
    ["armies", ecs.TYPE_OBJECT],
    ["army", ecs.TYPE_STRING],
    ["soldier_revive_points__respawnsToRestoreByCount", ecs.TYPE_OBJECT]
  ]
}

let soldierRespawnPointsQuery = ecs.SqQuery("soldierRespawnPointsQuery", soldierReviveComps)

let initSoldierRevivePints = @(eid, army)
  soldierRespawnPointsQuery.perform(eid, @(_, comp) initSoldierReviveData(army, comp))

let function applyGameModeSoldierModifier(soldier, soldier_modifier) {
  soldier_modifier.each(function(v,k) {
    if (k not in soldier)
      soldier[k] <- v
    else if (typeof(soldier[k]) == "table")
      soldier[k].__update(v)
    else if (typeof(soldier[k]) == "array")
      soldier[k].extend(v)
    else
      soldier[k] <- v
  })
}

let gameModeModifiersQuery = ecs.SqQuery("gameModeModifiersQuery", { comps_ro = [["game_mode__soldierModifier", ecs.TYPE_OBJECT]] })

let applyGameMode = @(armies) gameModeModifiersQuery.perform(function (_, game_mod_comp) {
  let gameModeSoldierModifier = game_mod_comp["game_mode__soldierModifier"].getAll()
  foreach (army in armies)
    foreach (squad in army?.squads ?? [])
      foreach (soldier in squad?.squad ?? [])
        applyGameModeSoldierModifier(soldier, gameModeSoldierModifier)
})

let function unpackArmiesFromJwt(_userid, jwt) {
  if (typeof jwt != "array")
    return null
  let token = "".join(jwt)
  let res   = decode_jwt(token, profilePublicKey)
  if ("error" in res) {
    let resError = res["error"]
    debug($"Could not decode profile jwt: {resError}. Fallback to default profile. Token:")
    debug(token)
  } else {
    return res?.payload.armies
  }
  return null
}

let firstPlayerConnectionTimeQuery = ecs.SqQuery("firstPlayerConnectionTimeQuery", {
  comps_ro = [["firstPlayerConnectionTime", ecs.TYPE_FLOAT]]
})

let function calcFirstSpawnDelay(squad, delayByType) {
  let vehicleTemplate = squad?.curVehicle.gametemplate
  if (vehicleTemplate == null)
    return 0.0

  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(vehicleTemplate)
  let canUseRespawnbaseType = templ?.getCompValNullable("canUseRespawnbaseType")
  return delayByType?[canUseRespawnbaseType].tofloat() ?? 0.0
}

let disableVehicleSpawnDelayQuery = ecs.SqQuery("disableVehicleSpawnDelayQuery",  {comps_rq = ["disableVehicleSpawnDelay"]})

let function updateProfileImpl(evt, eid, comp, getArmiesCb) {
  let net = has_network()
  let senderEid = net ? find_human_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  if (senderEid != eid)
    return
  if (comp.isArmiesReceived) {
    logerr("Try to apply player profile second time")
    return
  }

  let armies = getArmiesCb()
  let teamEid = comp.team != TEAM_UNASSIGNED ? get_team_eid(comp.team) : INVALID_ENTITY_ID
  let teamArmies = ecs.obsolete_dbg_get_comp_val(teamEid, "team__armies")?.getAll() ?? []
  let playerArmy = teamArmies.findvalue(@(a) a in armies)
  debug($"Received profile: team = {comp.team}; army = {playerArmy}; player = {eid};")

  if (!validateArmies(armies, playerArmy)) {
    logerr($"Corrupted profile or bad armies. See log for details.")
    debug($"userid = {comp.userid}; playerArmy = {playerArmy};")
    debug($"Team allowed armies = ")
    debugTableData(teamArmies)
    debug($"Profile = ")
    debugTableData(armies)
    kick_player(comp.userid, $"The profile is corrupted!")
    return
  }

  applyGameMode(armies)
  convertGunMods(armies)
  applyGunUpgrades(armies)
  applyVehicleMods(armies)

  comp.allAvailablePerks <- applyPerks(armies)

  comp.army = playerArmy
  comp.armies = armies
  comp.isArmiesReceived = true

  let curTime = get_sync_time()

  debug($"Received squad data when player {eid} army is {playerArmy}")
  comp.armiesReceivedTime = curTime
  comp.armiesReceivedTeam = comp.team

  let army = comp.armies[playerArmy]
  let squadsCount = army.squads.len()
  if (army?.isFakeSquads ?? false)
    debug($"Received fake armies for player {eid}. Experience will not be counted.")

  initSoldierRevivePints(eid, army)

  local nonVehicleSquadsCount = squadsCount
  for (local i = 0; i < squadsCount; ++i)
    if (army?.squads?[i]?.curVehicle != null)
      nonVehicleSquadsCount -= 1

  comp["squads__respawnTypeList"] = array(squadsCount, "")
  for (local i = 0; i < squadsCount; ++i) {
    let gametemplate = army?.squads?[i]?.curVehicle.gametemplate ?? army.squads[i]?[0].gametemplate
    let respType = get_can_use_respawnbase_type(gametemplate)?.canUseRespawnbaseType ?? "human"
    comp["squads__respawnTypeList"][i] = respType
  }

  comp["squads__revivePointsList"] = array(squadsCount, 100)
  let revivePointsPerSquad = getRevivePointsHeal(getRespawnsToFullRestore(comp["squads__respawnsToFullRestoreSquadBySquadsCount"], nonVehicleSquadsCount))
  comp["squads__revivePointsPerSquad"] = revivePointsPerSquad

  debug($"Total squads count is {squadsCount}. Set {revivePointsPerSquad} revive points per squad for player {eid}.")

  let disableVehicleSpawnDelay = (disableVehicleSpawnDelayQuery(@(eid, _) eid) ?? INVALID_ENTITY_ID) != INVALID_ENTITY_ID
  local firstConnecitonTime = firstPlayerConnectionTimeQuery(@(_, comp) comp.firstPlayerConnectionTime) ?? -1
  firstConnecitonTime = firstConnecitonTime < 0.0 ? curTime : firstConnecitonTime

  comp["vehicleRespawnsBySquad"] = array(squadsCount).map(@(_, i) {
    lastSpawnOnVehicleAtTime = 0.0
    nextSpawnOnVehicleInTime = 0.0
    firstSpawnAtTime         = firstConnecitonTime + (disableVehicleSpawnDelay ? 0 : calcFirstSpawnDelay(army.squads[i], comp["squads__firstSpawnDelayByType"]))
  })

  let delayedSpawnSquad = comp.delayedSpawnSquad.getAll()
  comp.delayedSpawnSquad = []

  let wallPosters = army?.wallPosters ?? []
  local wallPostersCount = army?.wallPostersCount ?? 0
  if (wallPosters.len() == 0)
    wallPostersCount = 0

  comp["wallPosters__maxCount"] = wallPostersCount
  comp["wallPosters"] = array(wallPosters.len()).map(@(_, i) {
    template = wallPosters[i].template
  })

  comp["decorators__portrait"] = army?.decorators.portrait ?? ""
  comp["decorators__nickFrame"] = army?.decorators.nickFrame ?? ""

  ecs.set_callback_timer(function() {
      foreach (d in delayedSpawnSquad) {
        debug($"Send delayed CmdSpawnSquad for player {eid}")
        ecs.g_entity_mgr.sendEvent(eid, CmdSpawnSquad(d.__merge({respawnGroupId = -1})))
      }
    },
    0.1, false)

  ecs.g_entity_mgr.sendEvent(eid, EventPlayerProfileChanged())
}

let playerComps = {
  comps_rw = [
    ["team", ecs.TYPE_INT],
    ["armiesReceivedTime", ecs.TYPE_FLOAT],
    ["armiesReceivedTeam", ecs.TYPE_INT],
    ["delayedSpawnSquad", ecs.TYPE_ARRAY],
    ["armies", ecs.TYPE_OBJECT],
    ["isArmiesReceived", ecs.TYPE_BOOL],
    ["army", ecs.TYPE_STRING],
    ["squads__respawnTypeList", ecs.TYPE_ARRAY],
    ["squads__revivePointsList", ecs.TYPE_ARRAY],
    ["squads__revivePointsPerSquad", ecs.TYPE_INT],
    ["squads__firstSpawnDelayByType", ecs.TYPE_OBJECT],
    ["vehicleRespawnsBySquad", ecs.TYPE_ARRAY],
    ["wallPosters__maxCount", ecs.TYPE_INT],
    ["wallPosters", ecs.TYPE_ARRAY],
    ["allAvailablePerks", ecs.TYPE_OBJECT],
    ["decorators__nickFrame", ecs.TYPE_STRING],
    ["decorators__portrait", ecs.TYPE_STRING],
  ]
  comps_ro = [
    ["userid", ecs.TYPE_UINT64],
    ["squads__respawnsToFullRestoreSquadBySquadsCount", ecs.TYPE_OBJECT]
  ]
}

ecs.register_es("client_profile_dev_es", {
  [ecs.sqEvents.CmdDevSquadsData] = function(evt, eid, comp) {
    // This is paranoid checks now.
    // dev_profile_full.nut has been removed from production dedicated vroms
    let isSandbox = app_is_offline_mode()
    let disableMenu = get_setting_by_blk_path("disableMenu") ?? false
    let disableNetwork = get_setting_by_blk_path("debug")?.disableNetwork ?? false
    let isDevProfileAllowed = isSandbox || disableMenu || disableNetwork || ["moon",""].indexof(get_circuit()) != null
    if (isDevProfileAllowed) {
      let devArmies = isSandbox ? require_optional("%enlSqGlob/data/sandbox_profile.nut")
                                : require_optional("%enlisted_pkg_dev/game/data/dev_profile_full.nut")
      updateProfileImpl(evt, eid, comp, @() devArmies)
    }
  },
}, playerComps, {tags = "server"})

let is_tutorialQuery = ecs.SqQuery("is_tutorialQuery",  {comps_rq = ["isTutorial"]})
let getTutorialProfileQuery = ecs.SqQuery("getTutorialProfileQuery", {comps_ro=[["tutorial__profile", ecs.TYPE_STRING]]})
ecs.register_es("client_profile_tutorial_es", {
  [ecs.sqEvents.CmdTutorialSquadsData] = function(evt, eid, comp) {
    let isTutorial = (is_tutorialQuery.perform(@(eid, _comp) eid) ?? INVALID_ENTITY_ID) != INVALID_ENTITY_ID
    if (isTutorial) {
      let id = getTutorialProfileQuery.perform(@(_, comp) comp["tutorial__profile"]) ?? "def"
      updateProfileImpl(evt, eid, comp, @() profiles?[id] ?? {})
    }
    else
      logerr("Tutorial profile enable only in tutorial map!")
  },
}, playerComps, {tags = "server"})

let getCustomProfileQuery = ecs.SqQuery("getCustomProfileQuery", {comps_ro=[["customProfile", ecs.TYPE_STRING]]})
ecs.register_es("client_profile_jwt_es", {
  [ecs.sqEvents.CmdProfileJwtData] = function(evt, eid, comp) {
    let customProfile = getCustomProfileQuery(@(_eid, comp) comp["customProfile"])
    let porfileCb = customProfile ? @() loadJson(customProfile) : @() unpackArmiesFromJwt(comp.userid, evt.data?.jwt)
    updateProfileImpl(evt, eid, comp, porfileCb)
  },
}, playerComps, {tags = "server"})

ecs.register_es("soldier_revive_points_init_es", {
  [[ecs.EventEntityCreated, ecs.EventComponentsAppear]] = onRevivePointsInit
}, soldierReviveComps, {tags = "server"})


let function stopTimerInt(eid, reason, do_logerr=false) {
  debug($"Stop wait profile timer: {reason}")
  ecs.recreateEntityWithTemplates({eid, removeTemplates=["wait_profile_timer"]})
  if (do_logerr)
    logerr("Stop wait profile timer")
}

let stopTimer = @(eid, reason) stopTimerInt(eid, reason)
let stopTimerLogerr = @(eid, reason) stopTimerInt(eid, reason, true)

let function checkProfile(_dt, eid, comp) {
  let connectedAtTime = comp.connectedAtTime
  if (connectedAtTime < 0.0) {
    debug($"Player {eid} ({comp.userid}) created but not connected yet. Wait for connection")
    return
  }

  if (comp.disconnected)
    return stopTimer(eid, $"Player {eid} ({comp.userid}) has been disconnected")

  if (comp.armiesReceivedTime >= 0.0)
    return stopTimer(eid, $"The profile is received for player {eid} ({comp.userid})")

  let profileWaitTimeout = comp.profileWaitTimeout
  let curWaitTime = get_sync_time() - connectedAtTime
  debug($"Wait profile for {eid} ({comp.userid}) {curWaitTime}/{profileWaitTimeout}")

  if (curWaitTime > profileWaitTimeout) {
    kick_player(comp.userid, $"The profile is not received during time {curWaitTime}")
    stopTimerLogerr(eid, $"The profile is missed for player {eid} ({comp.userid}) by timeout!")
  }
}

let function attachCheckProfile(eid, comp) {
  if (comp.userid != INVALID_USER_ID && has_network())
    ecs.recreateEntityWithTemplates({eid, addTemplates=["wait_profile_timer"]})
}

ecs.register_es("client_profile_attach_wait_profile_es", {onInit = attachCheckProfile}, {comps_ro=[["userid", ecs.TYPE_UINT64]], comps_rq=["player"]}, {tags="server"})

ecs.register_es("client_profile_timeout_es", {
  onInit = @(eid, comp) debug($"Start wait pofile timer fo player {eid} ({comp.userid}).")
  onUpdate = checkProfile,
},
{
  comps_ro=[["userid", ecs.TYPE_UINT64], ["connectedAtTime", ecs.TYPE_FLOAT], ["profileWaitTimeout", ecs.TYPE_FLOAT], ["armiesReceivedTime", ecs.TYPE_FLOAT], ["disconnected", ecs.TYPE_BOOL]]
  comps_rq=["wait_profile_timer"]
},
{ tags="server", updateInterval=2.0, after="*" })

let function onGetMySquadsData(evt, eid, comp) {
  let net = has_network()
  let senderEid = net ? find_human_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  if (senderEid != eid)
    return
  if (!comp.isArmiesReceived) {
    logerr("Try to get player profile when it not received on server")
    return
  }

  log($"Send squads data to player by request. PlayerEid = {eid}")
  ecs.server_send_event(eid, ecs.event.CmdSetMySquadsData(comp.armies), [comp.connid])
}

ecs.register_es("client_profile_requested_es",
  { [ecs.sqEvents.CmdGetMySquadsData] = onGetMySquadsData },
  { comps_ro = [
      ["connid", ecs.TYPE_INT],
      ["armies", ecs.TYPE_OBJECT],
      ["isArmiesReceived", ecs.TYPE_BOOL],
    ]
  },
  { tags = "server" })
