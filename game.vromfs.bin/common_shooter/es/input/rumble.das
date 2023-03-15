require ecs
require ecs.common
require daslib/strings_boost
require EnlistedDm
require HumanPhys
require EnlistedHuman
require DaWeapons
require DagorMath
require DagorSystem
require game.events_game
require game.utils.hero
require game.es.events
require game.es.input.input_common
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require common_shooter.events_common_shooter

[es(tag=input)]
def rumble_on_damage(evt : EventOnEntityHit)
  if !is_gamepad_input()
    return
  let victim      = evt.victim
  if !victim || !has(victim, "human_input")
    return

  if evt.damageType == int(DamageType DM_ZONE) || evt.damageType == int(DamageType DM_COLLISION) || evt.damageType == int(DamageType DM_PROJECTILE)
    let scale = cvt(evt.deltaHp, 0.0, get_float(evt.victim, "hitpoints__maxHp") ?? 0.0, 0.0, 1.0)
    sendEvent(evt.victim, [[CmdScaledRumble eventMinName="scaledDamageMin", eventMaxName="scaledDamageMax", scale=scale]])

  var rumbleEvent : string
  if evt.damageType == int(DamageType DM_MELEE)
    rumbleEvent = "meleeDamage"
  elif evt.damageType == int(DamageType DM_BACKSTAB)
    rumbleEvent = "backstabDamage"
  elif evt.damageType == int(DamageType DM_EXPLOSION)
    rumbleEvent = "explosionDamage"
  elif evt.damageType == int(DamageType DM_HOLD_BREATH)
    rumbleEvent = "holdBreathDamage"
  elif evt.damageType == int(DamageType DM_FIRE)
    rumbleEvent = "fireDamage"
  elif evt.damageType == int(DamageType DM_BARBWIRE)
    rumbleEvent = "barbwireDamage"

  sendEvent(evt.victim, [[CmdRumble eventName=rumbleEvent]])

[es(tag=input)]
def turret_rumble_on_shooting(evt : EventShot;
                              gun__owner : ecs::EntityId;
                              gun__curShellImpulse : float;
                              rumble__isHighBand : bool = true;
                              rumble__maxShellImpulse : float = 1.5f)
  if is_gamepad_input() && has(gun__owner, "human_input")
    let scale = cvt(gun__curShellImpulse, 0.0, rumble__maxShellImpulse, 0.0, 1.0)
    if rumble__isHighBand
      sendEvent(gun__owner, [[CmdScaledRumble eventMinName="minImpulseTurretShotHb", eventMaxName="maxImpulseTurretShotHb", scale=scale]])
    else
      sendEvent(gun__owner, [[CmdScaledRumble eventMinName="minImpulseTurretShot", eventMaxName="maxImpulseTurretShot", scale=scale]])

[es(tag=input, on_appear, track=game_effect__attachedTo)]
def rumble_on_effect_attach_es(evt : Event; game_effect__attachedTo : EntityId; ingame_rumble__onEffectAttach : string)
  if is_gamepad_input() && has(game_effect__attachedTo, "human_input")
    sendEvent(game_effect__attachedTo, [[CmdRumble eventName=ingame_rumble__onEffectAttach]])

[es(tag=input, REQUIRE=human_input, track=concussion__isActive)]
def rumble_concussion(evt : Event; eid : EntityId; concussion__isActive : bool; concussion__rumble : string)
  if concussion__isActive && is_gamepad_input()
    sendEvent(eid, [[CmdRumble eventName=concussion__rumble]])

[es(tag=input, no_order)]
def rumble_when_effect_attached_es(info : ParallelUpdateFrameDelayed; game_effect__attachedTo : EntityId; ingame_rumble__whenEffectAttached : string)
  if is_gamepad_input() && has(game_effect__attachedTo, "human_input")
    sendEvent(game_effect__attachedTo, [[CmdRumble eventName=ingame_rumble__whenEffectAttached, duration=int(info.dt * 1000.0)]])

[es(tag=input, REQUIRE=human_input)]
def rumble_on_melee_attack_es(evt : EventMeleeAttackHit; eid : EntityId; ingame_rumble__meleeAttackPower : float2)
  if is_gamepad_input()
    let scale = cvt(evt.power, ingame_rumble__meleeAttackPower.x, ingame_rumble__meleeAttackPower.y, 0.0, 1.0)
    sendEvent(eid, [[CmdScaledRumble eventMinName="meleeAttackMin", eventMaxName="meleeAttackMax", scale=scale]])

[es(tag=input, REQUIRE=human_input)]
def rumble_on_phys_events_es(evt : CmdPostPhysUpdate;
                             eid : EntityId;
                             human_net_phys : HumanActor;
                             ingame_rumble__fallDownMinSpeedSq : float;
                             ingame_rumble__fallDownMaxSpeedSq : float)
  let scale = cvt(length_sq(human_net_phys.phys.currentState.spdSummaryDiff), ingame_rumble__fallDownMinSpeedSq, ingame_rumble__fallDownMaxSpeedSq, 0.0, 1.0)
  if scale > 0.0
    sendEvent(eid, [[CmdScaledRumble eventMinName="fallDownMin", eventMaxName="fallDownMax", scale=scale]])
  if human_phys_state_get_isClimbing(human_net_phys.phys.currentState) && !human_phys_state_get_isClimbing(human_net_phys.phys.previousState)
    sendEvent(eid, [[CmdRumble eventName="climbingStart"]])


[es(tag=input, on_appear, REQUIRE=human_input)]
def human_rumble_init(evt : Event;
                      var human_input__rumblePlatformsPresets : ecs::Object;
                      var human_input__rumbleEvents : ecs::Object)
  let platformId = get_platform_string_id()
  for platformPresets in human_input__rumblePlatformsPresets
    if split_by_chars(platformPresets.key, "+") |> find_index(platformId) != -1
      let rumblePresets = get_ecs_object(platformPresets.value)
      if rumblePresets != null
        ecs::query() <| $ [es] (rumbleEvents : ecs::Object)
          for ev in rumbleEvents
            let presetName = get_string(ev.value, "")
            let preset = get_ecs_object((*rumblePresets)[presetName])
            if preset != null
              set(human_input__rumbleEvents, ev.key, *preset)
            else
              logerr("rumble preset {presetName} for event {ev.key} not found. platform: {platformId}")
  clear(human_input__rumblePlatformsPresets)
