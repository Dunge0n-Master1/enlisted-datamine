import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {ceil} = require("math")
let {DM_EFFECT_FIRE, DM_EFFECT_EXPL} = require("dm")

let {EventOnVehicleDamaged, EventOnVehicleDamageEffects} = require("vehicle")

let victimState = mkWatched(persist, "victimVehicleHp", {
  vehicle = INVALID_ENTITY_ID
  vehicleIconName = null
  damage = 0.0
  hp = 0.0
  maxHp = 0.0
  show = false
  effects = 0
})

let heroState = mkWatched(persist, "heroVehicleHp", {
  vehicle = INVALID_ENTITY_ID
  hp = 0.0
  maxHp = 0.0
  isBurn = false
})

ecs.register_es("ui_vehicle_hp_es", {
  [EventOnVehicleDamaged] = function(evt, _eid, _comp) {
    let state = victimState.value

    let vehicle = evt[1]
    let damage = evt[2]
    let hp = evt[3]
    let maxHp = evt[4]

    let totalDamage = damage + (vehicle == state.vehicle && state.show ? state.damage : 0)
    let data = {
      show = true
      vehicle = vehicle
      damage = totalDamage
      hp = hp
      maxHp = maxHp
      vehicleIconName = null
    }
    if (vehicle != state.vehicle || !state.show)
      data.__update({effects = 0})

    victimState.mutate(@(v) v.__update(data))
  },
  [EventOnVehicleDamageEffects] = function(evt, _eid, _comp) {
    let vehicle = evt[1]
    let effects = evt[2]
    let data = {
      show = true
      vehicle = vehicle
      effects = effects
      vehicleIconName = null
    }

    let state = victimState.value

    if (vehicle != state.vehicle || !state.show)
      data.__update({hp = 0, maxHp = 0, damage = 0})

    victimState.mutate(@(v) v.__update(data))
  }
},
{comps_rq=["hero"]})

let function trackHeroVehicle(eid, comp) {
  heroState.mutate(function(v) {
    v.vehicle = eid
    v.hp = ceil(comp["vehicle__hp"]).tointeger()
    v.maxHp = ceil(comp["vehicle__maxHp"]).tointeger()
    v.isBurn = comp["fire_damage__isBurn"]
  })
}

let resetHeroVehicle = @()
  heroState.update({
    vehicle = INVALID_ENTITY_ID
    hp = 0.0
    maxHp = 0.0
    isBurn = false
  })

ecs.register_es("ui_hero_vehicle_hp_es", {
  onInit = trackHeroVehicle,
  onChange = trackHeroVehicle,
  onDestroy = resetHeroVehicle,
  [ecs.EventComponentsDisappear] = resetHeroVehicle,
},
{
  comps_ro=[
    ["vehicle__maxHp", ecs.TYPE_FLOAT],
    ["fire_damage__isBurn", ecs.TYPE_BOOL],
  ]
  comps_rq=["heroVehicle"]
  comps_track=[["vehicle__hp", ecs.TYPE_FLOAT], ["fire_damage__isBurn", ecs.TYPE_BOOL]]
})

ecs.register_es("ui_hero_vehicle_on_change_es", {
  onDestroy = resetHeroVehicle,
  onChange = function(_eid, comp) {
    if (!comp.isInVehicle)
      resetHeroVehicle()
  }
},
{
  comps_rq=["hero"]
  comps_track=[["isInVehicle", ecs.TYPE_BOOL]]
})

console_register_command(@() victimState.mutate(@(v) v.show = true), "vehicle_hp.repeat_last_hit")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 300.0
    v.damage = 150.0
    v.maxHp = 450.0
  }),
"vehicle_hp.debug_hit")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 300.0
    v.damage = 150.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_FIRE)
  }),
"vehicle_hp.debug_fire")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = 0
  }),
"vehicle_hp.debug_destroy")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_FIRE)
  }),
"vehicle_hp.debug_destroy_fire")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_EXPL)
  }),
"vehicle_hp.debug_destroy_expl")

return { victim = victimState, hero = heroState }